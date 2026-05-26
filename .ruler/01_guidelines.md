## Coding Guidelines & Best Practices

When modifying or extending the codebase, adhere to the following rules:

### 1. Shell Scripting (Zsh)
- **Zsh Compatibility**: Always use `#!/bin/zsh` as the shebang. Do not write Bash-specific code that is incompatible with Zsh.
- **Quoting**: Always double-quote variables (e.g., `"$VARIABLE"`) to prevent word splitting and globbing issues, especially since student names and assignment names often contain spaces.
- **Error Handling**: Check the exit status of critical commands (like `unzip` or `rsync`). Use native AppleScript alerts (`gui_alert`) to report errors to the user.
- **Path Cleaning**: Use the `clean_path` function to sanitize input paths, resolving `~` to `$HOME` and removing backslashes, quotes, and leading/trailing spaces.

### 2. macOS GUI & AppleScript (`osascript`)
- **Non-blocking UI**: Ensure AppleScript dialogs activate properly by using `tell application "System Events" to activate` where appropriate.
- **User Experience**: Keep dialog prompts clear and in Dutch (as the target audience is Dutch-speaking educators).
- **Graceful Exit**: If a user cancels a dialog (e.g., `choose folder` or `choose from list`), handle the empty return value or "false" string gracefully and exit with `0` without throwing errors.

### 3. File Operations & Performance
- **Rsync over Cp**: Use `rsync -a` with appropriate `--exclude` flags instead of `cp -r` to ensure robust copying, preservation of metadata, and easy filtering of unwanted directories.
- **Exclusions**: Always exclude `node_modules`, `.git`, `.DS_Store`, and `__MACOSX` from student submissions to keep the output clean and save disk space.
- **ZIP Extraction**: Use `find ... -print0 | while IFS= read -r -d '' ZIPFILE` to safely handle ZIP files with spaces in their names. Extract them in-place and delete the original ZIP file upon successful extraction.