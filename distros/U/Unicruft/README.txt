NAME
    README for Unicruft - perl UTF-8 approximation module

DESCRIPTION
    The perl Unicruft package provides a perl interface to the libunicruft
    library, which is itself derived in part from the Text::Unidecode perl
    module.

INSTALLATION
  Requirements
   C Libraries
    libunicruft >= v0.21

  Building from Source
    To build and install the entire package, issue the following commands to
    the shell:

     bash$ cd unicruft-perl-0.01 # (or wherever you unpacked this distribution)
     bash$ perl Makefile.PL      # configure the package
     bash$ make                  # build the package
     bash$ make test             # test the build (optional)a
     bash$ make install          # install the package on your system

    More details on the top-level installation process can be found in the
    perlmodinstall(1) manpage.

SEE ALSO
    unicruft(1), Text::Unidecode(3pm), recode(1), iconv(1), ...

AUTHOR
    Bryan Jurish <moocow@cpan.org>

