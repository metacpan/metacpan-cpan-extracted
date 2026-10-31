# Bundled GLEW

Version: 2.3.1 (official release, 2026-01-24)

Upstream: https://github.com/nigels-com/glew

Source archive:
https://github.com/nigels-com/glew/releases/download/glew-2.3.1/glew-2.3.1.tgz

Archive SHA-256:
`b64790f94b926acd7e8f84c5d6000a86cb43967bd1e688b03089079799c9e889`

Only `src/glew.c`, `include/GL/*.h`, and `LICENSE.txt` are included.
The source and headers are already generated; no GLEW generator or separate
GLEW installation is needed. Retain LICENSE.txt when redistributing.

## Local change

The Unix GLEWAPI declaration in include/GL/glew.h supports
`TKZINC_PRIVATE_GLEW`. This marks GLEW functions and variables as hidden,
without hiding the imported system OpenGL functions. Unsupported Unix
compilers produce an explicit error rather than exposing the symbols.
All other upstream files are unchanged.

## Perl integration

Perl/ZincGlew.c compiles glew.c with GLEW_STATIC. Perl/Makefile.PL sets
TKZINC_PRIVATE_GLEW and includes these headers before system GLEW headers.
On Windows, MakeMaker's explicit .def export list exposes the Perl bootstrap
function, not the bundled GLEW symbols. No separate glew32.dll is installed
or loaded. The system OpenGL/GLU libraries are still required.

The Tcl/Tk build continues to use its existing external GLEW configuration.

## Updating

Use an official release archive, replace the files listed above, reapply
the small GLEWAPI change, and update the version, archive URL and checksum.
Verify the Perl build and check its dynamic exports for glew, wglew, glxew
and eglew symbols before releasing.
