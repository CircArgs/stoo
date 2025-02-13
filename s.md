### **Optimizing Remote and Local Code for Efficiency**

Your current implementation works, but we can **optimize the remote server and local client to make sync operations more efficient.** Here’s how:

---

## **1. Issues with the Current Setup**
1. **Redundant Deletes and Uploads**  
   - When renaming a folder, every file is uploaded first and then deleted remotely. However, this results in:
     - Files being deleted and re-uploaded individually instead of recognizing a folder move.
     - More network traffic and latency.

2. **No Support for Folder Rename in Remote API**  
   - The remote FastAPI server only supports individual file uploads (`/update-file/`) and deletions (`/delete-file/`).
   - It does **not** have an endpoint to **rename/move a folder directly**.

3. **Local Client Doesn't Batch Requests**  
   - The client currently processes each file separately. It could be optimized to **batch requests** to the server, reducing the number of HTTP requests.

---

## **2. Changes for the Remote Server (FastAPI)**
### **Add an Endpoint for Folder Rename**
Modify `sync.py` on the remote server to **handle folder renames directly**.

#### **Updated Remote API (FastAPI)**
```python
@app.post("/rename-folder/")
async def rename_folder(old_path: str = Form(...), new_path: str = Form(...)):
    """Move or rename a folder."""
    old_folder = os.path.join(BASE_DIR, old_path)
    new_folder = os.path.join(BASE_DIR, new_path)

    if not os.path.exists(old_folder):
        raise HTTPException(status_code=404, detail="Folder not found.")

    # Ensure the new directory does not already exist
    if os.path.exists(new_folder):
        raise HTTPException(status_code=400, detail="Target folder already exists.")

    # Rename the directory
    os.rename(old_folder, new_folder)
    return JSONResponse(content={"status": "success", "old_path": old_path, "new_path": new_path})
```

### **Why This is Better**
- This lets the client **directly rename/move folders** instead of deleting/re-uploading every file.
- Saves **time and bandwidth**.
- Prevents **data loss** if a failure happens mid-sync.

---

## **3. Changes for the Local Client**
Now that the remote server supports folder renames, modify `on_moved` in the local sync client.

#### **Updated `on_moved` in Local Client**
```python
def on_moved(self, event):
    """Handles file or folder renaming and movement efficiently."""
    if event.is_directory:
        print(f"Folder renamed or moved: {event.src_path} -> {event.dest_path}")

        # Send a single request to rename/move the folder remotely
        response = requests.post(
            f"{self.server_url}/rename-folder/",
            data={
                "old_path": os.path.relpath(event.src_path, self.local_dir),
                "new_path": os.path.relpath(event.dest_path, self.local_dir),
            },
        )

        if response.status_code != 200:
            raise Exception(f"Failed to rename folder {event.src_path} -> {event.dest_path}")

        print(f"Renamed folder remotely: {event.src_path} -> {event.dest_path}")

    else:
        print(f"File renamed or moved: {event.src_path} -> {event.dest_path}")

        # Upload first, then delete old file
        self.upload_file(event.dest_path)
        self.delete_file(event.src_path)
```

### **Why This is Better**
- If the event is a **folder rename**, it **sends just one request** instead of processing each file individually.
- If it’s a **single file rename**, it still **uploads first, then deletes** to avoid file loss.

---

## **4. Additional Optimizations**
### **Batch File Uploads**
Instead of uploading files **one-by-one**, modify the API to support batch uploads. This reduces HTTP overhead.

#### **Modify Remote API to Support Batch Upload**
```python
@app.post("/batch-upload/")
async def batch_upload(files: list[UploadFile] = Form(...), filepaths: list[str] = Form(...)):
    """Receive multiple files and save them in one batch."""
    if not files or not filepaths or len(files) != len(filepaths):
        raise HTTPException(status_code=400, detail="Invalid batch request.")

    for file, filepath in zip(files, filepaths):
        file_path = os.path.join(BASE_DIR, filepath)
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

    return JSONResponse(content={"status": "success", "file_count": len(files)})
```

#### **Modify Local Client to Use Batch Uploads**
```python
def batch_upload(self, file_paths):
    """Batch upload multiple files at once to reduce HTTP requests."""
    files = [("files", open(file_path, "rb")) for file_path in file_paths]
    filepaths = [("filepaths", os.path.relpath(file_path, self.local_dir)) for file_path in file_paths]

    response = requests.post(f"{self.server_url}/batch-upload/", files=files, data=filepaths)

    for file in files:
        file[1].close()  # Close file handlers after upload

    if response.status_code != 200:
        raise Exception(f"Batch upload failed for {len(file_paths)} files.")

    print(f"Batch uploaded {len(file_paths)} files.")
```

#### **Where to Use Batch Uploads**
Modify `on_moved` to upload files **in a batch**:
```python
def on_moved(self, event):
    """Handles file or folder renaming and movement efficiently."""
    if event.is_directory:
        print(f"Folder renamed or moved: {event.src_path} -> {event.dest_path}")

        # Rename folder remotely
        response = requests.post(
            f"{self.server_url}/rename-folder/",
            data={
                "old_path": os.path.relpath(event.src_path, self.local_dir),
                "new_path": os.path.relpath(event.dest_path, self.local_dir),
            },
        )

        if response.status_code != 200:
            raise Exception(f"Failed to rename folder {event.src_path} -> {event.dest_path}")

        print(f"Renamed folder remotely: {event.src_path} -> {event.dest_path}")

    else:
        print(f"File renamed or moved: {event.src_path} -> {event.dest_path}")

        # Batch upload before deleting old ones
        new_files = [event.dest_path]
        old_files = [event.src_path]

        self.batch_upload(new_files)  # Upload new files in a batch
        for old_file in old_files:
            self.delete_file(old_file)  # Delete old files one by one
```

---

## **5. Summary of Changes**
| Change | Why? |
|--------|------|
| **Added `/rename-folder/` API on remote** | Enables direct folder renames instead of deleting/re-uploading files. |
| **Updated `on_moved` to use `/rename-folder/`** | Reduces unnecessary operations when a folder is moved. |
| **Added `/batch-upload/` API on remote** | Allows multiple files to be uploaded in one request. |
| **Updated client to use `batch_upload()`** | Reduces the number of HTTP requests, improving speed. |

---

## **Final Benefits**
✔ **Less network traffic**  
✔ **Faster folder renames**  
✔ **More efficient file syncing**  
✔ **Lower risk of data loss**  

Would you like me to refine logging/debugging for better tracking during sync?
