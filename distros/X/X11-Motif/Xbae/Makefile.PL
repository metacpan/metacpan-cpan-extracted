
# Copyright 1997, 1998 by Ken Fox

use ExtUtils::MakeMaker;
require "../config.pm";

if ($want_xbae) {
    if (!$want_motif) {
	die "If you want the Xbae widgets, you must build the Motif module\n";
    }
}

WriteMakefile('NAME' => 'X11::Xbae',
	      'VERSION_FROM' => 'Xbae.pm');
