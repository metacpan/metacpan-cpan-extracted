#! /usr/bin/perl

use ExtUtils::MakeMaker;
use Devel::CheckLib;

check_lib_or_exit( lib => 'X11', header => [ 'X11/Xlib.h', 'X11/Xutil.h', 'X11/Xatom.h' ] );
check_lib_or_exit( lib => 'png', header => 'png.h' );

WriteMakefile(
    NAME	=> 'X11::PngViewer',
    VERSION_FROM => 'lib/X11/PngViewer.pm',
    LIBS	=> ['-lX11 -lpng'],
    LICENSE     => 'Perl_5',
    PL_FILES    => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
	'Devel::CheckLib' => 0,
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'MIME::Base64' => 0,
        'Test::More' => 0,
        'Test::NeedsDisplay' => 0,
    },
    PREREQ_PM => {
        'DynaLoader' => 0,
        'strict' => 0,
        'warnings' => 0,
	'base' => 0,
		},
);


