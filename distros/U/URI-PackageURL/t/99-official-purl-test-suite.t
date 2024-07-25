#!perl

use JSON::PP;
use Test::More;
use File::Spec;

# Official PackageURL test suite (https://raw.githubusercontent.com/package-url/purl-spec/master/test-suite-data.json)

require_ok('URI::PackageURL');

sub test_purl_encode {

    my ($test) = @_;

    my $test_name = $test->{description};

    my $purl = eval {
        URI::PackageURL->new(
            type       => $test->{type},
            namespace  => $test->{namespace},
            name       => $test->{name},
            version    => $test->{version},
            qualifiers => $test->{qualifiers},
            subpath    => $test->{subpath}
        );
    };

    if ($test->{is_invalid}) {
        like($@, qr/Invalid Package URL/i, "ENCODE: $test_name");
        return;
    }

    if (!$test->{is_invalid} && $@) {
        fail("ENCODE: $test_name");
        return;
    }

    if (!$test->{is_invalid}) {
        is($purl->to_string, $test->{canonical_purl}, "ENCODE: $test_name");
        return;
    }

}

sub test_purl_decode {

    my ($test) = @_;

    my $test_name = $test->{description};

    my $purl = eval { URI::PackageURL->from_string($test->{purl}) };

    if ($test->{is_invalid}) {
        like($@, qr/(Invalid|Malformed) Package URL/i, "DECODE: $test_name");
        return;
    }

    if (!$test->{is_invalid} && $@) {
        fail("DECODE: $test_name");
        return;
    }

    if (!$test->{is_invalid}) {
        is($purl->to_string, $test->{canonical_purl}, "DECODE: $test_name");
        return;
    }

}

my $test_suite_file = File::Spec->catfile('t', 'test-suite-data.json');

BAIL_OUT('"test-suite-data.json" file not found') if (!-e $test_suite_file);

open my $fh, '<', $test_suite_file or Carp::croak "Can't open file: $!";

my $test_suite_content = do { local $/; <$fh> };
my $test_suite_data    = JSON::PP::decode_json($test_suite_content);

foreach my $test (@{$test_suite_data}) {
    test_purl_encode($test);
    test_purl_decode($test);
}

done_testing();
