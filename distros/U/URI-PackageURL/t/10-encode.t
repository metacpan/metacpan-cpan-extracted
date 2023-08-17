#!perl -T

use strict;
use warnings;

use Test::More;

use URI::PackageURL qw(encode_purl);

is(
    encode_purl(type => 'cpan', namespace => 'GDT', name => 'URI-PackageURL', version => $URI::PackageURL::VERSION),
    'pkg:cpan/GDT/URI-PackageURL@' . $URI::PackageURL::VERSION,
    'encode_purl()'
);

done_testing();
