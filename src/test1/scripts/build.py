#!/usr/bin/env python3

# (c) 2026 by Jens Kallup - paule32
# all rights reserved.
#
# python build.py index.xml -o test.html -s index.xslt

from __future__  import annotations

import argparse
import html
import sys

from dataclasses import dataclass, field
from pathlib     import Path
from typing      import Optional
from lxml        import etree

@dataclass
class DirEntry:
    refid     : str
    name      : str
    location  : str = ""
    innerdirs : list[tuple[str, str]] = field(default_factory=list)
    innerfiles: list[tuple[str, str]] = field(default_factory=list)

def read_xml(path: Path) -> etree._ElementTree:
    return etree.parse(str(path))
    
def validate_xml(xml_path: Path, xsd_path: Path) -> bool:
    try:
        xml_doc = etree.parse(str(xml_path))
        xsd_doc = etree.parse(str(xsd_path))
        schema = etree.XMLSchema(xsd_doc)

        if schema.validate(xml_doc):
            print(f"[OK] Valide: {xml_path}")
            return True

        print(f"[ERROR] Invalid: {xml_path}", file=sys.stderr)
        for error in schema.error_log:
            print(
                f"  Line {error.line}, Column {error.column}: {error.message}",
                file=sys.stderr,
            )
        return False

    except Exception as exc:
        print(f"[ERROR] Verify fail: {exc}", file=sys.stderr)
        return False

def transform_xml_to_html(xml_path: Path, xslt_path: Path, html_path: Path) -> bool:
    try:
        xml_doc = etree.parse(str(xml_path))
        xslt_doc = etree.parse(str(xslt_path))
        transform = etree.XSLT(xslt_doc)
        result = transform(xml_doc)

        html_bytes = etree.tostring(
            result,
            pretty_print=True,
            method="html",
            encoding="UTF-8",
        )

        print(f"DEBUG Output-Size: {len(html_bytes)} Bytes")

        html_path.parent.mkdir(parents=True, exist_ok=True)
        html_path.write_bytes(html_bytes)

        print(f"[OK] {xml_path} -> {html_path}")
        return True

    except Exception as exc:
        print(f"[ERROR] Transform failed: {exc}", file=sys.stderr)
        return False

def html_page(title: str, body: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <title>{html.escape(title)}</title>
  <style>
    body {{
      font-family: Arial, Helvetica, sans-serif;
      margin: 2rem auto;
      max-width: 1100px;
      line-height: 1.45;
      padding: 0 1rem;
    }}
    h1, h2, h3 {{
      margin-bottom: 0.5rem;
    }}
    a {{
      text-decoration: none;
      color: #0b57d0;
    }}
    a:hover {{
      text-decoration: underline;
    }}
    .muted {{
      color: #666;
    }}
    .card {{
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 1rem;
      margin: 1rem 0;
      background: #fafafa;
    }}
    .breadcrumbs {{
      margin-bottom: 1rem;
      font-size: 0.95rem;
    }}
    .breadcrumbs a {{
      color: #0b57d0;
    }}
    table {{
      border-collapse: collapse;
      width: 100%;
      margin: 1rem 0 2rem 0;
    }}
    th, td {{
      border: 1px solid #ccc;
      padding: 0.55rem 0.75rem;
      text-align: left;
      vertical-align: top;
    }}
    th {{
      background: #f1f1f1;
    }}
    code {{
      background: #f4f4f4;
      padding: 0.1rem 0.35rem;
      border-radius: 4px;
    }}
    ul {{
      margin-top: 0.4rem;
    }}
    .badge {{
      display: inline-block;
      padding: 0.15rem 0.45rem;
      border-radius: 999px;
      background: #eee;
      font-size: 0.85rem;
      margin-left: 0.4rem;
    }}
  </style>
</head>
<body>
{body}
</body>
</html>
"""

def parse_index(index_path: Path) -> tuple[list[tuple[str, str]], list[tuple[str, str, str]]]:
    doc = read_xml(index_path)
    root = doc.getroot()

    all_compounds: list[tuple[str, str]] = []
    dirs: list[tuple[str, str, str]] = []

    for compound in root.findall("compound"):
        refid = compound.get("refid", "")
        kind = compound.get("kind", "")
        name = (compound.findtext("name") or "").strip()

        all_compounds.append((kind, name))

        if kind == "dir":
            dirs.append((refid, name, kind))

    return all_compounds, dirs
    
def parse_dir_xml(dir_xml_path: Path) -> Optional[DirEntry]:
    if not dir_xml_path.exists():
        return None

    doc = read_xml(dir_xml_path)
    compounddef = doc.find("compounddef")
    if compounddef is None:
        compounddef = doc.find("doxygen/compounddef")
    if compounddef is None:
        return None

    refid = compounddef.get("id", "")
    name = (compounddef.findtext("compoundname") or "").strip()
    location = ""
    location_node = compounddef.find("location")
    if location_node is not None:
        location = location_node.get("file", "")

    entry = DirEntry(refid=refid, name=name, location=location)

    for innerdir in compounddef.findall("innerdir"):
        entry.innerdirs.append(
            (innerdir.get("refid", ""), (innerdir.text or "").strip())
        )

    for innerfile in compounddef.findall("innerfile"):
        entry.innerfiles.append(
            (innerfile.get("refid", ""), (innerfile.text or "").strip())
        )

    return entry
    
def render_index_page(
    all_compounds: list[tuple[str, str]],
    dir_entries: list[DirEntry]) -> str:
    rows = []
    for kind, name in sorted(all_compounds, key=lambda x: (x[0], x[1].lower())):
        rows.append(
            "<tr>"
            f"<td>{html.escape(kind)}</td>"
            f"<td>{html.escape(name)}</td>"
            "</tr>"
        )

    dir_cards = []
    for entry in sorted(dir_entries, key=lambda x: x.name.lower()):
        dir_cards.append(
            f"""
            <div class="card">
              <h3><a href="{html.escape(entry.refid)}.html">{html.escape(entry.name)}</a></h3>
              <div class="muted">
                Pfad: <code>{html.escape(entry.location or entry.name)}</code>
              </div>
              <div class="muted">
                Unterverzeichnisse: {len(entry.innerdirs)} |
                Dateien: {len(entry.innerfiles)}
              </div>
            </div>
            """
        )

    body = f"""
    <h1>Doxygen HTML-Übersicht</h1>
    <p>
      Startseite für die aus XML erzeugte Dokumentation.
    </p>

    <h2>Verzeichnisse</h2>
    {''.join(dir_cards) if dir_cards else '<p>Keine Verzeichnisse gefunden.</p>'}

    <h2>Alle Index-Einträge</h2>
    <table>
      <thead>
        <tr>
          <th>Typ</th>
          <th>Name</th>
        </tr>
      </thead>
      <tbody>
        {''.join(rows)}
      </tbody>
    </table>
    """
    return html_page("Doxygen HTML-Übersicht", body)

def build_breadcrumbs(name: str) -> str:
    parts = [p for p in name.split("/") if p]
    if not parts:
        return '<div class="breadcrumbs"><a href="index.html">Start</a></div>'

    chunks: list[str] = ['<a href="index.html">Start</a>']
    current = []

    for part in parts:
        current.append(part)
        chunks.append(html.escape(part))

    return f'<div class="breadcrumbs">{" / ".join(chunks)}</div>'
    
def render_dir_page(entry: DirEntry, known_dirs: dict[str, DirEntry]) -> str:
    breadcrumbs = build_breadcrumbs(entry.name)

    innerdir_html = []
    for refid, name in sorted(entry.innerdirs, key=lambda x: x[1].lower()):
        if refid in known_dirs:
            link = f'<a href="{html.escape(refid)}.html">{html.escape(name)}</a>'
        else:
            link = html.escape(name)
        innerdir_html.append(
            f"<li>{link} <span class='muted'>(<code>{html.escape(refid)}</code>)</span></li>"
        )

    innerfile_html = []
    for refid, name in sorted(entry.innerfiles, key=lambda x: x[1].lower()):
        innerfile_html.append(
            f"<li>{html.escape(name)} <span class='muted'>(<code>{html.escape(refid)}</code>)</span></li>"
        )

    body = f"""
    {breadcrumbs}
    <h1>{html.escape(entry.name)} <span class="badge">Verzeichnis</span></h1>

    <div class="card">
      <div><strong>RefID:</strong> <code>{html.escape(entry.refid)}</code></div>
      <div><strong>Pfad:</strong> <code>{html.escape(entry.location or entry.name)}</code></div>
    </div>

    <div class="card">
      <h2>Unterverzeichnisse</h2>
      {"<ul>" + "".join(innerdir_html) + "</ul>" if innerdir_html else "<p>Keine Unterverzeichnisse.</p>"}
    </div>

    <div class="card">
      <h2>Dateien</h2>
      {"<ul>" + "".join(innerfile_html) + "</ul>" if innerfile_html else "<p>Keine Dateien.</p>"}
    </div>

    <p><a href="index.html">← Zurück zur Übersicht</a></p>
    """
    return html_page(entry.name, body)
    
def build_site(input_dir: Path, output_dir: Path) -> int:
    index_path = input_dir / "index.xml"
    if not index_path.exists():
        print(f"[FEHLER] index.xml nicht gefunden in: {input_dir}", file=sys.stderr)
        return 1

    all_compounds, dir_refs = parse_index(index_path)

    dir_entries: list[DirEntry] = []
    known_dirs: dict[str, DirEntry] = {}

    for refid, name, _kind in dir_refs:
        dir_xml_path = input_dir / f"{refid}.xml"
        entry = parse_dir_xml(dir_xml_path)

        if entry is None:
            # Fallback: Eintrag aus index.xml trotzdem anzeigen
            entry = DirEntry(refid=refid, name=name, location=name)

        dir_entries.append(entry)
        known_dirs[entry.refid] = entry

    output_dir.mkdir(parents=True, exist_ok=True)

    index_html = render_index_page(all_compounds, dir_entries)
    (output_dir / "index.html").write_text(index_html, encoding="utf-8")
    print(f"[OK] {output_dir / 'index.html'}")

    for entry in dir_entries:
        page_html = render_dir_page(entry, known_dirs)
        out_path = output_dir / f"{entry.refid}.html"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(page_html, encoding="utf-8")
        print(f"[OK] {out_path}")

    return 0
    
def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Transforms exactly one XML-File per XSLT to HTML."
    )
    parser.add_argument("-i", "--input-dir"   , type=Path, help="Path to XML-File")
    parser.add_argument("-s", "--xslt"  , type=Path, required=False, help="Path to XSLT-File")
    parser.add_argument("-o", "--output-dir", type=Path, required=True , help="Path to HTML-Output-File")
    parser.add_argument("-d", "--validate-index"   , type=Path, default=None  , help="Optional Path to XSD-File")
    return parser

def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    input_dir : Path = args.input_dir
    output_dir: Path = args.output_dir

    if not input_dir.exists():
        print(f"[FEHLER] Eingabeordner nicht gefunden: {input_dir}", file=sys.stderr)
        return 1

    index_xml = input_dir / "index.xml"
    if not index_xml.exists():
        print(f"[FEHLER] index.xml nicht gefunden in: {input_dir}", file=sys.stderr)
        return 1

    if args.validate_index is not None:
        xsd_path: Path = args.validate_index
        if not xsd_path.exists():
            print(f"[FEHLER] XSD-Datei nicht gefunden: {xsd_path}", file=sys.stderr)
            return 1
        if not validate_xml(index_xml, xsd_path):
            return 2

    return build_site(input_dir, output_dir)

if __name__ == "__main__":
    sys.exit(main())
