NAME
    README for Tie::File::Indexed - fast tied array access to indexed data
    files

DESCRIPTION
    The Tie::File::Indexed class provides fast tied array access to raw
    data-files using an auxilliary packed index-file to store and retrieve
    the offsets and lengths of the corresponding raw data strings as well as
    an additional header-file to store administrative data, resulting in a
    constant and very small memory footprint. Random-access storage and
    retrieval should both be very fast, and even pop(), shift() and splice()
    operations on large arrays should be tolerably efficient, since these
    only need to modify the (comparatively small) index-file.

    The Tie::File::Indexed distribution also comes with several pre-defined
    subclasses for transparent encoding/decoding of UTF8-encoded strings,
    and complex data structures encoded via the JSON or Storable modules.

INSTALLATION
  Building from Source
    To build and install the entire package, issue the following commands to
    the shell:

     bash$ cd PACKAGE-X.YY       # (or wherever you unpacked this distribution)
     bash$ perl Makefile.PL      # configure the package
     bash$ make                  # build the package
     bash$ make test             # test the build (optional)a
     bash$ make install          # install the package on your system

    More details on the top-level installation process can be found in the
    perlmodinstall(1) manpage.

SEE ALSO
    Tie::Array(3pm), Tie::File(3pm), perl(1).

AUTHOR
    Bryan Jurish <moocow@cpan.org>

