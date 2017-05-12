# $Id: Makefile.PL,v 1.2 2004/04/17 22:13:43 simonflack Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Wx::Perl::TreeChecker',
    'VERSION_FROM'	=> 'lib/Wx/Perl/TreeChecker.pm',
    'PREREQ_PM'		=> { Wx => 0.18, 'Test::More' => 0.45 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Wx/Perl/TreeChecker.pm',
       AUTHOR     => 'Simon Flack') : ()),
);
