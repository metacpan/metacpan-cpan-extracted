#!/usr/bin/perl

# examples/rrdtool/graph.pl
#  Update the graphs based on the current time
#
# $Id: graph.pl 10660 2009-12-28 14:41:35Z FREQUENCY@cpan.org $

use strict;
use warnings;

use RRDTool::OO;
use DateTime;

=head1 NAME

graph.pl - Regenerate graphs based on most recent statistics

=head1 SYNOPSIS

graph.pl [filename]

This program loads a Round Robin database used for tracking data and graphs
recent data (based on the last day, week, month and year) of data. If this
script is run without a database name, it uses a default of B<opg.rrd>.

=cut

my $filename = $ARGV[0] || 'opg.rrd';
my $rrd = RRDTool::OO->new( file => $filename );

# Keep track of when the script started up, so all graphs will be shown
# relative to the same time
my $now = DateTime->now();

sub plot {
  my ($name, $period) = @_;

  $rrd->graph(
    image          => $name,
    vertical_label => 'Electric Power (MW)',
    units_exponent => 0,
    width          => 640,
    height         => 150,
    watermark      => 'by Jonathan Yu <http://luminescent.ca>',
    slope_mode     => undef,
    alt_autoscale  => undef,
    interlaced     => undef,

    start          => $now->clone->subtract( seconds => $period ),
    end            => $now,

    draw => {
      name      => 'opg',
      dsname    => 'opg', 
      type      => 'area',
      color     => '00BFFF88',
    },

    draw => {
      name      => 'opg-line',
      dsname    => 'opg',
      type      => 'line',
      thickness => 2,
      color     => '00BFFF',
      legend    => 'Power Generation',
    },

    # Current
    draw => {
      type      => 'hidden',
      name      => 'opg_current',
      vdef      => 'opg,LAST',
    },
    gprint => {
      draw   => 'opg_current',
      format => 'Current\: %0.0lf',
    },

    # Average
    draw => {
      type      => 'hidden',
      name      => 'opg_average',
      vdef      => 'opg,AVERAGE',
    },
    gprint => {
      draw   => 'opg_average',
      format => 'Average\: %0.2lf',
    },

    # Maximum
    draw => {
      type      => 'hidden',
      name      => 'opg_maximum',
      vdef      => 'opg,MAXIMUM',
    },
    gprint => {
      draw   => 'opg_maximum',
      format => 'Maximum\: %0.0lf\n',
    },

    # 95th Percentile
    draw => {
      type      => 'line',
      name      => '95percent',
      vdef      => 'opg,95,PERCENT',
      color     => '191970',
      thickness => 1.5,
      legend    => '95% utilisation',
    },
    gprint => {
      draw      => '95percent',
      format    => '%0.2lf MWe\l',
    },
  );
}

plot('power-day.png',       24*60*60);
plot('power-week.png',    7*24*60*60);
plot('power-month.png',  31*24*60*60);
plot('power-year.png',  365*24*60*60);

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
