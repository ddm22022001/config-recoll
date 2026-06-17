#!/bin/bash
# list.sh
#
# Defines the lists of paths managed by init.sh's copy-list/move-list/link-list
# functions. Paths are relative to the user's home directory.
#
# Paths in the lists include leading dots for hidden files and directories.
# During deployment, init.sh strips these leading dots (via strip-lead-dot function)
# so that:
#   - $HOME/.local/share/recoll-webui/views/result.tpl
#   - becomes $DEPLOY-DIR/local/share/recoll-webui/views/result.tpl
#
# This allows config files to be managed without the dot prefix in the deploy dir,
# while keeping them properly linked back to their hidden locations in $HOME.
#
# Meant to be sourced by init.sh, not executed directly.

# recoll-files-list: individual files
# Paths include leading dots; init.sh will strip them for deploy directory storage
recoll-files-list() {
    cat <<'EOF'
.local/share/recoll-webui/views/result.tpl
.recoll/mimeview
.recoll/recoll.conf
.recoll/mimeconf
.recoll/mimemap
EOF
}

# recoll-folders-list: folders within the user dir
# Paths include leading dots; init.sh will strip them for deploy directory storage
recoll-folders-list() {
    cat <<'EOF'
EOF
}
