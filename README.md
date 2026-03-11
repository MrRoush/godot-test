# GitHub Classroom for Godot

A simple Godot 4.5+ editor addon that lets students **pull** and **push** their projects to GitHub Classroom repositories — no command line or GitHub Desktop needed.

Everything happens through a small panel inside the Godot editor, making it ideal for introductory game-design courses where students are new to version control.

---

## Features

| Feature | Description |
|---------|-------------|
| **Pull** | Download the latest version of the project from GitHub with one click. |
| **Push** | Upload changes to GitHub with a short commit message. |
| **No Git required** | Uses the GitHub REST API directly — Git does not need to be installed. |
| **Simple UI** | One panel with only the controls students need. |
| **Secure** | The GitHub token is stored locally outside the project folder and is never committed. |

---

## Installation

### For Teachers — Setting Up the Template

1. Copy the `addons/github_classroom/` folder into your Godot project's `addons/` directory.
2. Open the project in Godot, go to **Project → Project Settings → Plugins** and enable **GitHub Classroom**.
3. Commit the project (including the addon) to your GitHub Classroom template repository.

### For Students — First-Time Setup

1. Accept the GitHub Classroom assignment. This creates your own repository.
2. Open the Godot project your teacher provided.
3. Look for the **GitHubClassroom** panel on the right side of the editor.
4. Enter three things:
   - **Repository URL** — the link to *your* repository (e.g. `https://github.com/classroom-org/assignment-yourname`).
   - **GitHub Token** — a Personal Access Token you create on GitHub (see below).
   - **Branch** — leave this as `main` unless your teacher says otherwise.
5. Click **Save Settings**.
6. Click **Pull** to download the starter code.

---

## Creating a GitHub Personal Access Token

Students need a token so the addon can talk to GitHub on their behalf.

1. Go to <https://github.com/settings/tokens?type=beta> (Fine-grained tokens).
2. Click **Generate new token**.
3. Give it a name, for example `Godot Classroom`.
4. Set the **Expiration** to match your course length (or choose *Custom*).
5. Under **Repository access**, select **Only select repositories** and pick your classroom repository.
6. Under **Permissions → Repository permissions**, set **Contents** to **Read and write**.
7. Click **Generate token** and **copy** the token immediately (you will not see it again).
8. Paste the token into the **GitHub Token** field in Godot.

> **Tip for teachers:** Walk students through this process once at the beginning of the course. The token only needs to be created once per repository.

---

## Daily Workflow

1. **Start of class** — Click **Pull** to make sure you have the latest version.
2. **Work on your project** — Add scenes, write scripts, create art, etc.
3. **End of class**:
   - Type a short commit message describing what you did (e.g. *"Added player movement"*).
   - Click **Push** to save your work to GitHub.

That's it! Your changes are now safely stored on GitHub.

---

## How It Works

The addon uses the [GitHub REST API](https://docs.github.com/en/rest) (specifically the Git Data API) to transfer files between the local Godot project and the remote GitHub repository.

- **Pull** downloads every file from the repository and writes it into the project folder.
- **Push** computes a local SHA-1 hash for each project file, compares it with the remote, uploads only the files that changed, and creates a new commit.

No local Git installation is needed at all.

### What Gets Synced

| Included | Excluded |
|----------|----------|
| All project files (scenes, scripts, assets, `project.godot`, etc.) | `.godot/` (editor cache) |
| `.gitignore`, `.gitattributes`, etc. | `.git/` (if present) |
| The addon itself (if included in the template) | OS junk files (`.DS_Store`, `Thumbs.db`) |

---

## Troubleshooting

| Message | What to Do |
|---------|------------|
| **Invalid repository URL** | Make sure the URL looks like `https://github.com/owner/repo`. |
| **HTTP 401: Bad credentials** | Your token is invalid or expired. Generate a new one. |
| **HTTP 403: …** | Your token does not have the required permissions. Make sure **Contents → Read and write** is enabled. |
| **HTTP 404: Not Found** | Double-check the repository URL and make sure your token has access to that repository. |
| **Connection failed** | Check your internet connection and try again. |
| **No changes to push** | Your local files already match what is on GitHub. |

---

## Project Structure

```
addons/
└── github_classroom/
    ├── plugin.cfg                  # Plugin metadata
    ├── plugin.gd                   # EditorPlugin entry point
    ├── github_api.gd               # GitHub REST API wrapper
    └── github_classroom_dock.gd    # Dock panel UI + pull/push logic
```

---

## Requirements

- **Godot 4.5** or later (tested with 4.5 and 4.6).
- A GitHub account with a Personal Access Token.
- An internet connection.

---

## License

This project is provided as-is for educational use. Feel free to modify and redistribute it for your classroom.