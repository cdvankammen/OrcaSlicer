# Claude Code Configuration

This directory contains Claude Code settings for the OrcaSlicer workspace.

## Files

- **settings.json**: Workspace-level permissions and settings (checked into git)
- **settings.local.json**: Your personal overrides (NOT checked into git)

## Permission Strategy

This configuration enables maximum autonomy for Claude while maintaining safety:

### ✅ Auto-Approved Operations
- **Build commands**: cmake, ctest, make, ninja
- **Git operations**: status, diff, log, commit, push, pull
- **File operations**: ls, cd, cat, grep, find, mkdir, cp, mv
- **Development tools**: python, node, npm, pip, compiler commands
- **Web fetching**: All WebFetch operations

### ⚠️ Protected Files (Require Approval)
- Git configuration (`.git/*`, `.gitignore`)
- Lock files (`package-lock.json`, `yarn.lock`, `Cargo.lock`)
- IDE settings (`.vscode/settings.json`)

### 🚫 Blocked Operations (Always Denied)
- Destructive system commands (`rm -rf /`, `shutdown`, `reboot`)
- Disk formatting (`mkfs`, `dd`, `format`)
- System-wide deletions

## Mode: acceptEdits

Claude will automatically apply code edits without prompting, similar to GitHub Copilot. You'll see changes being made in real-time.

## Customization

To add your own permissions, edit `settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(*:your-custom-command*)"
    ]
  }
}
```

## For OrcaSlicer Development

This configuration is optimized for OrcaSlicer development:
- Build commands pre-approved (Windows, macOS, Linux)
- Test commands pre-approved
- Git workflow streamlined
- CMake operations permitted

See `CLAUDE.md` in the repository root for more development guidance.
