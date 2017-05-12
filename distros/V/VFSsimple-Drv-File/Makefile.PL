# $Id: Makefile.PL 38877 2006-07-12 12:16:51Z nanardon $

use 5.008;
use strict;
use ExtUtils::MakeMaker;

my $modulename = 'File';

WriteMakefile(
    NAME	 => "VFSsimple::Drv::$modulename",
    AUTHOR   => 'Olivier Thauvin <nanardon@nanardon.zarb.org>',
    VERSION_FROM => "lib/VFSsimple/Drv/$modulename.pm",
    PREREQ_PM => { 'VFSsimple::Base' => undef },
);

package MY;

sub postamble {
    return "
mymanifest :
\tdarcs query manifest | grep '^./$modulename' | sed 's:^./$modulename/::' | sort > MANIFEST
";
}
