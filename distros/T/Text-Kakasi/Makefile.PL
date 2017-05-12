#
# $Id: Makefile.PL,v 2.0 2003/05/22 18:19:11 dankogai Exp $
#
use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME' => 'Text::Kakasi',
	      'VERSION_FROM' => 'Kakasi.pm',
	      'INC' => '-I/usr/local/include',
	      'LIBS' => ['-L/usr/local/lib -lkakasi'],
	      'DEFINE' => '-DWAKATIGAKI',
);
