# Python-NoAdmin - bin directory

This directory contains the bootstrap Python used by the installer scripts.

**Do not commit this directory to version control** if it contains downloaded Python binaries.

The `install.cmd` (Windows) and `install.sh` (Unix) scripts will automatically
download a portable Python here on first run.

## Structure after first run:

```
bin/
└── python/           # Bootstrap Python installation
    ├── python.exe    # (Windows) or bin/python3 (Unix)
    └── ...
```

## To reset:

Delete the `python/` subdirectory to force re-download of the bootstrap Python.
