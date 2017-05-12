# $Id: Makefile.PL,v 1.1 2004/03/22 21:41:32 simonflack Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Wx::Perl::Throbber',
    'VERSION_FROM'	=> 'lib/Wx/Perl/Throbber.pm',
    'PREREQ_PM'		=> { Wx => 0.19, 'Test::More' => 0.45 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Wx/Perl/Throbber.pm',
       AUTHOR     => 'Simon Flack') : ()),
);
