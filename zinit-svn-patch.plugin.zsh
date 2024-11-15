#!/usr/bin/env zsh

(( ${+functions[.zinit-mirror-using-svn]} )) || builtin source ${ZINIT[BIN_DIR]}"/zinit-install.zsh"
# FUNCTION: .zinit-mirror-using-svn (patched) [[[
# Used to clone subdirectories from Github. If in update mode
# (see $2), then invokes `git pull', in normal mode invokes
# `git clone' and `sparse-checkout'. In test mode only
# compares remote and local revision and outputs true if update
# is needed.
#
# $1 - URL
# $2 - mode, "" - normal, "-u" - update, "-t" - test
# $3 - subdirectory (not path) with working copy, needed for -t and -u
.zinit-mirror-using-svn() {
setopt localoptions extendedglob warncreateglobal
local url="$1" update="$2" directory="$3" git_url="${url%%/trunk*}" subfolder="${url#*/trunk/}"

if [[ "$update" = "-t" ]]; then
  # from .zinit-self-update(), .zinit-update-or-status()
  (
    () { setopt localoptions noautopushd; builtin cd -q "$directory"; }
    # TODO(lk): is it possible to check only change under r subfolder?
    local -a lines
    command git fetch --quiet && \
    lines=( ${(f)"$(command git --no-pager log --color --date=short --pretty=format:'%Cgreen%cd %h %Creset%s%n' ..origin/HEAD)"} )
    (( ${#lines} > 0 )) && return 0
    return 1
  )
  return $?
fi

if [[ "$update" = "-u" && -d "$directory" && -d "$directory/.git" ]]; then
  # from .zinit-update-or-status()
  (
    () { setopt localoptions noautopushd; builtin cd -q "$directory"; }
    command git reset --hard HEAD && command git clean -df && \
    command git pull --no-stat ${=ZINIT_ICE[pullopts]:---ff-only} origin ${ZINIT_ICE[ver]:-master} |& \
    command egrep -v '(FETCH_HEAD|up to date\.|From.*://)' && \
    command mv "$subfolder"/* . 2>/dev/null && \
    command rm -rf "${subfolder%%/*}"
    return $?
  )
else
  if [[ -z $git_url || -z $subfolder ]]; then
    +zinit-message "{error}[snippet]: Unsupported url: $url"
    return 1
  else
    +zinit-message "repo: $git_url, subfolder: $subfolder"
  fi
  # from .zinit-setup-plugin-dir()
  :zinit-git-clone() {
    command git clone --progress --no-checkout ${ZINIT_ICE[cloneopts]} \
      --depth ${ZINIT_ICE[depth]:-10} \
      "$git_url" "$directory" \
      --config transfer.fsckobjects=false \
      --config receive.fsckobjects=false \
      --config fetch.fsckobjects=false \
      --config submodule.recurse=false
    unfunction :zinit-git-clone
  }
  :zinit-git-clone |& { command ${ZINIT[BIN_DIR]}/git-process-output.zsh || cat; }
  (( pipestatus[1] )) && return ${pipestatus[1]}
  (
    () { setopt localoptions noautopushd; builtin cd -q "$directory"; }
    command git sparse-checkout set --no-cone "$subfolder" && \
    command git checkout && \
    command mv "$subfolder"/* . 2>/dev/null && \
    command rm -rf "${subfolder%%/*}"
    return $?
  )
fi
return $?
}
# ]]]

# TODO(lk): patch .zinit-update-or-status-snippet(), fix zinit status?

# vim: set expandtab filetype=zsh shiftwidth=2 softtabstop=2 tabstop=2:
