use ExtUtils::MakeMaker;

# $Abso: abso/divers/mat/perl/WWW-Mechanize-SpamCop/Makefile.PL,v 1.1 2003/08/05 12:56:50 mat Exp $

WriteMakefile(
    'NAME'         => 'WWW::Mechanize::SpamCop',
    'VERSION_FROM' => 'SpamCop.pm',                 # finds $VERSION
    'PREREQ_PM'    => { 'WWW::Mechanize' => 0 },    # e.g., Module::Name => 1.1
    (
	$] >= 5.005
	?                                           ## Add these new keywords supported since 5.005
	    (
	    ABSTRACT_FROM => 'SpamCop.pm',                     # retrieve abstract from module
	    AUTHOR        => 'Mathieu Arnold <mat@cpan.org>, Aleksander Adamowski <cpan@olo.org.pl>'
	    )
	: ()
    ),
);

