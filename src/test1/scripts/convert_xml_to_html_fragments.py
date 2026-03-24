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
import re
import shutil
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

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
