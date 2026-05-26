## Architecture & Flow

The script operates in two distinct modes:

### 1. Batch Mode (Drag & Drop)
- **Trigger**: Triggered when a folder path is passed as the first argument (`$1`) to the script.
- **Behavior**:
  - Cleans the input path using `clean_path`.
  - Scans the directory for all assignments.
  - Processes **all** found assignments automatically without prompting the user.
  - Opens the target directory in Finder upon completion.

### 2. Interactive Mode (GUI)
- **Trigger**: Triggered when the script is run without any arguments.
- **Behavior**:
  - Prompts the user to select the `Submitted files` folder using a native macOS folder picker.
  - Scans the folder and presents a list of found assignments.
  - Prompts the user to select a single assignment to process.
  - Displays a macOS notification when processing starts.
  - Displays a native dialog upon completion, offering to open the target directory in Finder.

---

## Versioning & Merging Logic
When processing student submissions, the script handles versioning as follows:
1. **Base Copy**: Copies the base files from the student's assignment folder, excluding any folders matching `Version*` or `Versie*`.
2. **Version Merging**: Finds all version folders (e.g., `Version_1`, `Versie 2`), sorts them naturally using `sort -V` (version sort), and copies them sequentially over the base files. This ensures that newer versions overwrite older files while preserving any files that were not modified in the newer versions.
3. **ZIP Extraction**: Recursively searches the student's target directory for `.zip` files (case-insensitive), extracts them in-place, and deletes the `.zip` file.