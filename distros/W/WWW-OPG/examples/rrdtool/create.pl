#!/usr/bin/perl

# examples/rrdtool/create.pl
#  Create a new Round Robin database for OPG stats
#
# $Id: create.pl 10634 2009-12-26 04:55:13Z FREQUENCY@cpan.org $

use strict;
use warnings;

use RRDTool::OO;
use WWW::OPG;

=head1 NAME

create.pl - Create a new Round Robin database for OPG stats

=head1 SYNOPSIS

create.pl [filename]

This program creates a Round Robin database suitable for storing statistical
information for OPG's Power Generation. If this script is run without a
database name, it defaults to B<opg.rrd>.

=cut

my $filename = $ARGV[0] || 'opg.rrd';
my $rrd = RRDTool::OO->new( file => $filename );

my $step = 5*60; # 5 minute step
my $limit = 365*24*60*60;

# Retrieve one record
my $opg = WWW::OPG->new();
$opg->poll(); # may die and cause script to abort

my $start = $opg->last_updated->epoch;
my $end = $start + $limit;

$rrd->create(
  start => $start,
  step  => $step,

  data_source => {
    name => 'opg',
    type => 'GAUGE',
  },

  # 1 sample "averaged" stays 1 period of 5 minutes
  # 6 samples averaged become one average on 30 minutes
  # 24 samples averaged become one average on 2 hours
  # 288 samples averaged become one average on 1 day
  #
  # Thus, to store it, we need:
  # 600 samples of 5 minutes  (2 days and 2 hours)
  # 700 samples of 30 minutes (2 days and 2 hours, plus 12.5 days)
  # 775 samples of 2 hours    (above + 50 days)
  # 797 samples of 1 day      (above + 732 days, rounded up to 797)
  # From: http://oss.oetiker.ch/rrdtool/tut/rrdtutorial.en.html
  archive => {
    rows    => 600,
    cpoints => 1,
    cfunc   => 'AVERAGE',
  },
  archive => {
    rows    => 700,
    cpoints => 6,
    cfunc   => 'AVERAGE',
  },
  archive => {
    rows    => 775,
    cpoints => 24,
    cfunc   => 'AVERAGE',
  },
  archive => {
    rows    => 797,
    cpoints => 288,
    cfunc   => 'AVERAGE',
  },
);

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head1 SUPPORT

For support details, please look at C<perldoc WWW::OPG> and use the
corresponding support methods.

=head1 LICENSE

This has the same copyright and licensing terms as L<WWW::OPG>.

=head1 SEE ALSO

L<RRDTool::OO>,

=cut
