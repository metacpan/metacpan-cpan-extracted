#!perl -T

use strict;
use warnings;

use Test::More;

use URI::VersionRange;

subtest "VERS: canonical percent-encoding (only reserved characters are encoded)" => sub {

    #<<<
    my @tests = (
        {version => '1.0.0+build', expected => 'vers:generic/1.0.0+build'},
        {version => '1.0:2~3',     expected => 'vers:generic/1.0:2~3'},
        {version => '1|2',         expected => 'vers:generic/1%7C2'},
        {version => '1>2<3=4!5',   expected => 'vers:generic/1%3E2%3C3%3D4%215'},
        {version => '1*2%3',       expected => 'vers:generic/1%2A2%253'},
        {version => '1 2',         expected => 'vers:generic/1%202'},
    );
    #>>>

    foreach my $test (@tests) {

        my $vers = URI::VersionRange->new(
            scheme      => 'generic',
            constraints => [URI::VersionRange::Constraint->new(version => $test->{version})]
        );

        is("$vers",                          $test->{expected}, "encode: '$test->{version}'");
        is($vers->constraints->[0]->version, $test->{version},  "decode: '$test->{version}'");

        my $roundtrip = URI::VersionRange->from_string("$vers");
        is("$roundtrip", "$vers", "roundtrip: $vers");

    }

};

subtest "VERS: percent-decoding (exactly once)" => sub {
    is(URI::VersionRange->from_string('vers:npm/1.0%252F0')->constraints->[0]->version, '1.0%2F0', 'decode once');
};

subtest "VERS: invalid percent-encoding" => sub {

    #<<<
    my @tests = (
        {vers => 'vers:npm/1.0%2G0',         error => qr/Invalid percent-encoding/},
        {vers => 'vers:npm/1.0%7c1',         error => qr/Invalid percent-encoding/},
        {vers => 'vers:npm/1.0%2B1',         error => qr/Non-canonical percent-encoding/},
        {vers => 'vers:npm/00%3A00',         error => qr/Non-canonical percent-encoding/},
        {vers => 'vers:lexicographic/1%092', error => qr/Non-canonical percent-encoding/},
    );
    #>>>

    foreach my $test (@tests) {
        eval { URI::VersionRange->from_string($test->{vers}) };
        like($@, $test->{error}, "error: $test->{vers}");
    }

};

done_testing();
