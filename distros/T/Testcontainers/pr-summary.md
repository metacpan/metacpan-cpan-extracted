# PR: Add Acknowledgments section to README

## Summary

Add an Acknowledgments section to `README.md` crediting the vendored [WWW::Docker](https://github.com/Getty/p5-www-docker) library and its author [Torsten Raudssus](https://github.com/getty). Also cleans up the intro paragraph by removing an inline note about WWW::Docker being unmaintained (that detail is better suited to the acknowledgments).

## Changes

### Modified files

| File | Description |
|------|-------------|
| `README.md` | Added `## Acknowledgments` section at the end; simplified the intro paragraph to remove the inline WWW::Docker maintenance note |

## Diff

```diff
 Perl 5 implementation of Testcontainers, inspired by the
-Go reference implementation. Incrorporates the work from
-WWW::Docker as the Docker client, as it is mot maintained.
+Go reference implementation.

+## Acknowledgments
+
+This project includes code derived from WWW::Docker by Torsten Raudssus,
+licensed under Perl license.
```
