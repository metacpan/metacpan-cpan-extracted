# $Id: Makefile.PL 38877 2006-07-12 12:16:51Z nanardon $

use 5.008;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'VFSsimple',
    AUTHOR   => 'Olivier Thauvin <nanardon@nanardon.zarb.org>',
    VERSION_FROM => 'lib/VFSsimple.pm',
    EXE_FILES => [ map { "bin/$_" } qw(listmedia vfsget) ],
);

package MY;

sub postamble {
    return "
mymanifest :
\tdarcs query manifest | grep '^./VFSsimple' | sed 's:^./VFSsimple/::' | sort > MANIFEST
";
}
