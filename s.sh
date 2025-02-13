def on_moved(self, event):
    """Handles file or folder renaming and movement"""
    if event.is_directory:
        print(f"Folder renamed or moved: {event.src_path} -> {event.dest_path}")
        # Walk through the renamed/moved folder and upload all files first
        for root, _, files in os.walk(event.dest_path):
            for file in files:
                full_path = os.path.join(root, file)
                self.upload_file(full_path)
        
        # Now walk through the old folder path and delete files remotely
        for root, _, files in os.walk(event.src_path):
            for file in files:
                full_path = os.path.join(root, file)
                self.delete_file(full_path)

    else:
        print(f"File renamed or moved: {event.src_path} -> {event.dest_path}")
        # Upload the new file first
        self.upload_file(event.dest_path)
        # Then delete the old file
        self.delete_file(event.src_path)
