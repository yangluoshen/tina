# Separate upstream skills from private policy

Vendor the required Matt Pocock skills unchanged and keep personal behavior in `tina-*` wrappers plus the `tina` schema. This costs a small amount of duplication, but keeps installations reproducible and allows upstream snapshots or OpenSpec-generated skills to be upgraded without merging private edits into managed files.
