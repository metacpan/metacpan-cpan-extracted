#!perl -T

use strict;
use warnings;

use Test::More;

use URI::VersionRange;

my $vers = 'vers:cpan/>v1.00|!=v2.10|<=v3.00';

my $v1 = URI::VersionRange->from_string($vers);

my $v2 = URI::VersionRange->new(
    scheme      => 'cpan',
    constraints => [
        URI::VersionRange::Constraint->new(comparator => '>',  version => 'v1.00'),
        URI::VersionRange::Constraint->new(comparator => '!=', version => 'v2.10'),
        URI::VersionRange::Constraint->new(comparator => '<=', version => 'v3.00')
    ]
);

my $v3 = URI::VersionRange->new(scheme => 'cpan', constraints => ['>v1.00', '!=v2.10', '<=v3.00']);

my $v4 = decode_vers($vers);

my $v5 = decode_vers(encode_vers(scheme => 'cpan', constraints => ['>v1.00', '!=v2.10', '<=v3.00']));

my %TESTS = (
    'from_string'               => $v1,
    'object-oriented #1'        => $v2,
    'object-oriented #2'        => $v3,
    'decode_vers'               => $v4,
    'encode_vers + decode_vers' => $v5,
);

my @in_range     = ('v2.11', 'v2.99', 'v3.00');
my @not_in_range = ('v0.01', 'v0.99', 'v2.10');

foreach (sort keys %TESTS) {
    is $v1, $TESTS{$_}, "Version range ($_)";
}

is $v1->contains($_), !!1, "$_ version in range ($v1)"     for (sort @in_range);
is $v1->contains($_), !!0, "$_ version not in range ($v1)" for (sort @not_in_range);

done_testing();
