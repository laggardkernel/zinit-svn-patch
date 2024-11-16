#!/usr/bin/env zsh

if [[ -z "${ZINIT[GIT_PROCESS_SCRIPT]}" ]]; then
  if [[ -f "${ZINIT[BIN_DIR]}/share/git-process-output.zsh" ]]; then
    ZINIT[GIT_PROCESS_SCRIPT]="${ZINIT[BIN_DIR]}/share/git-process-output.zsh"
  else
    ZINIT[GIT_PROCESS_SCRIPT]="${ZINIT[BIN_DIR]}/git-process-output.zsh"
  fi
fi

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

# In version 0580db (2020-07-23), ZINIT_ICE was renamed to ICE.
# Since I'm using an older version of zinit, this code is written
# to be compatible with both versions, before and after the rename.
local -A ice
(( ${+ICE} )) && ice=("${(kv)ICE[@]}") || ice=("${(kv)ZINIT_ICE[@]}")

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
    command git pull --no-stat ${=ice[pullopts]:---ff-only} origin ${ice[ver]:-master} |& \
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
    command git clone --progress --no-checkout ${ice[cloneopts]} \
      --depth ${ice[depth]:-10} \
      "$git_url" "$directory" \
      --config transfer.fsckobjects=false \
      --config receive.fsckobjects=false \
      --config fetch.fsckobjects=false \
      --config submodule.recurse=false
    unfunction :zinit-git-clone
  }
  :zinit-git-clone |& { command "${ZINIT[GIT_PROCESS_SCRIPT]}" || cat; }
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
if (( ${ZINI_SVN_PATCH_STATUS:-1} )); then
(( ${+functions[.zinit-update-or-status-snippet]} )) || builtin source ${ZINIT[BIN_DIR]}"/zinit-autoload.zsh"
# FUNCTION: .zinit-update-or-status-snippet (patch) [[[
#
# Implements update or status operation for snippet given by URL.
#
# $1 - "status" or "update"
# $2 - snippet URL
.zinit-update-or-status-snippet() {
  local st="$1" URL="${2%/}" local_dir filename is_snippet
  local -A ice ice2

  (( ${+ICE} )) && ice=("${(kv)ICE[@]}") || ice=("${(kv)ZINIT_ICE[@]}")

  (( ${#ice[@]} > 0 )) && { ZINIT_SICE[$URL]=""; local nf="-nftid"; }
  .zinit-compute-ice "$URL" "pack$nf" \
    ice2 local_dir filename is_snippet || return 1

  integer retval

  if [[ "$st" = "status" ]]; then
    if (( ${+ice2[svn]} )); then
      builtin print -r -- "${ZINIT[col-info]}Status for ${${${local_dir:h}:t}##*--}/${local_dir:t}${ZINIT[col-rst]}"
      ( builtin cd -q "$local_dir"; command git status )
      # ( builtin cd -q "$local_dir"; command git log -1 --pretty="%h %s" && command ls -lh )
      # .zinit-mirror-using-svn "$URL" "-t" "$local_dir" || true
      retval=$?
      builtin print
    else
      builtin print -r -- "${ZINIT[col-info]}Status for ${${local_dir:h}##*--}/$filename${ZINIT[col-rst]}"
      ( builtin cd -q "$local_dir"; command ls -lth $filename )
      retval=$?
      builtin print
    fi
  else
    (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source ${ZINIT[BIN_DIR]}"/zinit-install.zsh"
    (( ${+ICE} )) && ICE=( "${(kv)ice2[@]}" )
    .zinit-update-snippet "${ice2[teleid]:-$URL}"
    retval=$?
  fi

  (( ${+ICE} )) && ICE=() || ZINIT_ICE=()
  if (( PUPDATE && ZINIT[annex-multi-flag:pull-active] > 0 )) {
    builtin print ${ZINIT[annex-multi-flag:pull-active]} >! $PUFILE.ind
  }
  return $retval
}
# ]]]
fi

# vim: ft=zsh sw=2 ts=2 et foldmarker=[[[,]]] foldmethod=marker
