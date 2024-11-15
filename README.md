# zinit-svn-patch

This script patches/overrides `.zinit-mirror-using-svn()` (subfolders download,
update) to redirect `svn` operation to `git` sparse-checkout.

It makes `zinit ice svn` work again.

```sh
zinit ice svn
zinit snippet OMZ::plugins/fancy-ctrl-z
```

NOTE: `zinit status` for subfolder snippets is still broken, not being patched
yet.
