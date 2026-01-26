#!perl

use File::Spec;
use JSON::PP;
use Test::More;
use File::Find qw(find);

require_ok('URI::PackageURL');

my $purl_tests_dir = File::Spec->catdir('t', 'purl');

BAIL_OUT('"purl" tests directory not found') if (!-d $purl_tests_dir);


find {wanted => \&execute_test, no_chdir => 1}, $purl_tests_dir;

sub test_context {
    my $test = shift;
    return sprintf '%s [%s] %s', $test->{test_type}, $test->{test_group}, $test->{description};
}

sub execute_test {

    my $test_file = $_;

    return if -d $test_file;
    return unless $test_file =~ /\.json/;

    if (my $purl_type = $ENV{PURL_TYPE}) {
        return unless ($test_file =~ /$purl_type/);
        diag "Test only $ENV{PURL_TYPE} testcases";
    }

    note "--- $test_file ---";

    open my $fh, '<', $test_file or Carp::croak "Can't open file: $!";

    my $test_content = do { local $/; <$fh> };
    my $test_data    = eval { JSON::PP::decode_json($test_content) };

    BAIL_OUT("$test_file - $@") if $@;

    foreach my $test (@{$test_data->{tests}}) {

        $test->{file} = $test_file;

    TODO: {

            local $TODO = 'Maven - SKIP test because in ENCODE always generate well format PURL string'
                if ($test->{description} eq 'invalid encoded colon : between scheme and type');

            # (!) Skip some tests for PRs and issues in purl-spec that are still open

            local $TODO = 'Huggingface - missing namespace - test issue' if ($test_file =~ /huggingface/);

            execute_parse_test($test)      if $test->{test_type} eq 'parse';
            execute_build_test($test)      if $test->{test_type} eq 'build';
            execute_roundtrip_test($test)  if $test->{test_type} eq 'roundtrip';
            execute_validation_test($test) if $test->{test_type} eq 'validation';

        }

    }

}

sub execute_build_test {

    my $test = shift;

    my $test_context = test_context($test);

    my $purl = eval { URI::PackageURL->new(%{$test->{input}}); };

    if ($test->{expected_failure}) {
        like($@, qr/Invalid PURL/i, $test_context);
        return;
    }

    if (!$test->{expected_failure} && $@) {
        fail("$test_context ($@)");
        return;
    }

    is($purl->to_string, $test->{expected_output}, $test_context);

}

sub execute_parse_test {

    my $test = shift;

    my $test_context = test_context($test);
    my $purl_string  = $test->{input};

    note $purl_string;

    my $purl = eval { URI::PackageURL->from_string($purl_string, 0) };

    if ($test->{expected_failure}) {
        like($@, qr/(Invalid|Malformed) PURL/i, $test_context);
        return;
    }

    if (!$test->{expected_failure} && $@) {
        fail("$test_context ($@)");
        return;
    }

    my @components = qw(type namespace name version subpath);

    foreach my $component (@components) {
        is(
            $purl->$component,
            $test->{expected_output}->{$component},
            "$test_context --> Compare '$component' component"
        );
    }

}

sub execute_roundtrip_test {

    my $test = shift;

    my $test_context = test_context($test);
    my $purl_string  = $test->{input};

    note $purl_string;

    my $purl = eval { URI::PackageURL->from_string($purl_string, 0) };

    if ($@) {
        fail("$test_context ($@)");
        return;
    }

    is($purl->to_string, $test->{expected_output}, $test_context);

}

sub execute_validation_test {

    my $test = shift;

    my $test_context = test_context($test);

    my $purl = eval { URI::PackageURL->new(%{$test->{input}}); };

    if (@{$test->{expected_messages}}) {
        like($@, qr/Invalid PURL/i, $test_context);
        diag "-- URI::PackageURL exception: $@";
        diag "-- Expected message: $_" for @{$test->{expected_messages}};
        return;
    }

    if (!@{$test->{expected_messages}} && $@) {
        fail("$test_context ($@)");
        return;
    }

    ok($purl->to_string, $test_context);

}

done_testing();
