#!/bin/bash
# init.sh
#
# Provides copy-list / move-list / deploy-list / list-list / del-home-files
# / del-deploy-files commands operating on the paths returned by
# recoll-files-list and recoll-folders-list (defined in list.sh).
#
# Deploy directory behavior: leading dots are stripped from paths.
# This means:
#   - $HOME/.local/share/recoll-webui/views/result.tpl is read from
#   - Deploy dir stores it as ./local/share/recoll-webui/views/result.tpl
#   - deploy-list symlinks: $HOME/.local/... -> $DEPLOY-DIR/local/...
#
# Wherever a file (not a folder) is printed, the output includes its
# modification date, size, and hash (md5).
#
# Usage:
#   ./init.sh copy-list
#   ./init.sh move-list
#   ./init.sh deploy-list
#   ./init.sh list-list
#   ./init.sh del-home-files
#   ./init.sh del-deploy-files
#
# copy-list       : copies each path from $HOME/<path> to ./<path-stripped>
# move-list       : moves each path from $HOME/<path> to ./<path-stripped>
# deploy-list     : validates that none of the paths already exist under
#                   $HOME (as a regular file/dir or as a symlink, even a
#                   broken one). If any do, an error is printed and the
#                   script exits. Otherwise, a symlink is created for each
#                   path: source ./<path-stripped>, destination $HOME/<path>.
# list-list       : reports, for every path, its state under $HOME
#                   (~/<path> for a real file, ~/<path> -> target for a
#                   symlink) and its state under the deploy dir (./<path-stripped>).
#                   If a deploy dir entry is itself a symlink, an error is
#                   printed and the script exits.
# del-home-files  : deletes each $HOME/<path>; unlinks it if it's a
#                   symlink, removes it if it's a real file/dir.
# del-deploy-files: deletes each real file/dir at ./<path-stripped> in the deploy
#                   dir.

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DEPLOY_DIR/list.sh"

HASH_CMD=md5sum

all-list-entries() {
    recoll-files-list
    recoll-folders-list
}

# strip-lead-dot <path>
# Strips the leading dot from a path (if present).
# Examples:
#   .local/share/... -> local/share/...
#   .recoll/... -> recoll/...
#   regular/path -> regular/path (unchanged)
# 
# Handles both:
#   .local -> local  (leading dot removed)
#   ./local -> local (leading ./ removed)
strip-lead-dot() {
    local path="$1"
    if [[ "$path" == ./* ]]; then
        # Remove ./ prefix (two characters)
        echo "${path:2}"
    elif [[ "$path" == .* ]]; then
        # Remove . prefix (one character)
        echo "${path:1}"
    else
        # No leading dot, return unchanged
        echo "$path"
    fi
}

# file-meta <path>
# Prints "date=... size=... md5=..." for a regular file (following
# symlinks). Prints nothing and fails if <path> isn't a regular file.
file-meta() {
    local path="$1"
    [ -f "$path" ] || return 1
    local d s h
    d="$(date -r "$path" '+%Y-%m-%d %H:%M:%S')"
    s="$(stat -c%s "$path")"
    h="$("$HASH_CMD" "$path" | awk '{print $1}')"
    echo "date=$d size=$s md5=$h"
}

copy-list() {
    recoll-files-list | while IFS= read -r f; do
        [ -z "$f" ] && continue
        local f_deploy
        f_deploy="$(strip-lead-dot "$f")"
        mkdir -p "./$(dirname "$f_deploy")"
        if cp -p "$HOME/$f" "./$f_deploy"; then
            echo "'$HOME/$f' -> './$f_deploy'  $(file-meta "./$f_deploy")"
        fi
    done

    recoll-folders-list | while IFS= read -r d; do
        [ -z "$d" ] && continue
        local d_deploy
        d_deploy="$(strip-lead-dot "$d")"
        mkdir -p "./$(dirname "$d_deploy")"
        cp -rv "$HOME/$d" "./$d_deploy"
    done
}

move-list() {
    recoll-files-list | while IFS= read -r f; do
        [ -z "$f" ] && continue
        local f_deploy
        f_deploy="$(strip-lead-dot "$f")"
        mkdir -p "./$(dirname "$f_deploy")"
        if [ -f "$HOME/$f" ]; then
            meta="$(file-meta "$HOME/$f")"
            mv "$HOME/$f" "./$f_deploy" && echo "'$HOME/$f' -> './$f_deploy'  $meta"
        fi
    done

    recoll-folders-list | while IFS= read -r d; do
        [ -z "$d" ] && continue
        local d_deploy
        d_deploy="$(strip-lead-dot "$d")"
        mkdir -p "./$(dirname "$d_deploy")"
        mv -v "$HOME/$d" "./$d_deploy"
    done
}

deploy-list() {
    local entry

    # Validate: none of the listed paths may already exist under $HOME,
    # whether as a regular file/dir or as a symlink (even a broken one).
    while IFS= read -r entry; do
        [ -z "$entry" ] && continue
        if [ -e "$HOME/$entry" ] || [ -L "$HOME/$entry" ]; then
            echo "Error: $HOME/$entry already exists, aborting deploy-list" >&2
            exit 1
        fi
    done < <(all-list-entries)

    # Deploy: symlink each path from ./<entry-stripped> into $HOME/<entry>
    recoll-files-list | while IFS= read -r f; do
        [ -z "$f" ] && continue
        local f_deploy
        f_deploy="$(strip-lead-dot "$f")"
        mkdir -p "$HOME/$(dirname "$f")"
        meta="$(file-meta "./$f_deploy")"
        ln -s "$DEPLOY_DIR/$f_deploy" "$HOME/$f" && echo "'$HOME/$f' -> '$DEPLOY_DIR/$f_deploy'  $meta"
    done

    recoll-folders-list | while IFS= read -r d; do
        [ -z "$d" ] && continue
        local d_deploy
        d_deploy="$(strip-lead-dot "$d")"
        mkdir -p "$HOME/$(dirname "$d")"
        ln -sv "$DEPLOY_DIR/$d_deploy" "$HOME/$d"
    done
}

list-list() {
    echo "Home directory (\$HOME):"
    recoll-files-list | while IFS= read -r f; do
        [ -z "$f" ] && continue
        if [ -L "$HOME/$f" ]; then
            meta="$(file-meta "$HOME/$f")"
            echo "~/$f -> $(readlink "$HOME/$f")  ${meta:-(broken link)}"
        elif [ -e "$HOME/$f" ]; then
            echo "~/$f  $(file-meta "$HOME/$f")"
        else
            echo "~/$f (missing)"
        fi
    done
    recoll-folders-list | while IFS= read -r d; do
        [ -z "$d" ] && continue
        if [ -L "$HOME/$d" ]; then
            echo "~/$d -> $(readlink "$HOME/$d")"
        elif [ -e "$HOME/$d" ]; then
            echo "~/$d"
        else
            echo "~/$d (missing)"
        fi
    done

    echo
    echo "Deploy directory (.):"
    recoll-files-list | while IFS= read -r f; do
        [ -z "$f" ] && continue
        local f_deploy
        f_deploy="$(strip-lead-dot "$f")"
        if [ -L "./$f_deploy" ]; then
            echo "Error: ./$f_deploy is a link, deploy dir is expected to hold real files" >&2
            exit 1
        elif [ -e "./$f_deploy" ]; then
            echo "./$f_deploy  $(file-meta "./$f_deploy")"
        else
            echo "./$f_deploy (missing)"
        fi
    done
    recoll-folders-list | while IFS= read -r d; do
        [ -z "$d" ] && continue
        local d_deploy
        d_deploy="$(strip-lead-dot "$d")"
        if [ -L "./$d_deploy" ]; then
            echo "Error: ./$d_deploy is a link, deploy dir is expected to hold real files" >&2
            exit 1
        elif [ -e "./$d_deploy" ]; then
            echo "./$d_deploy"
        else
            echo "./$d_deploy (missing)"
        fi
    done
}

del-home-files() {
    recoll-files-list | while IFS= read -r f; do
        [ -z "$f" ] && continue
        path="$HOME/$f"
        if [ -L "$path" ]; then
            meta="$(file-meta "$path")"
            unlink "$path" && echo "unlinked '$path'  ${meta:-(broken link)}"
        elif [ -e "$path" ]; then
            meta="$(file-meta "$path")"
            rm -rf "$path" && echo "removed '$path'  $meta"
        fi
    done

    recoll-folders-list | while IFS= read -r d; do
        [ -z "$d" ] && continue
        path="$HOME/$d"
        if [ -L "$path" ]; then
            unlink "$path" && echo "unlinked '$path'"
        elif [ -e "$path" ]; then
            rm -rf "$path" && echo "removed '$path'"
        fi
    done
}

del-deploy-files() {
    recoll-files-list | while IFS= read -r f; do
        [ -z "$f" ] && continue
        local f_deploy
        f_deploy="$(strip-lead-dot "$f")"
        path="./$f_deploy"
        if [ -e "$path" ]; then
            meta="$(file-meta "$path")"
            rm -rf "$path" && echo "removed '$path'  $meta"
        fi
    done

    recoll-folders-list | while IFS= read -r d; do
        [ -z "$d" ] && continue
        local d_deploy
        d_deploy="$(strip-lead-dot "$d")"
        path="./$d_deploy"
        if [ -e "$path" ]; then
            rm -rf "$path" && echo "removed '$path'"
        fi
    done
}

# Allow direct invocation, e.g. ./init.sh deploy-list
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cmd="$1"
    case "$cmd" in
        copy-list|move-list|deploy-list|list-list|del-home-files|del-deploy-files)
            "$cmd"
            ;;
        *)
            echo "Usage: $0 {copy-list|move-list|deploy-list|list-list|del-home-files|del-deploy-files}" >&2
            exit 1
            ;;
    esac
fi
