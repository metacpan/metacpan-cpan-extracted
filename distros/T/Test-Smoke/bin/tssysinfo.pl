#! /usr/bin/perl -w
use strict;
$| = 1;

# $Id$
use vars qw( $VERSION );
$VERSION = 0.001;

use File::Spec;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use lib $FindBin::Bin;

use System::Info;

my $si = System::Info->new ();
printf "Hostname             : %s\n", $si->host;
printf "Number of CPU's      : %s\n", $si->ncpu;
printf "Processor type       : %s\n", $si->cpu_type;   # short
printf "Processor description: %s\n", $si->cpu;        # long
printf "OS and version       : %s\n", $si->os;
