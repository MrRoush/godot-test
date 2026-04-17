# Local Classroom Addon

## 1) What this addon does

`local_classroom` is a Godot editor addon that saves student projects directly to a local Windows network share (UNC or mapped drive). It does not use GitHub, Git, Python, or HTTP.

- Students can pull starter files from a shared `_template` folder.
- Students can save timestamped ZIP backups to their own server folder.
- Teachers can load student folders and pull the latest backup ZIP for grading.

Both **UNC paths** (`\\SERVER\GodotClassroom`) and **mapped drives** (`Z:\GodotClassroom`) are supported as the server path.

---

## 2) Server folder setup

Create this structure on your file share. You can use a UNC path or a mapped network drive:

**UNC example:**

```text
\\SERVER\GodotClassroom\
├── students.cfg
├── Assignment1\
│   ├── _template\
│   │   └── (starter project files)
│   ├── Alice\
│   │   └── backup_2026-04-17_10-30-00.zip
│   └── Bob\
│       └── backup_2026-04-17_09-15-44.zip
└── Assignment2\
    └── ...
```

**Mapped-drive example (same structure, different root):**

```text
Z:\GodotClassroom\
├── students.cfg
├── Assignment1\
│   ├── _template\
│   │   └── ...
```

### Permissions best-practices

| Folder / file | Students | Teachers |
|---|---|---|
| `students.cfg` | Read-only | Full control |
| `_template\` | Read-only | Full control |
| `<StudentName>\` | Read/Write to **own** folder only | Full control on **all** student folders |

On a Windows file server you can enforce this with per-folder NTFS permissions or share-level permissions. A simple approach:

1. Give the **Students** group *Read* access to the share root.
2. For each student folder (e.g. `Alice\`), grant that student *Modify* access.
3. Give the **Teacher** account *Full Control* at the root so they can browse every student folder.

---

## 3) How to create `students.cfg`

Create `students.cfg` at the server root using Godot INI format. Include both a `[students]` section and a `[teacher]` section:

```ini
[teacher]
pin = t3ach3r_s3cret

[students]
Alice = 1234
Bob = 5678
Charlie = 9012
```

- **`[teacher]` section** — The `pin` value is required to access the Teacher role in the addon. This prevents students from switching to Teacher mode and viewing other students' folders.
- **`[students]` section** — Each key is a student name (matched case-insensitively) and its value is that student's PIN.

> ⚠️ **Format warning:** Both sections and all key-value pairs are required. The `[teacher]` and `[students]` section headers must be present, and each entry must follow `key = value` syntax. A missing section header is the most common cause of parse errors and will prevent login. The addon's custom parser will report a clear error message in the Status area rather than crashing.

> **Security note:** The teacher PIN is stored in plain text in `students.cfg`. Keep this file read-only for students at the OS / file-share level so they cannot open and read it. See the *Permissions best-practices* table above.

---

## 4) How to create/configure `classroom_config.cfg`

Edit `addons/local_classroom/classroom_config.cfg` in your template project:

```ini
[classroom]
server_path = \\SERVER\GodotClassroom
assignment_name = Assignment1
```

**Mapped-drive alternative:**

```ini
[classroom]
server_path = Z:\GodotClassroom
assignment_name = Assignment1
```

If `server_path` is set, that field is pre-filled and locked in the dock so students cannot change it.  If `assignment_name` is set, that field is also locked and the **Browse Assignments** button is hidden (the assignment is already chosen for the student).

> **Tip:** If you map the same drive letter on every lab machine (e.g. via a Group Policy login script), a mapped-drive path is often simpler for students to understand than a UNC path.

> ⚠️ **Format warning:** The `[classroom]` section header is required. A missing section header causes a ConfigFile parse error.  The addon skips loading the file if `classroom_config.cfg` does not exist, so it is safe to leave it empty or delete it on machines where you want students to enter the path manually.

---

## 5) Student setup steps

1. Open the Godot project.
2. Enable **Local Classroom** in Project Settings → Plugins.
3. Enter **Your Name** and **PIN**.
4. Click **📋 Browse Assignments** to see the list of available assignments on the server and select one.  *(This button is only shown when the assignment is not pre-configured by the teacher via `classroom_config.cfg`.)*
5. Click **Save Settings**.
6. Click **⬇ Get Template (Pull)** once at the start of an assignment.

---

## 6) Teacher setup steps

1. Prepare the server folder layout and `students.cfg` (including the `[teacher]` section with a `pin`).
2. Put starter files in `{server}\{assignment}\_template\`.
3. In Godot, switch role to **Teacher** (Show Advanced Options).
4. Enter the **Teacher PIN** that matches the `pin` value in `students.cfg`.
5. Click **Load Students** to browse student folders.
6. Select a student and click pull to load their latest ZIP backup.

> **Note:** The teacher PIN is verified against the server's `students.cfg` each session. If you change the PIN on the server, all teachers must use the new value.

---

## 7) Daily workflow for students

1. Pull template at the beginning (if needed).
2. Work normally in Godot.
3. Press save (`Ctrl+S`) to trigger auto-save if enabled.
4. Optionally click **⬆ Save to Server (Push)** manually at any time.
5. Click **🔒 Sign Out / Clear Credentials** on shared computers.

---

## 8) Daily workflow for teachers

1. Open the project and switch to **Teacher** role.
2. Enter the Teacher PIN.
3. Click **Load Students**.
4. Select a student from the tree.
5. Click **⬇ Get Template (Pull)** to load that student's latest backup.
6. Review/grade, then pull the next student.

---

## 9) Using a mapped network drive

If your school maps a drive letter (e.g. `Z:`) to the file server, you can use that letter in place of a UNC path everywhere:

| Setting | UNC path | Mapped drive |
|---|---|---|
| `classroom_config.cfg` → `server_path` | `\\SERVER\GodotClassroom` | `Z:\GodotClassroom` |
| Server-path field in dock | `\\SERVER\GodotClassroom` | `Z:\GodotClassroom` |

Both formats work identically. The addon normalizes slashes internally, so either forward slashes (`Z:/GodotClassroom`) or backslashes (`Z:\GodotClassroom`) are accepted.

### Common mapped-drive issues

| Symptom | Likely cause | Fix |
|---|---|---|
| "Server path is not reachable" | Drive letter not mapped for the current user session | Log out and back in, or run `net use Z: \\SERVER\Share` in a command prompt |
| "Server path is not reachable" with a UNC path | Server is unreachable or the share name is misspelled | Verify in File Explorer that `\\SERVER\GodotClassroom` is accessible |
| Works in File Explorer but not Godot | Godot is running under a different user / elevated context | Run Godot under the same user account that has the drive mapped |

---

## 10) Troubleshooting

| Problem | Possible solution |
|---|---|
| "Server path is not reachable or does not exist" | Double-check the server path in the dock or `classroom_config.cfg`. Make sure the share is accessible from File Explorer first. Try both UNC and mapped-drive formats. |
| "students.cfg was not found" | Create `students.cfg` at the root of the server path with `[teacher]` and `[students]` sections. |
| "Could not read students.cfg — check the file format" | Open `students.cfg` in a text editor and confirm it has the correct INI format: the `[teacher]` and `[students]` section headers must appear before any key-value entries. |
| "students.cfg is missing a [teacher] section" | Add a `[teacher]` section with a `pin` value to `students.cfg`. |
| "Incorrect teacher PIN" | Make sure the PIN in the dock matches the value under `[teacher]` → `pin` in `students.cfg`. |
| No assignments listed in Browse Assignments | Confirm that each assignment folder contains a `_template` subfolder. The Browse Assignments button only lists folders that have a `_template` subdirectory. |
| ZIP creation fails | Check that the student's folder exists on the server and the student's OS account has write permission. |
| Template pull has errors | Verify the `_template` folder exists under the assignment folder and that the student has read access. |
| Auto-save not triggering | Check the Auto-Save setting (Show Advanced Options). "Manual Only" disables auto-save. |
