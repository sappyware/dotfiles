#!/usr/bin/env python3
import json, sys
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("{}")
        sys.exit(0)
try:
    with open(sys.argv[1], "rb") as f:
        print(json.dumps(tomllib.load(f)))
except Exception as e:
    sys.stderr.write(str(e) + "\n")
    print("{}")
    sys.exit(1)
