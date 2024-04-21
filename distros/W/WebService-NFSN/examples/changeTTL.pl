#! /usr/local/bin/perl
#---------------------------------------------------------------------
# changeTTL.pl
# Copyright 2008 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Change the TTL of all records matching the given parameters
#---------------------------------------------------------------------

use strict;
use warnings;
use WebService::NFSN;

my ($domain, $newTTL, @parameters) = @ARGV;

# Check our parameters:
die <<"" unless $domain and $newTTL and not @parameters % 2;
Usage: $0 DOMAIN NEW_TTL [PARAMETERS...]\n
The PARAMETERS will be passed to listRRs for DOMAIN.
All RRs returned will have their TTL updated to NEW_TTL.
You must have your login credentials in .nsfn-api\n
Examples:
  $0 example.com 5400 type TXT
  $0 example.com 60 name dynamic

# Create a DNS object:
print STDERR "Reading credentials from .nfsn-api...\n";
my $nfsn = WebService::NFSN->new;
my $dns = $nfsn->dns($domain);

# List the RRs to update:
print STDERR "Listing RRs matching @parameters...\n";
my $rrList = $dns->listRRs(@parameters);

# Update each RR that has the wrong TTL:
foreach my $rr (@$rrList) {
  next if $rr->{ttl} == $newTTL;

  my @record = map { $_ => $rr->{$_} } qw(name type data);

  print "Updating @$rr{qw(name type data)}...\n";
  $dns->removeRR(@record);
  $dns->addRR(@record, ttl => $newTTL);
} # end foreach $rr
