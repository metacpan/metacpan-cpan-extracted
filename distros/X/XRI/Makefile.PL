# Copyright (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>

# Makefile for XRI library and command line interface

require 5.6.0;
use ExtUtils::MakeMaker;
use File::Copy;
use Config;

use vars qw($roots);

my $xrilib = "$Config{'installsitelib'}/XRI";

$roots = prompt("Where should the xriroots.xml be installed (default OK)?\n",
                $xrilib);

rename 'XRI.pm', 'XRI.pm.bak';
open IFH, "< XRI.pm.bak" or die "$!\n";
open OFH, "> XRI.pm" or die "$!\n";
while (my $line = <IFH>) {
    if ($line =~ /^my \$ROOTS/) {
        $line = qq(my \$ROOTS = '$roots/xriroots.xml';\n);
    }
    print OFH $line;
}
close OFH;
close IFH;

WriteMakefile(
    NAME              => 'XRI',
    VERSION_FROM      => 'XRI.pm',
    EXE_FILES         => ['scripts/xriresolve.pl'],
    PREREQ_PM         => {LWP::Simple => 0,
                          Log::Agent => 0,
                          Text::Balanced => 0,
                          URI::Escape => 0,
                          XML::Smart => 0,
                          Getopt::Std => 0},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'XRI.pm',
       AUTHOR         => 'Fen Labalme <fen@idcommons.net>') : ()),
);

# add code to Makefile for writing xriroots.xml
package MY;

sub postamble {
    my $roots = $main::roots;
    return <<EOM;
xriroots_install ::
	if test -r $roots/xriroots.xml; then mv $roots/xriroots.xml $roots/xriroots.xml.bak; fi
	cp XRI/xriroots.xml $roots
EOM
}

sub install {
    my $self = shift;
    my $basic = $self->SUPER::install(@_);
    $basic =~ s/^(install\s+::\s+.*)$/$1 xriroots_install/m;
    return $basic;
}
