#
# $Id: Makefile.PL,v 1.3 2000/12/01 15:02:15 jmorris Exp $
#
use strict;
$^W = 1;

#
# Defaults
#
my $IPTABLES_DIR = '/usr/local';

#
# Query user to override defaults.
#
$IPTABLES_DIR = lc prompt("\nLocation of iptables development components:", $IPTABLES_DIR);

print STDERR <<END;

Ok, using '$IPTABLES_DIR' to find libipq headers and libraries.

END

#
# Generate the Makefile
#
use ExtUtils::MakeMaker;

WriteMakefile('NAME' => 'IPTables::IPv4::IPQueue',
              'DISTNAME' => 'perlipq',
              'VERSION_FROM' => 'IPQueue.pm',
              'LIBS' => ["-L$IPTABLES_DIR/libipq -lipq"],
              'DEFINE' => '',
              'INC' => "-I$IPTABLES_DIR/include");
