# zinit-svn-patch

This plugin provide patches for

- `.zinit-mirror-using-svn()` (for downloading and updating subfolders)
  redirects `svn` operations to `git` sparse-checkout.
- `.zinit-update-or-status-snippet` fixs `zinit status snippet-name`.

These patches restore functionality for `zinit ice svn`.

```sh
zinit ice svn
zinit snippet OMZ::plugins/fancy-ctrl-z
```

NOTE:

- `zinit self-update` triggers a re`source` of
  `$ZINIT[BIN_DIR]/zinit*.zsh` files, which reverts pathces applied here.
- `zinit status`, namedly `zinit status --all`, triggers a `self-update` before
  checking all plugins. So the same revert occurs, and `zinit status` for
  all plugins will not work as expected.
