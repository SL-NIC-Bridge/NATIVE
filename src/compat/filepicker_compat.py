"""Compatibility wrapper for Flet FilePicker payloads.

This module provides a repo-local, committed compatibility shim that makes
`FilePickerResultEvent` tolerant when platform payloads omit the `id`
field. Import this module early in your application (for example from
`main.py`) so it takes effect before any `FilePicker` is created.

This avoids editing the virtualenv/site-packages and is reproducible for all
developers when committed to source control. Remove this shim once the
underlying platform or Flet runtime is updated upstream.
"""
import json
from typing import List, Optional, Any
import os
import base64
import logging
import tempfile
import datetime
import json as _json
import time  # <--- ADDED FOR RETRY LOGIC

from flet.core.control_event import ControlEvent

try:
    import flet.core.file_picker as _fp_mod
    # Capture reference to original FilePickerFile in case it's needed
    _OriginalFilePickerFile = getattr(_fp_mod, "FilePickerFile", None)

    class FilePickerResultEvent(ControlEvent):
        """Tolerant replacement for flet.core.file_picker.FilePickerResultEvent.

        This normalizes each file dict to ensure the 'id' key exists (set to
        None when missing) before constructing FilePickerFile instances.
        """
        def __init__(self, e: ControlEvent):
            super().__init__(e.target, e.name, e.data, e.control, e.page)
            d = json.loads(e.data)
            self.path: Optional[str] = d.get("path")
            self.files: Optional[List[Any]] = None
            files_data = d.get("files")
            if files_data is not None and isinstance(files_data, List):
                self.files = []
                for fd in files_data:
                    try:
                        # Ensure fd is a dict and has an 'id' key
                        if not isinstance(fd, dict):
                            # Try to coerce mapping-like objects
                            fd = dict(fd)
                        # Guarantee presence of 'id' key (may be None)
                        if "id" not in fd:
                            fd["id"] = None
                    except Exception:
                        # If coercion fails, wrap minimal structure
                        fd = {"name": None, "path": None, "size": 0, "id": None}

                    # Construct FilePickerFile using the original class (if available)
                    if _OriginalFilePickerFile:
                        try:
                            obj = _OriginalFilePickerFile(**fd)

                            # Try to ensure the object has a bytes payload when possible.
                            file_bytes = None

                            # 1) If fd contains a 'bytes' value, try to coerce it.
                            if "bytes" in fd and fd["bytes"] is not None:
                                bval = fd["bytes"]
                                # base64-encoded string
                                if isinstance(bval, str):
                                    try:
                                        file_bytes = base64.b64decode(bval)
                                    except Exception:
                                        try:
                                            file_bytes = bval.encode("utf-8")
                                        except Exception:
                                            file_bytes = None
                                # list/tuple of ints
                                elif isinstance(bval, (list, tuple)):
                                    try:
                                        file_bytes = bytes(bval)
                                    except Exception:
                                        file_bytes = None
                                # already bytes-like
                                elif isinstance(bval, (bytes, bytearray)):
                                    file_bytes = bytes(bval)

                            # 2) If still missing, try reading from a local path
                            if file_bytes is None and fd.get("path"):
                                p = fd.get("path")
                                if isinstance(p, str):
                                    
                                    # ========================================================== #
                                    # START: MODIFIED SECTION WITH RETRY LOGIC                   #
                                    # ========================================================== #
                                    # This handles a race condition on mobile where the event
                                    # arrives before the file copy is complete.
                                    
                                    max_retries = 5
                                    retry_delay = 1  # 200 milliseconds

                                    for attempt in range(max_retries):
                                        try:
                                            if os.path.exists(p):
                                                with open(p, "rb") as _f:
                                                    file_bytes = _f.read()
                                                # If read is successful, break the loop
                                                break
                                            else:
                                                # File does not exist yet, wait before retrying
                                                time.sleep(retry_delay)
                                        except Exception as ex:
                                            # If another error occurs during read, wait and retry
                                            print(f"Warning: unable to read file on attempt {attempt + 1}: {ex}")
                                            time.sleep(retry_delay)
                                    # ========================================================== #
                                    # END: MODIFIED SECTION                                      #
                                    # ========================================================== #


                            # If we obtained bytes, attach them to the object (best-effort).
                            if file_bytes is not None:
                                try:
                                    setattr(obj, "bytes", file_bytes)
                                except Exception:
                                    # ignore if attribute can't be set
                                    pass
                            else:
                                # Debug: record a trimmed payload when bytes couldn't be obtained.
                                DEBUG = os.environ.get("FILEPICKER_COMPAT_DEBUG", "").lower() in ("1", "true", "yes")
                                if DEBUG:
                                    try:
                                        logger = logging.getLogger("filepicker_compat")
                                        short_fd = {k: fd.get(k) for k in ("id", "name", "path", "size", "mime_type") if isinstance(fd, dict) and k in fd}
                                        msg = f"filepicker_compat: unable to read bytes for file: {short_fd}"
                                        # Print to console for visibility
                                        print(msg)
                                        # Append a JSON line to a small debug log in tempdir
                                        tmp = tempfile.gettempdir()
                                        stamp = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
                                        pid = os.getpid()
                                        fname = os.path.join(tmp, f"filepicker_compat_debug_{stamp}_{pid}.jsonl")
                                        with open(fname, "a", encoding="utf-8") as _f:
                                            _f.write(_json.dumps({"ts": stamp, "file": short_fd}) + "\n")
                                    except Exception:
                                        # Never let debugging break runtime
                                        pass

                            self.files.append(obj)
                        except Exception:
                            # Fallback: append the raw dict if construction fails
                            self.files.append(fd)
                    else:
                        self.files.append(fd)

    # Install the compatibility class into the flet module
    _fp_mod.FilePickerResultEvent = FilePickerResultEvent

except Exception as _ex:
    # Non-fatal: if import fails, skip compatibility shim. Log for visibility.
    print(f"filepicker_compat: skipped installing shim: {_ex}")