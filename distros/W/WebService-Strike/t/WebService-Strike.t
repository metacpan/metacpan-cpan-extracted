#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper qw/Dumper/;
use Test::RequiresInternet qw/getstrike.net 443/;
use Test::More skip_all => 'The Strike API was discontinued, therefore this test is disabled';
use Test::More tests => 8;
use Try::Tiny;
BEGIN { use_ok('WebService::Strike') };

my ($t1, $t2, $t3);
try {
	($t1, $t2, $t3) = strike qw/66FC47BF95D1AA5ECA358F12C70AF3BA5C7E8F9A 5D4FD5A64E436A831383773F85FB38B888B9ECC9 B425907E5755031BDA4A8D1B6DCCACA97DA14C04/;
} catch {
	diag 'Error while calling strike:', "\n", Dumper $_
};

subtest 'order' => sub {
	plan tests => 3;
	is $t1->hash, '66FC47BF95D1AA5ECA358F12C70AF3BA5C7E8F9A', 'hash #1';
	is $t2->hash, '5D4FD5A64E436A831383773F85FB38B888B9ECC9', 'hash #2';
	is $t3->hash, 'B425907E5755031BDA4A8D1B6DCCACA97DA14C04', 'hash #3'
};

is $t1->date, 1439319419, 'date';
is $t2->title, 'FreeBSD 7.1 i386.DVD.iso', 'title';
like $t2->description, qr#FreeBSD#, 'description contains FreeBSD';

try {
	strike 'aaa';
} catch {
	is $_->{status}, 404, 'non-existent torrent status is 404';
};

my @debian = strike_search 'Debian';
ok @debian > 10, 'search for Debian returned more than 10 results';
try {
	strike_search "nosuchstring$$";
} catch {
	is $_->{status}, 404, "search for nosuchstring$$ returned 404"
};

# Test disabled as it fails due to the API returning bad results
#my $p = strike_search 'Perl', 1;
#say STDERR $p->hash;
#
#is @{$p->file_names}, $p->count, 'file_names has count elements';

# Test disabled as I can't find a torrent with an IMDB ID. Presumably
# this feature of the API is broken.
#my $imdb = strike('ED70C185E3E3246F30B2FDB08D504EABED5EEA3F')->imdb;
#is $imdb->{title}, 'The Walking Dead', 'imdb title';
