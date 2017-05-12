use 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'WKHTMLTOX::XS',
	PREREQ_PM       => {},
	VERSION_FROM	=> 'lib/WKHTMLTOX/XS.pm',
    ($] >= 5.005 ?
      	(ABSTRACT  => 'Perl XS (Written in C( Wrapper for libwkhtmltox',
       	AUTHOR         => 'Kurt Wagner <kurt.wagner@affinitylive.com>') : ()),
	LIBS            => '-lstdc++ -lwkhtmltox',
	DEFINE		=> '-Wall -ansi -ggdb -O2',
	INC             => '-I.',
	LD 		=> 'gcc',
	CC 		=> 'gcc',
	OBJECT    	=> 'perl-wkhtmltox.o perl-wkhtmltox-func.o',
	clean 		=> {FILES => "t/*.jpg t/*.pdf"},
);
