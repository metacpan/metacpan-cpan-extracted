#!perl -T

use strict;
use warnings;

use Test::More;

use URI::PackageURL qw(encode_purl);


my @TESTS = (
    {
        purl      => 'pkg:cpan/DROLSKY/DateTime@1.55',
        type      => 'cpan',
        namespace => 'DROLSKY',
        name      => 'DateTime',
        version   => '1.55'
    },
    {purl => 'pkg:cpan/GDT/URI-PackageURL', type => 'cpan', namespace => 'GDT', name => 'URI-PackageURL'},
    {
        purl      => 'pkg:cpan/OALDERS/libwww-perl@6.76',
        type      => 'cpan',
        namespace => 'OALDERS',
        name      => 'libwww-perl',
        version   => '6.76'
    },
    {
        purl       => 'pkg:generic/100%25/100%25@100%25?repository_url=https://example.com/100%2525/#100%25',
        type       => 'generic',
        namespace  => '100%',
        name       => '100%',
        version    => '100%',
        qualifiers => {'repository_url' => 'https://example.com/100%25/'},
        subpath    => '100%',
    },
    {purl => 'pkg:brew/openssl%401.1@1.1.1w', type => 'brew', name => 'openssl@1.1', version => '1.1.1w'},
);


foreach my $test (@TESTS) {

    my $expected_purl = $test->{purl};

    subtest "$expected_purl" => sub {

        my $got_purl_1 = encode_purl(
            type       => $test->{type},
            namespace  => $test->{namespace},
            name       => $test->{name},
            version    => $test->{version},
            qualifiers => $test->{qualifiers},
            subpath    => $test->{subpath},
        );

        my $got_purl_2 = URI::PackageURL->new(
            type       => $test->{type},
            namespace  => $test->{namespace},
            name       => $test->{name},
            version    => $test->{version},
            qualifiers => $test->{qualifiers},
            subpath    => $test->{subpath},
        );

        my $got_purl_3 = URI::PackageURL->from_string($expected_purl)->to_string;

        is($got_purl_1, $expected_purl, "encode_purl --> $got_purl_1");
        is($got_purl_2, $expected_purl, "URI::PackageURL --> $got_purl_2");
        is($got_purl_3, $expected_purl, "decode+encode --> $got_purl_3");

    };

}

done_testing();
