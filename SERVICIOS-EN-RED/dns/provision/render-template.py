#!/usr/bin/env python3

import json
import os
import re
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: render-template.py TEMPLATE DESTINATION")

    template_path = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    content = template_path.read_text()

    for name in set(re.findall(r"@@([A-Z][A-Z0-9_]*)@@", content)):
        value = os.environ.get(name)
        if value is None:
            raise SystemExit(f"missing template variable: {name}")
        content = content.replace(f"@@{name}@@", value)

    unresolved = re.findall(r"@@([A-Z][A-Z0-9_]*)@@", content)
    if unresolved:
        raise SystemExit(f"unresolved template variables: {', '.join(unresolved)}")
    if template_path.name.endswith(".json.tmpl"):
        json.loads(content)

    destination.write_text(content)
    destination.chmod(0o640)


if __name__ == "__main__":
    main()
