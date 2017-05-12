use 5.006;
use ExtUtils::MakeMaker;

BEGIN {
  unless ( $^O =~ /MSWin32/i ) {
    die qq{OS unsupported: This module requires a "native" }
      . qq{(i.e. non-Cygwin) Microsoft Windows platform.\n};
  }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME         => 'Win32::Console::ANSI',
  VERSION_FROM => 'lib/Win32/Console/ANSI.pm',    # finds $VERSION
  PREREQ_PM    => { 
                   Win32::Pipe => 0,
                   Win32::Process => 0,
    },                             # e.g., Module::Name => 1.1
  ( $] >= 5.005
    ?    ## Add these new keywords supported since 5.005
      (
      ABSTRACT_FROM =>
        'lib/Win32/Console/ANSI.pm',    # retrieve abstract from module
      AUTHOR => 'J-L. Morel <jl_morel@bribes.org>'
      )
    : ()
  ),
  LICENSE => 'perl',
  LIBS   => [''],     # e.g., '-lm'
  DEFINE => '',       # e.g., '-DHAVE_SOMETHING'
  INC    => '-I.',    # e.g., '-I. -I/usr/include/other'
                      # Un-comment this if you add C files to link with later:
       # OBJECT            => '$(O_FILES)', # link all the C files too
);
