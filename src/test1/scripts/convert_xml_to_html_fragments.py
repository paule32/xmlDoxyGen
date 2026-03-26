#!/usr/bin/env python3
# -------------------------------------------------------------------------------
# (c) 2026 by Jens Kallup - paule32
# all rights reserved.
#
# python scripts\convert_xml_to_html_fragments.py ^
#    xml xslt -o out --full-pages ^
#    --template example_template.html
# -------------------------------------------------------------------------------
from __future__ import annotations

import argparse
import json
import base64
import re
import shutil
import hashlib
from pathlib import Path

from lxml import etree

XSLT_MAP = {
    "dir": "dir_body.xslt",
    "file": "file_body.xslt",
    "group": "group_body.xslt",
    "page": "page_body.xslt",
    "class": "class_body.xslt",
    "namespace": "namespace_body.xslt",
}

INDEX_OVERVIEW_MAP = {
    "index": "index_body.xslt",
    "files": "files_index_body.xslt",
    "dirs": "dirs_index_body.xslt",
    "groups": "groups_index_body.xslt",
    "pages": "pages_index_body.xslt",
    "classes": "classes_index_body.xslt",
    "namespaces": "namespaces_index_body.xslt",
}

OUTNAMES = {
    "index": "index.html",
    "files": "files.html",
    "dirs": "dirs.html",
    "groups": "groups.html",
    "pages": "pages.html",
    "classes": "classes.html",
    "namespaces": "namespaces.html",
}


def slug_refid(refid: str) -> str:
    return refid.replace("/", "_")


def parse_xml(path: Path) -> etree._ElementTree:
    return etree.parse(str(path))


def transform(xml_path: Path, xslt_path: Path, out_path: Path) -> None:
    xml_doc = parse_xml(xml_path)
    xslt_doc = parse_xml(xslt_path)
    result = etree.XSLT(xslt_doc)(xml_doc)
    out_path.write_text(str(result), encoding="utf-8")


def render_full_page(template_text: str, title: str, body_html: str) -> str:
    return (
        template_text
        .replace("{{ title }}", title)
        .replace("{{ body_html }}", body_html)
    )


def fragment_title(fragment_html: str, fallback: str) -> str:
    m = re.search(r"<h[1-3][^>]*>(.*?)</h[1-3]>", fragment_html, flags=re.I | re.S)
    if not m:
        return fallback
    title = re.sub(r"<.*?>", "", m.group(1)).strip()
    return title or fallback


def compound_kind(xml_path: Path) -> str | None:
    doc = parse_xml(xml_path)
    comp = doc.find("compounddef")
    if comp is None:
        comp = doc.find("doxygen/compounddef")
    if comp is None:
        return None
    return comp.get("kind")


def compound_refid(xml_path: Path) -> str | None:
    doc = parse_xml(xml_path)
    comp = doc.find("compounddef")
    if comp is None:
        comp = doc.find("doxygen/compounddef")
    if comp is None:
        return None
    return comp.get("id")







def _local_name(tag: object) -> str:
    if not isinstance(tag, str):
        return ''
    return tag.split('}', 1)[-1].lower()


def _slug_text(value: str) -> str:
    value = re.sub(r'[^A-Za-z0-9_\-]+', '_', value).strip('_')
    return value or 'item'


def _find_existing_asset(path_hint: str, search_roots: list[Path]) -> Path | None:
    if not path_hint:
        return None
    hint = Path(path_hint)
    candidates = []
    if hint.is_absolute():
        candidates.append(hint)
    else:
        for root in search_roots:
            candidates.append((root / hint).resolve())
            candidates.append((root / hint.name).resolve())
    seen = set()
    for cand in candidates:
        key = str(cand)
        if key in seen:
            continue
        seen.add(key)
        if cand.exists() and cand.is_file():
            return cand
    filename = hint.name
    for root in search_roots:
        try:
            for found in root.rglob(filename):
                if found.is_file():
                    return found
        except Exception:
            continue
    return None


def _asset_search_roots(xml_dir: Path) -> list[Path]:
    roots = [xml_dir]
    roots.extend(list(xml_dir.parents[:6]))
    uniq = []
    seen = set()
    for root in roots:
        try:
            resolved = root.resolve()
        except Exception:
            resolved = root
        key = str(resolved)
        if key not in seen and resolved.exists():
            uniq.append(resolved)
            seen.add(key)
    return uniq


def _compound_html_href(kind: str, refid: str) -> str:
    return f"{kind}_{slug_refid(refid)}.html" if kind in {'group', 'page', 'file', 'class', 'namespace', 'dir'} else ''


def _first_text(*values: str) -> str:
    for value in values:
        value = str(value or '').strip()
        if value:
            return value
    return ''


def _collect_compounds(index_xml: Path) -> list[dict[str, str]]:
    index_doc = parse_xml(index_xml)
    compounds: list[dict[str, str]] = []
    for comp in index_doc.findall('.//compound'):
        kind = comp.get('kind') or ''
        name = _text_content(comp.find('name')).strip()
        refid = comp.get('refid') or ''
        if not refid or not name:
            continue
        compounds.append({'kind': kind, 'name': name, 'refid': refid, 'href': _compound_html_href(kind, refid)})
    return compounds


def collect_visual_items(index_xml: Path, xml_dir: Path, out_dir: Path) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    compounds = _collect_compounds(index_xml)
    search_roots = _asset_search_roots(xml_dir)
    image_items: list[dict[str, object]] = []
    structure_items: list[dict[str, object]] = []
    image_seen: set[tuple[str, str]] = set()
    structure_seen: set[tuple[str, str, str]] = set()
    image_ref_re = re.compile(r'([A-Za-z0-9_./\-]+\.(?:png|jpg|jpeg|gif|svg|bmp|webp))', re.I)

    for comp in compounds:
        refid = comp['refid']
        kind = comp['kind']
        xml_path = xml_dir / f'{refid}.xml'
        if not xml_path.exists():
            continue
        try:
            doc = parse_xml(xml_path)
        except Exception:
            continue
        root = doc.getroot()
        compound_name = comp['name']
        source_href = comp['href']
        xml_text = xml_path.read_text(encoding='utf-8', errors='ignore')

        image_hits: list[dict[str, str]] = []
        for elem in root.iter():
            lname = _local_name(elem.tag)
            if lname in {'image', 'imagedata', 'graphic', 'dotfile', 'mscfile', 'diafile', 'plantuml'}:
                ref = _first_text(elem.get('name'), elem.get('file'), elem.get('src'), elem.get('href'), _text_content(elem))
                if ref:
                    image_hits.append({'ref': ref, 'caption': _text_content(elem).strip()})
        for match in image_ref_re.findall(xml_text):
            image_hits.append({'ref': match, 'caption': ''})

        img_idx = 0
        for hit in image_hits:
            ref = str(hit.get('ref') or '').strip().strip("\"'")
            if not ref:
                continue
            img_idx += 1
            key = (refid, ref.lower())
            if key in image_seen:
                continue
            image_seen.add(key)
            asset_path = _find_existing_asset(ref, search_roots)
            page_id = hashlib.md5(f'{refid}|{ref}'.encode('utf-8')).hexdigest()[:12]
            out_name = f'graphic_{page_id}.html'
            copied_name = ''
            if asset_path is not None:
                copied_name = f'generated_media/{asset_path.name}'
            label = Path(ref).name or f'Grafik {img_idx}'
            description = _first_text(hit.get('caption', ''), f'Grafik aus {compound_name}')
            image_items.append({
                'name': label,
                'description': description,
                'source_compound': compound_name,
                'source_href': source_href,
                'asset_ref': ref,
                'asset_path': asset_path,
                'copied_name': copied_name,
                'page_name': out_name,
            })

        table_idx = 0
        list_idx = 0
        for elem in root.iter():
            lname = _local_name(elem.tag)
            if lname == 'table':
                table_idx += 1
                key = (refid, 'table', str(table_idx))
                if key in structure_seen:
                    continue
                structure_seen.add(key)
                title = _first_text(elem.get('title'), _text_content(elem.find('title')), f'Tabelle {table_idx}')
                description = _first_text(_text_content(elem.find('caption')), _text_content(elem.find('title')), f'Tabelle aus {compound_name}')
                rows = []
                for row in elem.findall('.//*'):
                    if _local_name(row.tag) != 'row':
                        continue
                    cols = []
                    for entry in row:
                        if _local_name(entry.tag) == 'entry':
                            cols.append(_text_content(entry).strip())
                    if cols:
                        rows.append(cols)
                page_id = hashlib.md5(f'{refid}|table|{table_idx}'.encode('utf-8')).hexdigest()[:12]
                structure_items.append({
                    'kind': 'table',
                    'name': title,
                    'description': description,
                    'source_compound': compound_name,
                    'source_href': source_href,
                    'rows': rows,
                    'items': [],
                    'page_name': f'tablelist_{page_id}.html',
                })
            elif lname in {'itemizedlist', 'orderedlist', 'variablelist'}:
                list_idx += 1
                key = (refid, 'list', str(list_idx))
                if key in structure_seen:
                    continue
                structure_seen.add(key)
                title = _first_text(elem.get('title'), f'Liste {list_idx}')
                description = f'Liste aus {compound_name}'
                items = []
                for li in elem.iter():
                    if _local_name(li.tag) == 'listitem':
                        txt = _text_content(li).strip()
                        if txt:
                            items.append(txt)
                page_id = hashlib.md5(f'{refid}|list|{list_idx}'.encode('utf-8')).hexdigest()[:12]
                structure_items.append({
                    'kind': 'list',
                    'name': title,
                    'description': description,
                    'source_compound': compound_name,
                    'source_href': source_href,
                    'rows': [],
                    'items': items,
                    'page_name': f'tablelist_{page_id}.html',
                })

    image_items.sort(key=lambda x: str(x['name']).lower())
    structure_items.sort(key=lambda x: (str(x['kind']), str(x['name']).lower()))
    return image_items, structure_items


def render_media_index_page(title: str, intro: str, items: list[dict[str, object]], empty_text: str = 'Keine Einträge gefunden.') -> str:
    parts = ['<div class="doxy-docs">', '  <div class="doxy-nav">', '    <a href="index.html">Start</a>', '    <a href="toc.html">TOC</a>', '    <a href="graphics.html">Grafiken</a>', '    <a href="tables_lists.html">Tabellen / Listen</a>', '  </div>', '  <div class="doxy-card">', f'    <h2>{_html_text(title)}</h2>', f'    <p class="doxy-muted">{_html_text(intro)}</p>', '  </div>', '  <div class="doxy-card doxy-section-gap">', f'    <div class="doxy-kpi">{len(items)}</div>', f'    <span class="doxy-badge-label">{_html_text(title)}</span>', '  </div>', '  <div class="doxy-card doxy-section-gap">', '    <table class="doxy-table">', '      <thead><tr><th>Name</th><th>Beschreibung</th></tr></thead>', '      <tbody>']
    if items:
        for item in items:
            href = str(item.get('page_name') or '')
            name = str(item.get('name') or 'Eintrag')
            desc = str(item.get('description') or '—')
            parts.append(f'        <tr><td><a href="{_html_text(href)}">{_html_text(name)}</a></td><td>{_html_text(desc)}</td></tr>')
    else:
        parts.append(f'        <tr><td colspan="2" class="doxy-muted">{_html_text(empty_text)}</td></tr>')
    parts += ['      </tbody>', '    </table>', '  </div>', '</div>']
    return '\n'.join(parts)


def render_graphic_detail_page(item: dict[str, object]) -> str:
    parts = ['<div class="doxy-docs">', '  <div class="doxy-nav">', '    <a href="toc.html">TOC</a>', '    <a href="graphics.html">Grafiken</a>', '  </div>', '  <div class="doxy-card">', f'    <h2>{_html_text(str(item.get("name") or "Grafik"))}</h2>', f'    <div class="doxy-desc-brief-row">{_html_text(str(item.get("description") or "—"))}</div>']
    if item.get('source_href'):
        parts.append(f'    <div class="doxy-desc-since-row"><strong>Quelle:</strong> <a href="{_html_text(str(item.get("source_href")))}">{_html_text(str(item.get("source_compound") or "Dokumentation"))}</a></div>')
    parts.append('  </div>')
    parts.append('  <div class="doxy-card doxy-section-gap">')
    parts.append('    <h3>Grafik</h3>')
    copied_name = str(item.get('copied_name') or '')
    if copied_name:
        parts.append(f'    <div class="doxy-media-frame"><img src="{_html_text(copied_name)}" alt="{_html_text(str(item.get("name") or "Grafik"))}" class="doxy-media-image"></div>')
    else:
        parts.append(f'    <div class="doxy-text-block">{_html_text(str(item.get("asset_ref") or "Grafikreferenz nicht gefunden."))}</div>')
    parts.append('  </div>')
    parts.append('</div>')
    return '\n'.join(parts)


def render_structure_detail_page(item: dict[str, object]) -> str:
    title = str(item.get('name') or ('Tabelle' if item.get('kind') == 'table' else 'Liste'))
    parts = ['<div class="doxy-docs">', '  <div class="doxy-nav">', '    <a href="toc.html">TOC</a>', '    <a href="tables_lists.html">Tabellen / Listen</a>', '  </div>', '  <div class="doxy-card">', f'    <h2>{_html_text(title)}</h2>', f'    <div class="doxy-desc-brief-row">{_html_text(str(item.get("description") or "—"))}</div>']
    if item.get('source_href'):
        parts.append(f'    <div class="doxy-desc-since-row"><strong>Quelle:</strong> <a href="{_html_text(str(item.get("source_href")))}">{_html_text(str(item.get("source_compound") or "Dokumentation"))}</a></div>')
    parts.append('  </div>')
    parts.append('  <div class="doxy-card doxy-section-gap">')
    if item.get('kind') == 'table':
        rows = list(item.get('rows') or [])
        if rows:
            parts.append('    <table class="doxy-table">')
            for ridx, row in enumerate(rows):
                tag = 'th' if ridx == 0 else 'td'
                parts.append('      <tr>' + ''.join(f'<{tag}>{_html_text(str(col))}</{tag}>' for col in row) + '</tr>')
            parts.append('    </table>')
        else:
            parts.append('    <div class="doxy-text-block">Keine Tabellenstruktur in den XML-Daten gefunden.</div>')
    else:
        items = list(item.get('items') or [])
        if items:
            parts.append('    <ul class="doxy-link-list">' + ''.join(f'<li>{_html_text(str(val))}</li>' for val in items) + '</ul>')
        else:
            parts.append('    <div class="doxy-text-block">Keine Listeneinträge in den XML-Daten gefunden.</div>')
    parts.append('  </div>')
    parts.append('</div>')
    return '\n'.join(parts)


def write_visual_pages(index_xml: Path, xml_dir: Path, out_dir: Path, template_text: str | None) -> tuple[int, int]:
    graphics, structures = collect_visual_items(index_xml, xml_dir, out_dir)
    media_dir = out_dir / 'generated_media'
    media_dir.mkdir(parents=True, exist_ok=True)
    for item in graphics:
        asset_path = item.get('asset_path')
        copied_name = str(item.get('copied_name') or '')
        if asset_path is not None and copied_name:
            target = out_dir / copied_name
            target.parent.mkdir(parents=True, exist_ok=True)
            try:
                shutil.copy2(asset_path, target)
            except Exception:
                pass
        html = render_graphic_detail_page(item)
        if template_text is not None:
            html = render_full_page(template_text, str(item.get('name') or 'Grafik'), html)
        (out_dir / str(item['page_name'])).write_text(html, encoding='utf-8')
    for item in structures:
        html = render_structure_detail_page(item)
        if template_text is not None:
            html = render_full_page(template_text, str(item.get('name') or 'Tabelle / Liste'), html)
        (out_dir / str(item['page_name'])).write_text(html, encoding='utf-8')
    graphics_index = render_media_index_page('Grafiken', 'Automatisch aus den Doxygen-XML-Daten ermittelte Grafiken.', graphics, 'Keine Grafiken in den XML-Daten gefunden.')
    tables_index = render_media_index_page('Tabellen / Listen', 'Automatisch aus den Doxygen-XML-Daten ermittelte Tabellen und Listen.', structures, 'Keine Tabellen oder Listen in den XML-Daten gefunden.')
    if template_text is not None:
        graphics_index = render_full_page(template_text, 'Grafiken', graphics_index)
        tables_index = render_full_page(template_text, 'Tabellen / Listen', tables_index)
    (out_dir / 'graphics.html').write_text(graphics_index, encoding='utf-8')
    (out_dir / 'tables_lists.html').write_text(tables_index, encoding='utf-8')
    return len(graphics), len(structures)
def _text_content(node) -> str:
    if node is None:
        return ""
    return "".join(node.itertext())


def _clean_comment_line(raw: str) -> str:
    line = raw.rstrip("\r\n")
    line = re.sub(r"^\s*///+\s?", "", line)
    line = re.sub(r"^\s*//[/!]??\s?", "", line)
    line = re.sub(r"^\s*/\*+\s?", "", line)
    line = re.sub(r"\s*\*/\s*$", "", line)
    line = re.sub(r"^\s*\*\s?", "", line)
    return line.rstrip()


def _clean_doc_text(value: str) -> str:
    if not value:
        return ""
    lines = [line.rstrip() for line in value.splitlines()]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return "\n".join(lines)


def _html_text(value: str) -> str:
    value = (
        value.replace('&', '&amp;')
        .replace('<', '&lt;')
        .replace('>', '&gt;')
    )
    return value.replace('\n', '<br>')


def _normalize_display_source_text(value: str) -> str:
    if not value:
        return ""
    return value.replace("\r\n", "\n").replace("\r", "\n").replace("\\n", "\n")


def _parse_doc_comment(raw_lines: list[str]) -> dict[str, str]:
    info = {'brief': '', 'details': '', 'since': ''}
    current = None
    brief_lines: list[str] = []
    detail_lines: list[str] = []
    since_lines: list[str] = []

    for raw in raw_lines:
        line = _clean_comment_line(raw)
        stripped = line.strip()
        if not stripped:
            if current == 'details':
                detail_lines.append('')
            continue
        low = stripped.lower()
        if low.startswith('@brief'):
            current = 'brief'
            brief_lines.append(stripped[6:].lstrip())
            continue
        if low.startswith('@details'):
            current = 'details'
            detail_lines.append(stripped[8:].lstrip())
            continue
        if low.startswith('@since'):
            current = 'since'
            since_lines.append(stripped[6:].lstrip())
            continue
        if current == 'details':
            detail_lines.append(stripped)
        elif current == 'since':
            since_lines.append(stripped)
        elif current == 'brief':
            brief_lines.append(stripped)
        else:
            if not brief_lines:
                brief_lines.append(stripped)
            else:
                detail_lines.append(stripped)

    info['brief'] = _clean_doc_text('\n'.join(brief_lines))
    info['details'] = _clean_doc_text('\n'.join(detail_lines))
    info['since'] = _clean_doc_text('\n'.join(since_lines))
    return info


def is_pascal_file(xml_path: Path) -> bool:
    doc = parse_xml(xml_path)
    comp = doc.find('compounddef')
    if comp is None:
        comp = doc.find('doxygen/compounddef')
    if comp is None or comp.get('kind') != 'file':
        return False
    location = comp.find('location')
    file_name = (location.get('file') if location is not None else '') or ''
    file_name = file_name.lower()
    return file_name.endswith(('.pas', '.pp', '.p'))


def pascal_fallback_outname(file_refid: str, class_name: str) -> str:
    safe_name = re.sub(r'[^A-Za-z0-9_]+', '_', class_name).strip('_') or 'Class'
    return f"class_pas_{slug_refid(file_refid)}_{safe_name}.html"


def _find_pascal_source_file(xml_path: Path, comp) -> Path | None:
    location = comp.find('location')
    file_name = (location.get('file') if location is not None else '') or ''
    if not file_name:
        return None
    candidate = Path(file_name)
    if candidate.exists():
        return candidate
    roots = list(xml_path.parents[:8])
    for root in roots:
        probe = (root / file_name).resolve()
        if probe.exists():
            return probe
    for root in roots:
        matches = list(root.rglob(Path(file_name).name))
        if matches:
            return matches[0]
    return None


def _collect_preceding_comment(lines: list[str], idx: int) -> tuple[list[str], int]:
    comment_lines: list[str] = []
    j = idx - 1
    in_block = False
    while j >= 0:
        raw = lines[j].rstrip('\n')
        stripped = raw.strip()
        if in_block:
            comment_lines.append(raw)
            if '/*' in stripped:
                break
            j -= 1
            continue
        if not stripped:
            if comment_lines:
                break
            j -= 1
            continue
        if stripped.startswith('///') or stripped.startswith('//!') or stripped.startswith('//'):
            comment_lines.append(raw)
            j -= 1
            continue
        if stripped.endswith('*/') or stripped == '*/':
            comment_lines.append(raw)
            in_block = True
            j -= 1
            continue
        break
    comment_lines.reverse()
    return comment_lines, j


def _classify_pascal_member(norm: str) -> str | None:
    low = norm.lower()
    if low.startswith('constructor '):
        return 'constructor'
    if low.startswith('destructor '):
        return 'destructor'
    if low.startswith('property '):
        return 'property'
    if low.startswith(('procedure ', 'function ', 'class procedure ', 'class function ')):
        return 'method'
    if ':' in norm and norm.endswith(';') and not low.startswith(('case ', 'type ', 'const ', 'var ')):
        return 'field'
    return None


def extract_pascal_classes(xml_path: Path) -> list[dict[str, object]]:
    doc = parse_xml(xml_path)
    comp = doc.find('compounddef')
    if comp is None:
        comp = doc.find('doxygen/compounddef')
    if comp is None:
        return []

    file_refid = comp.get('id') or xml_path.stem
    source_file = _find_pascal_source_file(xml_path, comp)
    if source_file and source_file.exists():
        raw_lines = source_file.read_text(encoding='utf-8', errors='ignore').splitlines()
        file_name_only = source_file.name
    else:
        location = comp.find('location')
        file_name = (location.get('file') if location is not None else '') or ''
        file_name_only = Path(file_name).name if file_name else xml_path.name
        lines = comp.findall('programlisting/codeline')
        raw_lines = [_text_content(line) for line in lines]

    result: list[dict[str, object]] = []
    i = 0
    while i < len(raw_lines):
        line = raw_lines[i].rstrip()
        norm = ' '.join(line.split())
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*class(?:\s*\(([^)]*)\))?', norm, flags=re.IGNORECASE)
        if not m:
            i += 1
            continue

        class_name = m.group(1)
        base_class = (m.group(2) or '').strip()
        class_comment_lines, _ = _collect_preceding_comment(raw_lines, i)
        class_doc = _parse_doc_comment(class_comment_lines)

        declaration_lines: list[dict[str, str]] = []
        visibility_sections: dict[str, list[dict[str, str]]] = {}
        fields: list[dict[str, str]] = []
        constructors: list[dict[str, str]] = []
        destructors: list[dict[str, str]] = []
        methods: list[dict[str, str]] = []
        properties: list[dict[str, str]] = []
        current_visibility = 'public'

        k = i + 1
        while k < len(raw_lines):
            raw = raw_lines[k].rstrip()
            stripped = raw.strip()
            norm_member = ' '.join(stripped.split())
            low = norm_member.lower()
            if not stripped:
                k += 1
                continue
            if low in {'private', 'public', 'protected', 'published', 'strict private', 'strict protected'}:
                current_visibility = low
                declaration_lines.append({'kind': 'visibility', 'raw': stripped, 'visibility': current_visibility})
                visibility_sections.setdefault(current_visibility, [])
                k += 1
                continue
            if low.startswith('end;'):
                break
            if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
                k += 1
                continue

            member_type = _classify_pascal_member(norm_member)
            member_comment_lines, _ = _collect_preceding_comment(raw_lines, k)
            member_doc = _parse_doc_comment(member_comment_lines)
            entry = {
                'kind': member_type or 'member',
                'visibility': current_visibility,
                'signature': stripped,
                'brief': member_doc['brief'],
                'details': member_doc['details'],
                'since': member_doc['since'],
            }
            declaration_lines.append({'kind': member_type or 'member', 'raw': stripped, 'visibility': current_visibility})
            visibility_sections.setdefault(current_visibility, []).append(entry)
            if member_type == 'field':
                fields.append(entry)
            elif member_type == 'constructor':
                constructors.append(entry)
            elif member_type == 'destructor':
                destructors.append(entry)
            elif member_type == 'property':
                properties.append(entry)
            elif member_type == 'method':
                methods.append(entry)
            k += 1

        result.append({
            'class_name': class_name,
            'base_class': base_class,
            'brief': class_doc['brief'],
            'details': class_doc['details'],
            'since': class_doc['since'],
            'fields': fields,
            'constructors': constructors,
            'destructors': destructors,
            'properties': properties,
            'methods': methods,
            'visibility_sections': visibility_sections,
            'declaration_lines': declaration_lines,
            'file_refid': file_refid,
            'file_name': file_name_only,
            'out_name': pascal_fallback_outname(file_refid, class_name),
            'source_lines': raw_lines[i:k+1],
        })
        i = k + 1
    return result


def build_keyword_href_map(out_dir: Path) -> dict[str, str]:
    mapping: dict[str, str] = {}
    for html in sorted(out_dir.glob('page_*.html')):
        m = re.search(r'page_([^\.]+)\.html$', html.name, flags=re.I)
        if not m:
            continue
        refid = m.group(1).lower()
        for prefix in ('kw_pas_', 'kw_py_', 'kw_cpp_'):
            if refid.startswith(prefix):
                mapping[refid[len(prefix):].lower()] = html.name
                mapping[refid] = html.name
                break
    return mapping


def _display_keyword_name(name: str) -> str:
    low = name.lower()
    for prefix in ('kw_pas_', 'kw_py_', 'kw_cpp_'):
        if low.startswith(prefix):
            return name[len(prefix):]
    return name


def _tokenize_preserving_ws(text: str) -> list[str]:
    if not text:
        return []
    return re.findall(r'\s+|[A-Za-z_][A-Za-z0-9_]*|.', text, flags=re.UNICODE)


def _linkify_pascal_text(text: str, keyword_map: dict[str, str], extra_map: dict[str, str] | None = None) -> str:
    extra_map = extra_map or {}
    out: list[str] = []
    for tok in _tokenize_preserving_ws(text):
        if tok.isspace():
            out.append(tok.replace(' ', '&nbsp;').replace('\t', '&nbsp;&nbsp;&nbsp;&nbsp;').replace('\n', '<br>'))
            continue
        if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', tok):
            href = extra_map.get(tok) or extra_map.get(tok.lower()) or keyword_map.get(tok.lower())
            esc = _html_text(tok)
            if href:
                out.append(f'<a class="doxy-kw-link" href="{_html_text(href)}" data-keyword="{esc}">{esc}</a>')
            else:
                out.append(esc)
        else:
            out.append(_html_text(tok))
    return ''.join(out)


def _compute_link_spans(lines: list[str], keyword_map: dict[str, str], extra_map: dict[str, str] | None = None) -> list[dict[str, object]]:
    extra_map = extra_map or {}
    spans: list[dict[str, object]] = []
    ident = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
    for row, line in enumerate(lines):
        for m in ident.finditer(line):
            tok = m.group(0)
            href = extra_map.get(tok) or extra_map.get(tok.lower()) or keyword_map.get(tok.lower())
            if href:
                spans.append({'row': row, 'start': m.start(), 'end': m.end(), 'href': href, 'text': tok})
    return spans


def _render_description_cell(entry: dict[str, str], detail_href: str | None) -> str:
    chunks: list[str] = []
    brief = str(entry.get('brief') or '').strip()
    details = str(entry.get('details') or '').strip()
    since = str(entry.get('since') or '').strip()
    if brief:
        line = _html_text(brief)
        if details and detail_href:
            line += f' <a class="doxy-more-link" href="{_html_text(detail_href)}">mehr...</a>'
        chunks.append(f'<div class="doxy-desc-brief">{line}</div>')
    elif details and detail_href:
        chunks.append(f'<div class="doxy-desc-brief"><a class="doxy-more-link" href="{_html_text(detail_href)}">mehr...</a></div>')
    if since:
        chunks.append(f'<div class="doxy-desc-since"><strong>Seit:</strong> {_html_text(since)}</div>')
    return ''.join(chunks) or '—'


def _render_ace_block(element_id: str, lines: list[str], spans: list[dict[str, object]], mode: str = 'pascal') -> str:
    source = '\n'.join(lines).replace('\r\n', '\n').replace('\r', '\n').replace('\\n', '\n')
    payload = json.dumps(spans, ensure_ascii=False)
    source_b64 = base64.b64encode(source.encode('utf-8')).decode('ascii')
    return (
        '<div class="doxy-ace-host doxy-page-ace-host">\n'
        f'  <div class="doxy-code-toolbar"><span class="doxy-code-lang">{_html_text(mode.title())}</span><span class="doxy-code-note">Schlüsselwörter anklickbar</span></div>\n'
        f'  <div id="{element_id}" class="doxy-ace-editor doxy-page-ace-editor" data-ace-source={json.dumps(source)!r} data-ace-source-b64="{source_b64}" data-ace-links={payload!r}></div>\n'
        f'  <noscript><pre class="doxy-pre doxy-source">{_html_text(source)}</pre></noscript>\n'
        '</div>'
    )




def _render_source_block_html(lines: list[str], keyword_map: dict[str, str], extra_map: dict[str, str] | None = None, mode: str = 'pascal') -> str:
    extra_map = extra_map or {}
    source = _normalize_display_source_text("\n".join(str(line) for line in lines))
    linked = _linkify_pascal_text(source, keyword_map, extra_map)
    return (
        '<div class="doxy-source-host doxy-page-source-host">\n'
        f'  <div class="doxy-code-toolbar"><span class="doxy-code-lang">{_html_text(mode.title())}</span><span class="doxy-code-note">Schlüsselwörter anklickbar</span></div>\n'
        f'  <div class="doxy-source-div">{linked}</div>\n'
        '</div>'
    )


def _render_ace_bootstrap_script() -> str:
    return """<script>
(function(){
  function boot(){
    var editors=document.querySelectorAll('.doxy-ace-editor[data-ace-source], .doxy-ace-editor[data-ace-source-b64]');
    if(!editors.length){return;}
    function activate(){
      editors.forEach(function(host){
        if(host.dataset.aceReady==='1' || !window.ace){return;}
        host.dataset.aceReady='1';
        var src=host.getAttribute('data-ace-source')||'""';
        if((!src || src==='""') && host.hasAttribute('data-ace-source-b64')){
          try{ src=JSON.stringify(atob(host.getAttribute('data-ace-source-b64'))); }catch(e){ src='""'; }
        }
        var links=[];
        try{ links=JSON.parse(host.getAttribute('data-ace-links')||'[]'); }catch(e){ links=[]; }
        var editor=ace.edit(host);
        editor.setTheme('ace/theme/tomorrow_night');
        editor.session.setMode('ace/mode/pascal');
        editor.setValue(JSON.parse(src), -1);
        editor.setReadOnly(true);
        editor.setHighlightActiveLine(false);
        editor.setShowPrintMargin(false);
        editor.renderer.setShowGutter(true);
        editor.renderer.setScrollMargin(10,10,10,10);
        var Range=ace.require('ace/range').Range;
        var activeMarker=null, activeLink=null;
        function clearMarker(){ if(activeMarker!==null){ editor.session.removeMarker(activeMarker); activeMarker=null; } host.classList.remove('doxy-ace-pointer'); activeLink=null; host.title=''; }
        function findLink(pos){ for(var i=0;i<links.length;i++){ var l=links[i]; if(pos.row===l.row && pos.column>=l.start && pos.column<l.end){ return l; } } return null; }
        editor.container.addEventListener('mousemove', function(ev){
          var pos=editor.renderer.screenToTextCoordinates(ev.clientX, ev.clientY);
          var hit=findLink(pos);
          if(!hit){ clearMarker(); return; }
          if(activeLink && activeLink.row===hit.row && activeLink.start===hit.start && activeLink.end===hit.end && activeLink.href===hit.href){ host.title=hit.text; return; }
          clearMarker();
          activeLink=hit;
          activeMarker=editor.session.addMarker(new Range(hit.row, hit.start, hit.row, hit.end), 'doxy-ace-link-marker', 'text', false);
          host.classList.add('doxy-ace-pointer');
          host.title=hit.text;
        });
        editor.container.addEventListener('mouseleave', clearMarker);
        editor.container.addEventListener('click', function(){ if(activeLink){ window.location.href=activeLink.href; } });
      });
    }
    if(window.ace){ activate(); return; }
    var local='assets/vendors/ace/ace.js';
    var cdn='https://cdn.jsdelivr.net/npm/ace-builds@1.32.6/src-min-noconflict/ace.js';
    function add(src, cb){ var s=document.createElement('script'); s.src=src; s.onload=cb; s.onerror=cb; document.head.appendChild(s); }
    function fallback(){ editors.forEach(function(host){ if(host.dataset.aceReady==='1'){return;} var src=host.getAttribute('data-ace-source')||'""'; if((!src || src==='""') && host.hasAttribute('data-ace-source-b64')){ try{ src=JSON.stringify(atob(host.getAttribute('data-ace-source-b64'))); }catch(e){ src='""'; } } try{ host.innerHTML='<pre class="doxy-pre doxy-source">'+JSON.parse(src).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')+'</pre>'; }catch(e){} }); }
    add(local, function(){ if(window.ace){ activate(); } else { add(cdn, function(){ if(window.ace){ activate(); } else { fallback(); } }); } });
  }
  if(document.readyState==='loading'){ document.addEventListener('DOMContentLoaded', boot); } else { boot(); }
})();
</script>"""


def _render_member_table(title: str, entries: list[dict[str, str]], keyword_map: dict[str, str], extra_map: dict[str, str] | None = None, anchor_prefix: str = "member") -> str:
    if not entries:
        return ''
    extra_map = extra_map or {}
    parts = []
    detail_entries = []
    parts.append('  <div class="doxy-card doxy-section-gap">')
    parts.append(f'    <h3>{title}</h3>')
    parts.append('    <table class="doxy-table doxy-member-table">')
    parts.append('      <thead><tr><th>Deklaration</th><th class="doxy-col-visibility">Sichtbarkeit</th></tr></thead>')
    parts.append('      <tbody>')
    for idx, entry in enumerate(entries, start=1):
        detail_id = f"{anchor_prefix}-{idx}-details"
        detail_href = f"#{detail_id}" if entry.get('details') else None
        desc = _render_description_cell(entry, detail_href)
        parts.append('        <tr class="doxy-member-main-row">')
        parts.append(f'          <td><code>{_linkify_pascal_text(entry["signature"], keyword_map, extra_map)}</code></td>')
        parts.append(f'          <td class="doxy-col-visibility">{_html_text(entry.get("visibility", "")) or "—"}</td>')
        parts.append('        </tr>')
        parts.append('        <tr class="doxy-member-desc-row">')
        parts.append(f'          <td colspan="2">{desc}</td>')
        parts.append('        </tr>')
        if entry.get('details'):
            detail_entries.append((detail_id, entry))
    parts.append('      </tbody>')
    parts.append('    </table>')
    if detail_entries:
        parts.append('    <div class="doxy-member-details-list">')
        for detail_id, entry in detail_entries:
            parts.append(f'      <div class="doxy-member-detail" id="{detail_id}">')
            parts.append(f'        <h4><code>{_linkify_pascal_text(entry["signature"], keyword_map, extra_map)}</code></h4>')
            parts.append(f'        <div class="doxy-text-block">{_html_text(entry.get("details", ""))}</div>')
            if entry.get('since'):
                parts.append(f'        <div class="doxy-detail-since"><strong>Seit:</strong> {_html_text(entry.get("since", ""))}</div>')
            parts.append('      </div>')
        parts.append('    </div>')
    parts.append('  </div>')
    return '\n'.join(parts)


def render_pascal_class_page(info: dict[str, object], keyword_map: dict[str, str]) -> str:
    class_name = str(info['class_name'])
    brief = str(info.get('brief') or '')
    base_class = str(info.get('base_class') or '')
    details = str(info.get('details') or '')
    since = str(info.get('since') or '')
    constructors = list(info.get('constructors', []))
    destructors = list(info.get('destructors', []))
    properties = list(info.get('properties', []))
    methods = list(info.get('methods', []))
    fields = list(info.get('fields', []))
    visibility_sections = dict(info.get('visibility_sections', {}))
    declaration_lines = list(info.get('declaration_lines', []))
    source_lines = [str(line).replace('\\n', '\n') for line in list(info.get('source_lines', []))]
    file_name = str(info['file_name'])
    file_refid = str(info['file_refid'])
    current_out_name = str(info.get('out_name') or '')
    extra_map = {class_name.lower(): current_out_name, class_name: current_out_name}

    parts = []
    parts.append('<div class="doxy-docs">')
    parts.append('  <div class="doxy-nav">')
    parts.append('    <a href="index.html">Start</a>')
    parts.append('    <a href="files.html">Dateien</a>')
    parts.append('    <a href="dirs.html">Verzeichnisse</a>')
    parts.append('    <a href="groups.html">Gruppen</a>')
    parts.append('    <a href="pages.html">Seiten</a>')
    parts.append('    <a href="classes.html">Klassen</a>')
    parts.append('    <a href="namespaces.html">Namespaces</a>')
    parts.append('    <a href="toc.html">TOC</a>')
    parts.append('  </div>')
    parts.append('  <div class="doxy-card">')
    parts.append(f'    <h2>Klasse: <span class="doxy-class-title-name" style="color:#ffd54a !important;">{_html_text(class_name)}</span></h2>')
    parts.append('  </div>')
    parts.append('  <div class="doxy-card doxy-section-gap">')
    parts.append('    <h3>Beschreibung</h3>')
    brief_line = _html_text(brief or 'Aus Pascal-Datei extrahierte Klasse.')
    if details:
        brief_line += ' <a class="doxy-more-link" href="#class-details">mehr...</a>'
    parts.append(f'    <div class="doxy-desc-brief-row">{brief_line}</div>')
    if since:
        parts.append(f'    <div class="doxy-desc-since-row"><strong>Seit:</strong> {_html_text(since)}</div>')
    if base_class:
        parts.append(f'    <div class="doxy-section-gap"><strong>Basisklasse:</strong> <code>{_linkify_pascal_text(base_class, keyword_map, extra_map)}</code></div>')
    parts.append(f'    <div class="doxy-section-gap"><strong>Datei:</strong> <a href="file_{slug_refid(file_refid)}.html">{_html_text(file_name)}</a></div>')
    parts.append('  </div>')

    for title, entries in [
        ('Felder', fields),
        ('Konstruktoren', constructors),
        ('Destruktoren', destructors),
        ('Methoden', methods),
        ('Properties', properties),
    ]:
        block = _render_member_table(title, entries, keyword_map, extra_map, anchor_prefix=title.lower())
        if block:
            parts.append(block)

    for visibility in ['private', 'strict private', 'protected', 'strict protected', 'public', 'published']:
        entries = visibility_sections.get(visibility, [])
        if not entries:
            continue
        parts.append('  <div class="doxy-card doxy-section-gap">')
        parts.append(f'    <h3>Sektion: {_html_text(visibility)}</h3>')
        parts.append('    <table class="doxy-table doxy-section-member-table">')
        parts.append('      <thead><tr><th>Typ</th><th>Deklaration</th></tr></thead>')
        parts.append('      <tbody>')
        for idx, entry in enumerate(entries, start=1):
            label = {
                'field': 'Variable',
                'constructor': 'Konstruktor',
                'destructor': 'Destruktor',
                'method': 'Methode',
                'property': 'Property',
            }.get(entry.get('kind', ''), 'Member')
            detail_href = f"#sec-{visibility.replace(' ', '-')}-{idx}" if entry.get('details') else None
            desc = _render_description_cell(entry, detail_href)
            parts.append('        <tr class="doxy-member-main-row">')
            parts.append(f'          <td>{label}</td>')
            parts.append(f'          <td><code>{_linkify_pascal_text(entry["signature"], keyword_map, extra_map)}</code></td>')
            parts.append('        </tr>')
            parts.append('        <tr class="doxy-member-desc-row">')
            parts.append(f'          <td colspan="2">{desc}</td>')
            parts.append('        </tr>')
        parts.append('      </tbody>')
        parts.append('    </table>')
        for idx, entry in enumerate(entries, start=1):
            if not entry.get('details'):
                continue
            parts.append(f'    <div class="doxy-member-detail" id="sec-{visibility.replace(" ", "-")}-{idx}">')
            parts.append(f'      <h4><code>{_linkify_pascal_text(entry["signature"], keyword_map, extra_map)}</code></h4>')
            parts.append(f'      <div class="doxy-text-block">{_html_text(entry.get("details", ""))}</div>')
            if entry.get('since'):
                parts.append(f'      <div class="doxy-detail-since"><strong>Seit:</strong> {_html_text(entry.get("since", ""))}</div>')
            parts.append('    </div>')
        parts.append('  </div>')

    if details:
        parts.append('  <div class="doxy-card doxy-section-gap" id="class-details">')
        parts.append('    <h3>Details</h3>')
        parts.append(f'    <div class="doxy-text-block">{_html_text(details)}</div>')
        if since:
            parts.append(f'    <div class="doxy-detail-since"><strong>Seit:</strong> {_html_text(since)}</div>')
        parts.append('  </div>')

    display_source_lines = source_lines or [str(item.get('raw', '')) for item in declaration_lines if isinstance(item, dict) and item.get('raw')]
    if display_source_lines:
        parts.append('  <div class="doxy-card doxy-section-gap">')
        parts.append('    <h3>Quellcode</h3>')
        parts.append(_render_source_block_html(display_source_lines, keyword_map, extra_map, 'pascal'))
        parts.append('  </div>')

    parts.append('</div>')
    return '\n'.join(parts)


def generate_pascal_fallback_pages(xml_dir: Path, out_dir: Path, template_text: str | None, keyword_map: dict[str, str]) -> None:
    for xml_file in sorted(xml_dir.rglob('*.xml')):
        if xml_file.name == 'index.xml' or not is_pascal_file(xml_file):
            continue
        for class_info in extract_pascal_classes(xml_file):
            out_file = out_dir / str(class_info['out_name'])
            body_html = render_pascal_class_page(class_info, keyword_map)
            if template_text is not None:
                title = f"Klasse: {class_info['class_name']}"
                body_html = render_full_page(template_text, title, body_html)
            out_file.write_text(body_html, encoding='utf-8')


def class_language_from_file(file_name: str) -> str:
    f = file_name.lower()
    if f.endswith(('.py', '.pyw')):
        return 'Python'
    if f.endswith(('.pas', '.pp', '.p')):
        return 'Pascal'
    return 'C++'


def collect_real_classes(index_xml: Path, xml_dir: Path) -> list[dict[str, str]]:
    index_doc = parse_xml(index_xml)
    rows: list[dict[str, str]] = []
    for comp in index_doc.findall('/compound') if False else []:
        pass
    for comp in index_doc.findall('.//compound'):
        kind = comp.get('kind') or ''
        if kind not in {'class', 'struct', 'interface', 'protocol', 'exception'}:
            continue
        refid = comp.get('refid') or ''
        if not refid:
            continue
        xml_path = xml_dir / f'{refid}.xml'
        if not xml_path.exists():
            continue
        doc = parse_xml(xml_path)
        cdef = doc.find('compounddef')
        if cdef is None:
            cdef = doc.find('doxygen/compounddef')
        if cdef is None:
            continue
        compound_name = _text_content(cdef.find('compoundname')).strip() or _text_content(comp.find('name')).strip()
        simple_name = compound_name.split('::')[-1]
        location = cdef.find('location')
        file_name = (location.get('file') if location is not None else '') or ''
        brief = ' '.join(_text_content(cdef.find('briefdescription')).split())
        rows.append({
            'letter': (simple_name[:1] or '#').upper(),
            'lang': class_language_from_file(file_name),
            'name': simple_name,
            'brief': brief,
            'href': f'class_{slug_refid(refid)}.html',
        })
    return rows


def collect_pascal_fallback_classes(xml_dir: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for xml_file in sorted(xml_dir.rglob('*.xml')):
        if xml_file.name == 'index.xml' or not is_pascal_file(xml_file):
            continue
        for info in extract_pascal_classes(xml_file):
            rows.append({
                'letter': (str(info['class_name'])[:1] or '#').upper(),
                'lang': 'Pascal',
                'name': str(info['class_name']),
                'brief': str(info['brief'] or 'Aus Pascal-Datei extrahiert'),
                'href': str(info['out_name']),
            })
    return rows


def render_classes_index_html(index_xml: Path, xml_dir: Path) -> str:
    def esc(value: str) -> str:
        return value.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

    rows = collect_real_classes(index_xml, xml_dir)
    real_pascal = {row['name'] for row in rows if row['lang'] == 'Pascal'}
    for row in collect_pascal_fallback_classes(xml_dir):
        if row['name'] not in real_pascal:
            rows.append(row)
    rows.sort(key=lambda r: (r['letter'], r['lang'], r['name'].lower()))
    present_letters = {row['letter'] for row in rows if row['letter'].isalpha()}
    letters = list('ABCDEFGHIJKLMNOPQRSTUVWXYZ')

    parts = []
    parts.append('<div class="doxy-docs">')
    parts.append('  <div class="doxy-nav">')
    parts.append('    <a href="index.html">Start</a>')
    parts.append('    <a href="files.html">Dateien</a>')
    parts.append('    <a href="dirs.html">Verzeichnisse</a>')
    parts.append('    <a href="groups.html">Gruppen</a>')
    parts.append('    <a href="pages.html">Seiten</a>')
    parts.append('    <a href="classes.html">Klassen</a>')
    parts.append('    <a href="namespaces.html">Namespaces</a>')
    parts.append('    <a href="toc.html">TOC</a>')
    parts.append('  </div>')
    parts.append('  <div class="doxy-card">')
    parts.append('    <h2>Klassen</h2>')
    parts.append('    <div class="doxy-alpha-nav">')
    if rows:
        parts.append(' '.join((f'<a href="#classes-{esc(letter)}">{esc(letter)}</a>' if letter in present_letters else f'<span class="doxy-alpha-disabled">{esc(letter)}</span>') for letter in letters))
    else:
        parts.append('<span class="doxy-alpha-disabled">—</span>')
    parts.append('    </div>')
    parts.append('  </div>')

    for letter in letters:
        if letter not in present_letters:
            continue
        parts.append(f'  <div class="doxy-card doxy-section-gap">')
        parts.append(f'    <h3 id="classes-{esc(letter)}">{esc(letter)}</h3>')
        for lang in ('Python', 'Pascal', 'C++'):
            lang_rows = [r for r in rows if r['letter'] == letter and r['lang'] == lang]
            if not lang_rows:
                continue
            parts.append('    <div class="doxy-class-language-group">')
            parts.append(f'      <h4>{esc(lang)}</h4>')
            parts.append('      <table class="doxy-table doxy-class-table">')
            parts.append('        <thead><tr><th>Klasse</th><th>Beschreibung</th></tr></thead>')
            parts.append('        <tbody>')
            for row in lang_rows:
                parts.append('          <tr>')
                parts.append(f'            <td class="doxy-class-name-cell"><a href="{esc(row["href"])}">{esc(row["name"])}</a></td>')
                parts.append(f'            <td class="doxy-class-desc-cell">{esc(row["brief"] or "—")}</td>')
                parts.append('          </tr>')
            parts.append('        </tbody>')
            parts.append('      </table>')
            parts.append('    </div>')
        parts.append('  </div>')

    parts.append('</div>')
    return '\n'.join(parts)

def render_toc_html(index_xml: Path, graphics_count: int = 0, structures_count: int = 0) -> str:
    compounds = _collect_compounds(index_xml)

    groups = sorted([c for c in compounds if c['kind'] == 'group'], key=lambda x: x['name'].lower())
    pages = sorted([c for c in compounds if c['kind'] == 'page'], key=lambda x: x['name'].lower())
    files = sorted([c for c in compounds if c['kind'] == 'file'], key=lambda x: x['name'].lower())
    classes = sorted([c for c in compounds if c['kind'] in {'class','struct','interface','protocol','exception'}], key=lambda x: x['name'].lower())
    namespaces = sorted([c for c in compounds if c['kind'] == 'namespace'], key=lambda x: x['name'].lower())
    dirs = sorted([c for c in compounds if c['kind'] == 'dir'], key=lambda x: x['name'].lower())

    def list_items(items: list[dict[str, str]], empty: str = '—', strip_kw: bool = False) -> str:
        if not items:
            return f'<li class="doxy-muted">{_html_text(empty)}</li>'
        label_map = {
            'de_cpp_overview': 'C++ Überblick',
            'de_pas_overview': 'Pascal Übersicht',
            'de_py_overview': 'Python Übersicht',
        }
        html_items = []
        for item in items:
            if not item.get('href'):
                continue
            label = _display_keyword_name(item['name']) if strip_kw else label_map.get(item['name'], item['name'])
            html_items.append(f'<li><a href="{_html_text(item["href"])}">{_html_text(label)}</a></li>')
        return ''.join(html_items) or f'<li class="doxy-muted">{_html_text(empty)}</li>'

    def section(title: str, items: list[dict[str, str]], empty: str = '—', strip_kw: bool = False, scroll: bool = False, body_class: str = 'doxy-toc-list') -> str:
        wrap_class = 'doxy-badge-scroll' if scroll else ''
        return f'<div class="doxy-card"><h3>{_html_text(title)}</h3><div class="{wrap_class}"><ul class="{body_class}">{list_items(items, empty, strip_kw)}</ul></div></div>'

    def prefix_items(prefix: str) -> list[dict[str, str]]:
        return [c for c in pages if c['name'].lower().startswith(prefix)]

    def named_items(names: list[str], pool: list[dict[str, str]]) -> list[dict[str, str]]:
        wanted = {name.lower() for name in names}
        return [item for item in pool if item['name'].lower() in wanted]

    def build_dir_tree(items: list[dict[str, str]]) -> str:
        tree = {}
        for item in items:
            parts = [p for p in item['name'].split('/') if p]
            node = tree
            for idx, part in enumerate(parts):
                node = node.setdefault(part, {'__href__': item['href'] if idx == len(parts)-1 else '', '__children__': {}})['__children__']
        def render_nodes(children: dict[str, dict]) -> str:
            if not children:
                return '<li class="doxy-muted">Keine Verzeichnisse gefunden</li>'
            out=[]
            for name in sorted(children.keys(), key=str.lower):
                data=children[name]
                sub=data.get('__children__', {})
                href=data.get('__href__','')
                label=f'<a href="{_html_text(href)}">{_html_text(name)}</a>' if href else _html_text(name)
                if sub:
                    out.append('<li class="folder"><details open><summary><span class="doxy-tree-caret"></span><span class="doxy-tree-label"><span class="folder-icon"></span>'+label+'</span></summary><ul>'+render_nodes(sub)+'</ul></details></li>')
                else:
                    out.append('<li class="file"><span class="doxy-tree-label"><span class="file-icon"></span>'+label+'</span></li>')
            return ''.join(out)
        return '<ul class="doxy-tree-view">'+render_nodes(tree)+'</ul>'

    start_items = [
        {'name': 'Startseite', 'href': 'index.html'},
        {'name': 'Klassen', 'href': 'classes.html'},
        {'name': 'Dateien', 'href': 'files.html'},
        {'name': 'Verzeichnisse', 'href': 'dirs.html'},
        {'name': 'Namespaces', 'href': 'namespaces.html'},
        {'name': 'Seiten', 'href': 'pages.html'},
        {'name': 'Gruppen', 'href': 'groups.html'},
    ]

    language_groups = named_items(['cpp', 'pascal', 'python'], groups)
    overview_pages = named_items(['de_cpp_overview', 'de_pas_overview', 'de_py_overview'], pages)
    pascal_keyword_pages = prefix_items('kw_pas_')
    python_keyword_pages = prefix_items('kw_py_')
    cpp_keyword_pages = prefix_items('kw_cpp_')
    qt_items = [item for item in classes + namespaces + files if 'qrect' in item['name'].lower() or 'mainwindow' in item['name'].lower() or 'application' in item['name'].lower()]
    readme_items = [item for item in files if 'readme' in item['name'].lower()]
    keyword_docs = [item for item in files if 'keywords_' in item['name'].lower()]

    parts = []
    parts.append('<div class="doxy-docs">')
    parts.append('  <div class="doxy-nav">')
    parts.append('    <a href="index.html">Start</a>')
    parts.append('    <a href="files.html">Dateien</a>')
    parts.append('    <a href="dirs.html">Verzeichnisse</a>')
    parts.append('    <a href="groups.html">Gruppen</a>')
    parts.append('    <a href="pages.html">Seiten</a>')
    parts.append('    <a href="classes.html">Klassen</a>')
    parts.append('    <a href="namespaces.html">Namespaces</a>')
    parts.append('    <a href="toc.html">TOC</a>')
    parts.append('  </div>')
    parts.append('  <div class="doxy-card">')
    parts.append('    <h2>TOC</h2>')
    parts.append('    <p class="doxy-muted">Themenorientierter Einstieg in die Dokumentation. Diese Seite wird bei jedem Build automatisch aus Doxygen-XML durch das Python/XSLT-Setup neu erzeugt.</p>')
    parts.append('  </div>')
    parts.append('  <div class="doxy-grid doxy-section-gap">')
    parts.append(section('Einstieg', start_items))
    parts.append(f'<div class="doxy-card"><h3>Grafiken</h3><div class="doxy-kpi">{graphics_count}</div><div class="doxy-badge-label"><a href="graphics.html">Zur Grafik-Übersicht</a></div></div>')
    parts.append(f'<div class="doxy-card"><h3>Tabellen / Listen</h3><div class="doxy-kpi">{structures_count}</div><div class="doxy-badge-label"><a href="tables_lists.html">Zur Tabellen-/Listen-Übersicht</a></div></div>')
    parts.append(section('Sprachgruppen', language_groups, 'Keine Sprachgruppen gefunden'))
    parts.append(section('Übersichten', overview_pages, 'Keine Übersichtsseiten gefunden'))
    parts.append(section('Qt / Beispiele', qt_items, 'Keine Qt-Beispiele gefunden', scroll=True))
    parts.append(section('Pascal-Schlüsselwörter', pascal_keyword_pages, 'Keine Pascal-Seiten gefunden', strip_kw=True, scroll=True))
    parts.append(section('Python-Schlüsselwörter', python_keyword_pages, 'Keine Python-Seiten gefunden', strip_kw=True, scroll=True))
    parts.append(section('C++-Schlüsselwörter', cpp_keyword_pages, 'Keine C++-Seiten gefunden', strip_kw=True, scroll=True))
    parts.append(section('Keyword-Dateien', keyword_docs, 'Keine Keyword-Dateien gefunden', scroll=True))
    parts.append(section('README / Einführung', readme_items, 'Keine README-Dateien gefunden'))
    parts.append(f'<div class="doxy-card"><h3>Verzeichnisse</h3><div class="doxy-badge-scroll doxy-badge-scroll-tree">{build_dir_tree(dirs)}</div></div>')
    parts.append(section('Klassen', classes, 'Keine Klassen gefunden', scroll=True))
    parts.append(section('Namespaces', namespaces, 'Keine Namespaces gefunden', scroll=True))
    parts.append(section('Gruppen', groups, 'Keine Gruppen gefunden', scroll=True))
    parts.append(section('Seiten', pages, 'Keine Seiten gefunden', scroll=True))
    parts.append('  </div>')
    parts.append('</div>')
    return '\n'.join(parts)



def patch_start_index_html(index_file: Path, graphics_count: int, structures_count: int) -> None:
    if not index_file.exists():
        return
    html = index_file.read_text(encoding='utf-8')
    badges = (
        f'<div class="doxy-card"><a class="doxy-badge-label" href="graphics.html">Grafik</a><div class="doxy-kpi">{graphics_count}</div></div>\n'
        f'<div class="doxy-card"><a class="doxy-badge-label" href="tables_lists.html">Tabellen</a><div class="doxy-kpi">{structures_count}</div></div>\n'
    )
    if 'href="graphics.html">Grafik</a>' in html and 'href="tables_lists.html">Tabellen</a>' in html:
        return

    toc_card_re = re.compile(
        r'(<div class="doxy-card">\s*<a class="doxy-badge-label" href="toc\.html">TOC</a>\s*<div class="doxy-kpi">.*?</div>\s*</div>)',
        flags=re.S,
    )
    match = toc_card_re.search(html)
    if match:
        html = html[:match.end(1)] + '\n' + badges.rstrip() + html[match.end(1):]
    else:
        grid_marker = '<div class="doxy-grid doxy-section-gap">'
        pos = html.find(grid_marker)
        if pos != -1:
            html = html[:pos] + badges + html[pos:]
        else:
            html += '\n' + badges
    index_file.write_text(html, encoding='utf-8')

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Wandelt Doxygen-XML mit XSLT in HTML-Body-Fragmente oder vollständige HTML-Seiten um."
    )
    ap.add_argument("xml_dir", type=Path, help="Ordner mit Doxygen-XML, z. B. xml")
    ap.add_argument("xslt_dir", type=Path, help="Ordner mit XSLT-Dateien, z. B. xslt")
    ap.add_argument("-o", "--out-dir", type=Path, default=Path("out"), help="Ausgabeordner")
    ap.add_argument("--template", type=Path, default=None, help="Optionales Host-Template mit {{ title }} und {{ body_html }}")
    ap.add_argument("--full-pages", action="store_true", help="Erzeugt vollständige HTML-Seiten mit Host-Template")
    args = ap.parse_args()

    if not args.xml_dir.exists():
        ap.error(f"XML-Ordner nicht gefunden: {args.xml_dir}")
    if not args.xslt_dir.exists():
        ap.error(f"XSLT-Ordner nicht gefunden: {args.xslt_dir}")

    index_xml = args.xml_dir / "index.xml"
    if not index_xml.exists():
        ap.error(f"index.xml nicht gefunden in: {args.xml_dir}")

    args.out_dir.mkdir(parents=True, exist_ok=True)

    css_src = args.xslt_dir / "doxygen-doc.css"
    if css_src.exists():
        shutil.copy2(css_src, args.out_dir / "doxygen-doc.css")

    template_text = None
    if args.full_pages:
        template_path = args.template if args.template is not None else Path("example_template.html")
        if not template_path.exists():
            ap.error(f"Template nicht gefunden: {template_path}")
        template_text = template_path.read_text(encoding="utf-8")

    for key, xslt_name in INDEX_OVERVIEW_MAP.items():
        out_file = args.out_dir / OUTNAMES[key]
        if key == "classes":
            body_html = render_classes_index_html(index_xml, args.xml_dir)
            if template_text is not None:
                body_html = render_full_page(template_text, "Klassen", body_html)
            out_file.write_text(body_html, encoding="utf-8")
            continue
        transform(index_xml, args.xslt_dir / xslt_name, out_file)
        if template_text is not None:
            body_html = out_file.read_text(encoding="utf-8")
            title = fragment_title(body_html, OUTNAMES[key])
            out_file.write_text(render_full_page(template_text, title, body_html), encoding="utf-8")

    for xml_file in sorted(args.xml_dir.rglob("*.xml")):
        if xml_file.name == "index.xml":
            continue

        kind = compound_kind(xml_file)
        refid = compound_refid(xml_file)
        if kind not in XSLT_MAP or not refid:
            continue

        out_name = f"{kind}_{slug_refid(refid)}.html"
        out_file = args.out_dir / out_name
        transform(xml_file, args.xslt_dir / XSLT_MAP[kind], out_file)

        if template_text is not None:
            body_html = out_file.read_text(encoding="utf-8")
            title = fragment_title(body_html, out_name)
            out_file.write_text(render_full_page(template_text, title, body_html), encoding="utf-8")

    keyword_map = build_keyword_href_map(args.out_dir)
    graphics_count, structures_count = write_visual_pages(index_xml, args.xml_dir, args.out_dir, template_text)
    patch_start_index_html(args.out_dir / 'index.html', graphics_count, structures_count)
    toc_html = render_toc_html(index_xml, graphics_count, structures_count)
    if template_text is not None:
        toc_html = render_full_page(template_text, 'TOC', toc_html)
    (args.out_dir / 'toc.html').write_text(toc_html, encoding='utf-8')

    generate_pascal_fallback_pages(args.xml_dir, args.out_dir, template_text, keyword_map)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
