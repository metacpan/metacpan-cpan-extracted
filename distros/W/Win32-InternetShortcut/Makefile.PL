use strict;
use warnings;
use ExtUtils::MakeMaker;

if ( $^O ne 'MSWin32' ) {
  print STDERR "This is for MSWin32 only\n";
  exit 0;
}

WriteMakefile(
    NAME          => 'Win32::InternetShortcut',
    VERSION_FROM  => 'lib/Win32/InternetShortcut.pm',
    PREREQ_PM     => {
      'Test::More' => 0.47,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Win32/InternetShortcut.pm',
       AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>') : ()
    ),
    LIBS     => [],
    DEFINE   => '',
    INC      => '-I.',
    # OBJECT => '$(O_FILES)', # link all the C files too
    XS       => { 'InternetShortcut.xs' => 'InternetShortcut.cpp' },
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE => 'perl') : ()
    ),
);

sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}
