# Repository guidelines

## Vendored Discount sources

Directories matching `discount-*` are pristine vendored copies of upstream
Discount releases. Do not modify files in these directories directly.

Do not apply local patches to bundled Discount releases. Prefer fixing issues
upstream and updating the bundled release after the fix is published. Until
then, document the upstream behavior and pass it through unchanged.
