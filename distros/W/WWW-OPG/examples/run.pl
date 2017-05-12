#!/usr/bin/perl

# examples/run.pl
#  Continuously show updated stats
#
# $Id: run.pl 10634 2009-12-26 04:55:13Z FREQUENCY@cpan.org $

use strict;
use warnings;

use WWW::OPG;

=head1 NAME

run.pl - Display up-to-date power generation statistics

=head1 SYNOPSIS

run.pl

This program retrieves real-time power generation information using the
L<WWW::OPG> module.

=cut

print "This program will loop continuously. Use ^C to stop.\n";

my $opg = WWW::OPG->new();

while (1) {
  eval {
    # Only update if the data has been updated
    if ( $opg->poll() ) {
      print "Currently generating ", $opg->power, " MW of electricity ";
      print "(As of ", $opg->last_updated, ")\n";
    }

    # Nyquist Sampling Rate is 2 times maximum update frequency; we want to
    # update at twice the rate of the signal (1 event/5 minutes)
    sleep(2.5*60);
  };
  if ($@) {
    print STDERR $@;
  }
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
