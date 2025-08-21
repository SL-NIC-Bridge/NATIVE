import flet as ft
import uuid
from typing import Dict, Any, Callable

def create_file_upload(
    field: Dict[str, Any],
    field_key: str,
    page: ft.Page,
    state: Dict[str, Any],
    handle_change_callback: Callable,
    validate_callback: Callable
) -> ft.Column:
    """
    Create a self-contained file upload control using the correct two-step
    "pick then upload" Flet pattern. This version correctly generates the
    required upload_url and is reliable on all platforms.
    """

    # --- UI Components ---
    progress_bars: Dict[str, ft.ProgressRing] = {}
    upload_button = ft.ElevatedButton(
        f"Select {field['label']}",
        icon=ft.Icons.FOLDER_OPEN,
    )
    file_list = ft.Column(spacing=8)
    status_row = ft.Row(visible=False, controls=[ft.Text("Uploading...")])


    # --- Step 3: Handle individual file upload completion and progress ---
    def on_upload_progress(e: ft.FilePickerUploadEvent):
        if e.file_name in progress_bars:
            progress_bars[e.file_name].value = e.progress
            progress_bars[e.file_name].update()

        if e.progress and e.progress >= 1.0:
            file_info = {
                'name': e.file_name, 'path': e.path, 'size': e.size, 'id': str(uuid.uuid4())
            }
            if field.get('multiple', True):
                state['files'][field_key].append(file_info)
            else:
                state['files'][field_key] = [file_info]
            
            all_done = all(p.value >= 1.0 for p in progress_bars.values())
            if all_done:
                on_all_uploads_complete()


    # --- Step 2: Handle the result of the file picker and start the upload ---
    def on_files_picked(e: ft.FilePickerResultEvent):
        if not e.files:
            return

        if field_key not in state['files']:
            state['files'][field_key] = []
        
        progress_bars.clear()
        status_row.controls.clear()
        status_row.controls.append(ft.Text("Uploading...", weight=ft.FontWeight.BOLD))
        
        files_to_upload = []
        for f in e.files:
            prog = ft.ProgressRing(width=20, height=20, stroke_width=2, value=0)
            progress_bars[f.name] = prog
            status_row.controls.append(
                ft.Row([prog, ft.Text(f.name, size=12, overflow=ft.TextOverflow.ELLIPSIS, expand=True)])
            )
            
            # ========================================================== #
            # START: THIS IS THE CRITICAL FIX                            #
            # ========================================================== #
            # We must generate an upload URL for each file.
            upload_url = page.get_upload_url(f.name, 600)  # URL expires in 10 minutes
            files_to_upload.append(
                ft.FilePickerUploadFile(
                    f.name,
                    upload_url=upload_url
                )
            )
            # ========================================================== #
            # END: CRITICAL FIX                                          #
            # ========================================================== #

        status_row.visible = True
        upload_button.disabled = True
        page.update()

        file_picker.upload(files_to_upload)

    # --- Step 1: Initialize the file picker and wire it up ---
    file_picker = ft.FilePicker(on_result=on_files_picked, on_upload=on_upload_progress)
    page.overlay.append(file_picker)
    upload_button.on_click = lambda _: file_picker.pick_files(
        allow_multiple=field.get('multiple', True),
        allowed_extensions=field.get('allowed_extensions'),
        dialog_title=f"Select {field['label']}"
    )

    # --- Finalization and Helper Functions (Unchanged) ---
    def on_all_uploads_complete():
        status_row.visible = False
        upload_button.disabled = False
        current_files = state['files'][field_key]
        if current_files:
            handle_change_callback(field_key, current_files[0]['path'])
        update_file_list_display()
        validate_callback(field_key)
        page.update()

    def update_file_list_display():
        files = state.get('files', {}).get(field_key, [])
        if not files:
            file_list.controls = [ft.Text("No files uploaded", size=12, color=ft.Colors.GREY_500, italic=True)]
        else:
            file_list.controls = [
                ft.Container(
                    content=ft.Row([
                        ft.Icon(ft.Icons.INSERT_DRIVE_FILE, size=20, color=ft.Colors.BLUE_GREY),
                        ft.Column([
                            ft.Text(f['name'], size=14, weight=ft.FontWeight.BOLD, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS),
                            ft.Text(f"{f.get('size', 0):,} bytes", size=12, color=ft.Colors.GREY_600),
                        ], tight=True, spacing=2, expand=True),
                        ft.IconButton(icon=ft.Icons.CLOSE, on_click=lambda e, f=f: remove_file(f), tooltip="Remove file"),
                    ], alignment=ft.MainAxisAlignment.START, vertical_alignment=ft.CrossAxisAlignment.CENTER),
                    padding=ft.padding.symmetric(vertical=6, horizontal=10), border=ft.border.all(1, ft.Colors.GREY_300), border_radius=8,
                ) for f in files
            ]
        page.update()

    def remove_file(file_to_remove: Dict[str, Any]):
        files = state.get('files', {}).get(field_key, [])
        state['files'][field_key] = [f for f in files if f['id'] != file_to_remove['id']]
        remaining_files = state['files'][field_key]
        handle_change_callback(field_key, remaining_files[0]['path'] if remaining_files else '')
        update_file_list_display()
        validate_callback(field_key)

    # --- Final Layout ---
    container = ft.Column(
        controls=[
            ft.Text(field.get('label', ''), weight=ft.FontWeight.BOLD),
            ft.Row(controls=[upload_button]),
            status_row,
            file_list
        ], spacing=10
    )
    update_file_list_display()
    return container