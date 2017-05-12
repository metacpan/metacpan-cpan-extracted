#!/usr/bin/perl

# examples/rrdtool/update.pl
#  Update OPG stats in Round Robin Database
#
# $Id: update.pl 10656 2009-12-28 03:34:16Z FREQUENCY@cpan.org $

use strict;
use warnings;

use RRDTool::OO;
use WWW::OPG;

=head1 NAME

update.pl - Update a Round Robin Database with OPG stats

=head1 SYNOPSIS

update.pl [filename]

This program loads a Round Robin database suitable for storing statistical
information for OPG's Power Generation and adds the latest data (retrieved
using L<WWW::OPG>. If this script is run without a database name, it uses
a default of B<opg.rrd>.

=cut

my $filename = $ARGV[0] || 'opg.rrd';
my $rrd = RRDTool::OO->new( file => $filename );
my $opg = WWW::OPG->new();

# Update 24 times (for one hour runtime)
for (1..24) {
  eval {
    # Only update if the data has been updated
    if ( $opg->poll() ) {
      print 'Currently generating ', $opg->power, ' MW of electricity ',
        '(As of ', $opg->last_updated, ")\n";

      $rrd->update(
        time    => $opg->last_updated,
        value   => $opg->power,
      );
    }
  };
  if ($@) {
    print STDERR $@;
  }

  # Nyquist Sampling Rate is 2 times maximum update frequency; we want to
  # update at twice the rate of the signal (1 event/5 minutes)
  sleep(2.5*60);
}

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
