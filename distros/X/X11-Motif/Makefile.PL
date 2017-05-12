
# Copyright 1997, 1998 by Ken Fox

use ExtUtils::MakeMaker;
require "./config.pm";

$dirs = [ 'Lib', 'Toolkit' ];

push(@{$dirs}, 'Motif') if ($want_motif);
push(@{$dirs}, 'Xbae') if ($want_xbae);
push(@{$dirs}, 'XRT') if ($want_xrt);
push(@{$dirs}, 'Athena') if ($want_athena);
push(@{$dirs}, 'Xpm') if ($want_xpm);

my @static_options = ();
if ($want_static_perl) {
    push(@static_options, 'LINKTYPE' => 'static', 'MAP_TARGET' => 'xperl');
}

WriteMakefile('OPTIMIZE' => '-g',
	      'PM' => { },
	      'NAME' => 'X11',
	      'DIR' => $dirs,
	      @static_options);
