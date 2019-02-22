    README for DTA::TokWrap

ABSTRACT
    DTA::TokWrap - top-level wrapper modules & scripts for DTA corpus
    tokenization

REQUIREMENTS
  dta-tokwrap utilities
    See ../README.txt for details.

  Perl Modules
    Cwd tested version(s): 3.2501

    Encode
        tested version(s): 2.23

    Env::Path
        tested version(s): 0.18

    File::Basename
        tested version(s): 2.76

    Getopt::Long
        tested version(s): 2.37

    Log::Log4perl
        tested version(s): 1.21

    Pod::Usage
        tested version(s): 1.35

    Time::HiRes
        tested version(s): 1.9711

    XML::LibXML
        tested version(s): 1.66

    XML::LibXSLT
        tested version(s): 1.66

    XML::Parser
        tested version(s): 2.36

DESCRIPTION
    The DTA::TokWrap distribution provides wrapper modules and scripts for
    tokenization of DTA "base-format" XML documents.

INSTALLATION
    Issue the following commands to the shell:

     bash$ cd DTA-TokWrap-0.01   # (or wherever you unpacked this distribution)
     bash$ perl Makefile.PL      # check requirements, etc.
     bash$ make                  # build the module
     bash$ make test             # (optional): test module before installing
     bash$ make install          # install the module on your system

SEE ALSO
    ../README.txt, perlmodinstall(1), dta-tokwrap.perl(1),
    DTA::TokWrap(3pm), perl(1).

AUTHOR
    Bryan Jurish <moocow@cpan.org>

