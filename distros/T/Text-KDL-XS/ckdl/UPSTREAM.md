# Vendored ckdl

This directory holds an unmodified copy of the C library
[ckdl](https://github.com/tjol/ckdl) by Thomas Jollans. It is compiled
into Text::KDL::XS directly by Makefile.PL, so no system library and no
Alien module is needed. ckdl is MIT-licensed; see COPYING in this
directory.

Upstream commit: c9c33fe64446287215e80705545139d92a48f829 (2026-03-06)

Only the parts the XS layer needs are vendored: include/kdl/ (the
public headers) and src/ (the library sources and their private
headers). The CMake build, the C++ and Python bindings, the command
line tools and the upstream test suite are left out.

## Updating

1. Pick the upstream commit and download its tarball:

   ```sh
   COMMIT=<sha>
   curl -L -o ckdl.tar.gz https://github.com/tjol/ckdl/archive/$COMMIT.tar.gz
   tar xzf ckdl.tar.gz
   ```

2. Replace the vendored files and the license:

   ```sh
   rm ckdl/include/kdl/*.h ckdl/src/*.c ckdl/src/*.h
   cp ckdl-$COMMIT/include/kdl/*.h ckdl/include/kdl/
   cp ckdl-$COMMIT/src/*.c ckdl-$COMMIT/src/*.h ckdl/src/
   cp ckdl-$COMMIT/COPYING ckdl/COPYING
   ```

3. Record the new commit and date above, and check Makefile.PL: its
   `C` list names every source file in ckdl/src, and the compile
   definitions mirror what upstream's CMakeLists.txt sets for the
   static library.

4. Update MANIFEST if files were added or removed, then run
   `perl Makefile.PL && make test`.
