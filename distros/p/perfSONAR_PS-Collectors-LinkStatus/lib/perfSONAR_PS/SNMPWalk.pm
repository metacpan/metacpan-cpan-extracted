# ============================================================================

# Copyright (c) 2000-2005 David M. Town <dtown@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

# ============================================================================

package perfSONAR_PS::SNMPWalk;

use Net::SNMP qw(:snmp DEBUG_ALL);
use Exporter;

use strict;
use warnings;

our $VERSION = 0.09;

use base 'Exporter';
our @EXPORT = ('snmpwalk');

sub snmpwalk {
    my ($host, $port, $oid, $community, $version) = @_;

    if (not $host) {
        return (-1, "No host specified");
    }

    # Create the SNMP session
    my ($s, $e) = Net::SNMP->session(
       -hostname => $host,
       (defined $port and $port ne "")? (-port => $port) : (),
       (defined $community and $community ne "")? (-community => $community) : (),
       (defined $version and $version ne "")? (-version => $version) : (),
    );

    # Was the session created?
    if (!defined($s)) {
       return (-1, "Couldn't create session");
    }

    # Perform repeated get-next-requests or get-bulk-requests (SNMPv2c)
    # until the last returned OBJECT IDENTIFIER is no longer a child of
    # OBJECT IDENTIFIER passed in on the command line.

    my @args = (
       -varbindlist    => [$oid]
    );

    my @results = ();
    if ($s->version == SNMP_VERSION_1) {

       my $oid;

       while (defined($s->get_next_request(@args))) {
          $oid = ($s->var_bind_names())[0];

          if (!oid_base_match($ARGV[0], $oid)) { last; }

          my @result = ( $oid, snmp_type_ntop($s->var_bind_types()->{$oid}), $s->var_bind_list()->{$oid} );
          push @results, \@result;

          @args = (-varbindlist => [$oid]);
       }

    } else {

       push(@args, -maxrepetitions => 25);

       outer: while (defined($s->get_bulk_request(@args))) {

          my @oids = oid_lex_sort(keys(%{$s->var_bind_list()}));

          foreach (@oids) {

             if (!oid_base_match($oid, $_)) { last outer; }

             my @result = ( $_, snmp_type_ntop($s->var_bind_types()->{$_}), $s->var_bind_list()->{$_} );
             push @results, \@result;

             # Make sure we have not hit the end of the MIB
             if ($s->var_bind_list()->{$_} eq 'endOfMibView') { last outer; }
          }

          # Get the last OBJECT IDENTIFIER in the returned list
          @args = (-maxrepetitions => 25, -varbindlist => [pop(@oids)]);
       }
    }

    # Let the user know about any errors
    if ($s->error() ne '') {
       return(-1, $s->error());
    }

    # Close the session
    $s->close();

    return (0, \@results);
}

1;
