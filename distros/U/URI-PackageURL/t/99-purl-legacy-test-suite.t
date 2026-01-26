#!perl

use JSON::PP;
use Test::More;
use File::Spec;

# Official "legacy" PURL test suite (https://raw.githubusercontent.com/package-url/purl-spec/e56202efb16b943add2ae27b81a00efd25add47a/test-suite-data.json)

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

    local $TODO = 'SKIP test because in ENCODE always generate well format PURL string' if ($test->{purl} =~ /pkg%3A/);

    if ($test->{is_invalid}) {
        like($@, qr/Invalid PURL/i, "ENCODE: $test_name");
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

    my ($test, $purl_string_field) = @_;

    $purl_string_field //= 'canonical_purl';

    return unless defined $test->{$purl_string_field};

    my $purl_string = $test->{$purl_string_field};
    my $test_name   = $test->{description};

    my $purl = eval { URI::PackageURL->from_string($purl_string) };

    if ($test->{is_invalid}) {
        like($@, qr/(Invalid|Malformed) PURL/i, "DECODE $purl_string_field: $test_name");
        return;
    }

    if (!$test->{is_invalid} && $@) {
        fail("DECODE: $test_name --> $purl_string");
        return;
    }

    if (!$test->{is_invalid}) {

        is($purl->to_string, $test->{canonical_purl}, "DECODE $purl_string_field: $test_name");

        my @components = qw(type namespace name version subpath);

    TODO: {

            local $TODO = 'SKIP test because in canonical subpath exist "." or ".."'
                if ($test->{subpath} && $test->{subpath} =~ /\./);

            foreach my $component (@components) {
                is($purl->$component, $test->{$component},
                    "DECODE $purl_string_field: Compare '$test_name' $component component");
            }

        }

        my $qualifiers = $purl->qualifiers;

        is_deeply($qualifiers, $test->{qualifiers}, "DECODE $purl_string_field: Compare '$test_name' qualifiers")
            if %{$qualifiers};

        return;
    }

}

my $test_suite_file = File::Spec->catfile('t', 'test-suite-data.json');

BAIL_OUT('"test-suite-data.json" file not found') if (!-e $test_suite_file);

open my $fh, '<', $test_suite_file or Carp::croak "Can't open file: $!";

my $test_suite_content = do { local $/; <$fh> };
my $test_suite_data    = JSON::PP::decode_json($test_suite_content);

foreach my $test (@{$test_suite_data}) {

TODO: {

        local $TODO = '(!) Disabled test!';

        $ENV{PURL_LEGACY_CPAN_TYPE} = 1;

        test_purl_encode($test);
        test_purl_decode($test, 'purl');
        test_purl_decode($test, 'canonical_purl');
    }

}

done_testing();
