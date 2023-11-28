#!perl -T

use strict;
use warnings;

use Test::More;

use URI::PackageURL qw(encode_purl);

my $expected_purl = 'pkg:cpan/GDT/URI-PackageURL@' . $URI::PackageURL::VERSION;
my $encoded_purl
    = encode_purl(type => 'cpan', namespace => 'GDT', name => 'URI-PackageURL', version => $URI::PackageURL::VERSION);

is($encoded_purl, $expected_purl, 'encode_purl()');

done_testing();
