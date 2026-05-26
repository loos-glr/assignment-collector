# GLR Assignment Collector - Agent Instructions

Welcome! You are an expert software engineer and AI agent assisting in the development of the **GLR Assignment Collector**. This project is a macOS-specific automation tool designed to streamline the process of collecting, versioning, and structuring student assignments from Microsoft Teams / OneDrive.

## Project Overview
The **GLR Assignment Collector** is a lightweight, native macOS utility written in Zsh. It automates the tedious task of downloading and organizing student submissions.

### Core Objectives
1. **Automate Collection**: Scan a OneDrive/Teams `Submitted files` directory.
2. **Intelligent Versioning**: Automatically detect version folders (e.g., `Version_1`, `Versie 2`) and merge them so that only the latest files are kept.
3. **Bulletproof Extraction**: Automatically extract student ZIP files while handling spaces and special characters safely.
4. **Clean Output**: Filter out unnecessary files/folders like `node_modules`, `.git`, `.DS_Store`, and `__MACOSX`.
5. **Native macOS UX**: Provide a simple GUI using AppleScript (`osascript`) for folder selection, assignment selection, and notifications.

---

## Tech Stack & Environment
- **Operating System**: macOS (specifically tested on macOS Sequoia and later).
- **Shell**: `/bin/zsh` (Zsh-specific features like parameter expansion and arrays are used).
- **GUI Layer**: AppleScript via `osascript` (dialogs, lists, alerts, and notifications).
- **File Operations**: `rsync` (for robust copying and filtering), `find`, `unzip`.