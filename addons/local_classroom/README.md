# Local Classroom Addon

## 1) What this addon does

`local_classroom` is a Godot editor addon that saves student projects directly to a local Windows network share (UNC or mapped drive). It does not use GitHub, Git, Python, or HTTP.

- Students can pull starter files from a shared `_template` folder.
- Students can save timestamped ZIP backups to their own server folder.
- Teachers can load student folders and pull the latest backup ZIP for grading.

---

## 2) Server folder setup

Create this structure on your file share:

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

---

## 3) How to create `students.cfg`

Create `students.cfg` at the server root using Godot INI format:

```ini
[students]
Alice = 1234
Bob = 5678
Charlie = 9012
```

Names are checked case-insensitively.

---

## 4) How to create/configure `classroom_config.cfg`

Edit `addons/local_classroom/classroom_config.cfg` in your template project:

```ini
[classroom]
server_path = \\SERVER\GodotClassroom
assignment_name = Assignment1
```

If values are set, those fields are pre-filled and read-only in the dock.

---

## 5) Student setup steps

1. Open the Godot project.
2. Enable **Local Classroom** in Project Settings → Plugins.
3. Enter **Your Name** and **PIN**.
4. Click **Save Settings**.
5. Click **⬇ Get Template (Pull)** once at the start of an assignment.

---

## 6) Teacher setup steps

1. Prepare the server folder layout and `students.cfg`.
2. Put starter files in `{server}\{assignment}\_template\`.
3. In Godot, switch role to **Teacher** (Show Advanced Options).
4. Click **Load Students** to browse student folders.
5. Select a student and click pull to load their latest ZIP backup.

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
2. Click **Load Students**.
3. Select a student from the tree.
4. Click **⬇ Get Template (Pull)** to load that student's latest backup.
5. Review/grade, then pull the next student.
