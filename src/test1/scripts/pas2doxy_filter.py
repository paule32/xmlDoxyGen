#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path

VIS = {'private':'private:', 'public':'public:', 'protected':'protected:', 'published':'public:'}


def transform_line(line:str)->str:
    s=line.rstrip('\n')
    ind=re.match(r'\s*', s).group(0)
    t=s.strip()
    low=t.lower()

    # Keep comments and empty lines untouched
    if not t or t.startswith('///') or t.startswith('//') or t.startswith('{') or t.startswith('(*') or t.startswith('*') or t.startswith('/**') or t.startswith('*/'):
        return s

    m=re.match(r'(?i)^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*class(?:\(([^)]*)\))?\s*;?\s*$', t)
    if m:
        name, base = m.group(1), (m.group(2) or '').strip()
        if base:
            return f'{ind}class {name} : public {base} {{'
        return f'{ind}class {name} {{'

    if low in VIS:
        return ind + VIS[low]

    if re.match(r'(?i)^end\s*;\s*$', t):
        return ind + '};'

    m=re.match(r'(?i)^constructor\s+([A-Za-z_][A-Za-z0-9_]*)\s*(\([^;]*\))?\s*;\s*$', t)
    if m:
        name,args=m.group(1),m.group(2) or '()'
        return f'{ind}{name}{args};'

    m=re.match(r'(?i)^destructor\s+([A-Za-z_][A-Za-z0-9_]*)\s*(\([^;]*\))?\s*;\s*(?:override|overload|virtual|reintroduce|dynamic|abstract|final|sealed|message|static|inline|override|overwrite)?\s*;?\s*$', t)
    if m:
        name,args=m.group(1),m.group(2) or '()'
        return f'{ind}~{name}{args};'

    m=re.match(r'(?i)^procedure\s+([A-Za-z_][A-Za-z0-9_]*)\s*(\([^;]*\))?\s*;.*$', t)
    if m:
        name,args=m.group(1),m.group(2) or '()'
        return f'{ind}void {name}{args};'

    m=re.match(r'(?i)^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*(\([^;]*\))?\s*:\s*([^;]+);.*$', t)
    if m:
        name,args,ret=m.group(1),m.group(2) or '()',m.group(3).strip()
        return f'{ind}{ret} {name}{args};'

    m=re.match(r'(?i)^property\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^;]+);.*$', t)
    if m:
        name,typ=m.group(1),m.group(2).strip()
        return f'{ind}{typ} {name};'

    m=re.match(r'(?i)^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^;]+);\s*$', t)
    if m:
        name,typ=m.group(1),m.group(2).strip()
        return f'{ind}{typ} {name};'

    # neutralize unit/interface/implementation/type sections for parser
    if low in {'unit','interface','implementation','type'} or low.startswith('unit ') or low.startswith('interface') or low.startswith('implementation') or low.startswith('type'):
        return ind + '// ' + t

    return s


def main():
    if len(sys.argv) != 2:
        print('usage: pas2doxy_filter.py <file>', file=sys.stderr)
        return 1
    path = Path(sys.argv[1])
    text = path.read_text(encoding='utf-8', errors='replace').splitlines(True)
    out=[]
    for line in text:
        nl='\n' if line.endswith('\n') else ''
        out.append(transform_line(line)+nl)
    sys.stdout.write(''.join(out))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
