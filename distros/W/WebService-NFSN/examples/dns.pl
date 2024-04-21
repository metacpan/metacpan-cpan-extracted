#! /usr/local/bin/perl
#---------------------------------------------------------------------
# dns.pl
# Copyright 2007 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Example of using the DNS API
#---------------------------------------------------------------------

use strict;
use warnings;
# RECOMMEND PREREQ: Data::Dumper
use Data::Dumper;
use WebService::NFSN;

my ($user, $key, $domain) = @ARGV;

die "Usage: $0 USER API_KEY DOMAIN\n" unless defined $domain;

my $nfsn = WebService::NFSN->new($user, $key);

my $rr = $nfsn->dns($domain)->listRRs;

$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse    = 1;
print Dumper($rr);
