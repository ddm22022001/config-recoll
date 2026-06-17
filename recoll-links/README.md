# recoll-links v0.8

Bash scripts that manage recoll config files for a fedora44-plasma user,
between `$HOME` and a local deploy dir, with symlink deployment.

## Changes in v0.8

**Strip Lead Dot for Deploy Directory**: Leading dots are now stripped from paths
when storing files in the deploy directory. This means:

- **Home**: Files remain at their original locations with dots (e.g., `~/.local/share/recoll-webui/views/result.tpl`)
- **Deploy Dir**: Files are stored without the leading dot (e.g., `./local/share/recoll-webui/views/result.tpl`)
- **Symlinks**: Created from `$HOME/.local/share/...` pointing to `$DEPLOY-DIR/local/share/...`

This convention makes the deploy directory structure cleaner and easier to manage, while maintaining proper symlinks back to hidden configuration locations.

## Files

- `list.sh` — defines the path lists, sourced by `init.sh`.
- `init.sh` — provides the commands below.

## Lists (list.sh)

- `recoll-files-list` — files:
  - `.local/share/recoll-webui/views/result.tpl`
  - `.recoll/mimeview`
  - `.recoll/recoll.conf`
  - `.recoll/mimeconf`
  - `.recoll/mimemap`
- `recoll-folders-list` — folders within the user dir (currently empty).

## init.sh commands

```
./init.sh copy-list
./init.sh move-list
./init.sh deploy-list
./init.sh list-list
./init.sh del-home-files
./init.sh del-deploy-files
```

Run from the directory you want to use as the deploy dir. Whenever a file
(not a folder) is printed, the output includes its date, size, and md5
hash.

- **copy-list** — copy `$HOME/<path>` to `./<path-stripped>`. The leading dot
  is removed from the deploy directory path.
- **move-list** — move `$HOME/<path>` to `./<path-stripped>`. The leading dot
  is removed from the deploy directory path.
- **deploy-list** — symlink `./<path-stripped>` into `$HOME/<path>`. Creates
  absolute symlinks from `$HOME/<path>` to the deploy directory at
  `$DEPLOY-DIR/<path-stripped>`. Aborts if any `$HOME/<path>` already exists
  (file or symlink).
- **list-list** — show each path's state in `$HOME` (real / link / missing)
  and in the deploy dir (real / missing, with leading dot stripped). Aborts if
  a deploy dir entry is itself a link.
- **del-home-files** — delete each `$HOME/<path>`: unlink if it's a
  symlink, remove if it's a real file/dir.
- **del-deploy-files** — delete each real file/dir at `./<path-stripped>` in the deploy
  dir.

## Path Stripping Behavior

The `strip-lead-dot` function converts paths as follows:

```
.local/share/... → local/share/...
.recoll/... → recoll/...
regular/path → regular/path (unchanged if no leading dot)
```

This applies consistently across all commands:
- Files are read from `$HOME/.local/...` and stored in `$DEPLOY-DIR/local/...`
- Files are read from `$HOME/.recoll/...` and stored in `$DEPLOY-DIR/recoll/...`
- Symlinks point from `$HOME/<original-path>` to `$DEPLOY-DIR/<stripped-path>`

## Example Workflow

1. Start with config files in `$HOME`:
   ```
   ~/.local/share/recoll-webui/views/result.tpl
   ~/.recoll/recoll.conf
   ```

2. Copy to deploy directory (strips leading dots):
   ```
   ./init.sh copy-list
   # Creates:
   #   ./local/share/recoll-webui/views/result.tpl
   #   ./recoll/recoll.conf
   ```

3. Deploy symlinks back to $HOME:
   ```
   ./init.sh deploy-list
   # Creates symlinks:
   #   ~/.local/share/recoll-webui/views/result.tpl → $DEPLOY-DIR/local/share/recoll-webui/views/result.tpl
   #   ~/.recoll/recoll.conf → $DEPLOY-DIR/recoll/recoll.conf
   ```

## not implemented
- folders.sh — folders-clone-list is a list of git repos to clone into ../../
