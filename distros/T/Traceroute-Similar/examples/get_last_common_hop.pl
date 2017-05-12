#!/usr/bin/env perl

=head1 NAME

get_last_common_hop.pl - returns the farest common router for a list of hosts

=head1 SYNOPSIS

./get_last_common_hop.pl [ -h ]
                         [ -v ]
                         [ -t <seconds> ]
                         <host 1> <host 2> <host n> ...


=head1 DESCRIPTION

this script executes a traceroute for each host and returns the last common router

=head1 ARGUMENTS

script has the following arguments

=over 4

=item help

    -h

print help and exit

=item verbose

    -v

verbose output

=item timeout

    -t <seconds>

    set timeout

    default: 120 seconds

=item host

    <host>

    list of hosts to compare

=back

=head1 EXAMPLE

./get_last_common_hop.pl lp10wa01.w10 lp10wa02.w10 lp10wa03.w10

=head1 AUTHOR

2009, Sven Nierlein, <sven.nierlein@consol.de>

=cut

#########################################################################
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use Carp;
use lib './lib';
use Traceroute::Similar;

#########################################################################
# parse and check cmd line arguments
my ($opt_h, $opt_v, $opt_t, $opt_hosts);
Getopt::Long::Configure('no_ignore_case');
GetOptions (
   "h"              => \$opt_h,
   "v"              => \$opt_v,
   "t=i"            => \$opt_t,
   "<>"             => \&add_host,
);

if(defined $opt_h) {
    pod2usage( { -verbose => 1 } );
    exit 3;
}
my $verbose = 0;
if(defined $opt_v) {
    $verbose = 1;
}
if(!defined $opt_hosts or scalar @{$opt_hosts} == 0) {
    pod2usage( { -verbose => 1 } );
    exit 3;
}

#########################################################################
# Timeout
my $timeout = $opt_t || 120;
$SIG{'ALRM'} = sub {
    my @caller = caller();
    die("timeout in ".$caller[0]." ".$caller[1].":".$caller[2]);
};
alarm($timeout);
print "DEBUG: set timeout to $timeout\n" if $verbose;

#########################################################################
my $ts = Traceroute::Similar->new( verbose => $verbose );
my $last_common_hop = $ts->get_last_common_hop(@{$opt_hosts});
if(defined $last_common_hop) {
    print $last_common_hop."\n";
} else {
    warn "no common hops found\n";
}


#########################################################################
sub add_host {
    my $host = shift;
    push @{$opt_hosts}, $host;
}
