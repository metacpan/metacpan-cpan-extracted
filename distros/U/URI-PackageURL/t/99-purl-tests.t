#!perl

use strict;
use warnings;

use Test::More;
use File::Find qw(find);
use File::Spec;

require_ok('URI::PackageURL');

my $purl_tests_dir = File::Spec->catdir('t', 'purl');

BAIL_OUT('"purl" tests directory not found') if (!-d $purl_tests_dir);

find {wanted => \&execute_test, no_chdir => 1}, $purl_tests_dir;

sub test_context {
    my $test = shift;
    return sprintf '[group:%s / type:%s] %s', $test->{test_group}, $test->{test_type}, $test->{description};
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

            local $TODO = 'Upstream inconsistency: uppercase qualifier key (see "types/gem-test.json" parse test)'
                if ($test->{description} eq 'maven pom reference' && $test->{test_type} eq 'parse');

            execute_parse_test($test)    if $test->{test_type} eq 'parse';
            execute_build_test($test)    if $test->{test_type} eq 'build';
            execute_validate_test($test) if $test->{test_type} eq 'validate';

        }

    }

}

sub execute_build_test {

    my $test = shift;

    my $test_context = test_context($test);

    my $purl = eval { URI::PackageURL->new(%{$test->{input}}) };

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
    my $validate     = $test->{test_group} eq 'recommended' ? 0 : 1;

    note $purl_string;

    my $purl = eval { URI::PackageURL->from_string($purl_string, validate => $validate) };

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

    if (%{$purl->qualifiers}) {

        my $got_qualifiers      = $purl->qualifiers;
        my $expected_qualifiers = $test->{expected_output}->{qualifiers};

        if (defined $got_qualifiers->{checksum}) {
            $got_qualifiers->{checksum} = join ',', @{$got_qualifiers->{checksum}};
        }

        is_deeply($got_qualifiers, $expected_qualifiers, "$test_context --> Compare 'qualifiers' component");

    }

}

sub execute_validate_test {

    my $test = shift;

    my $test_context = test_context($test);
    my $purl_string  = $test->{input};
    my $validate     = $test->{test_group} eq 'recommended' ? 0 : 1;

    note $purl_string;

    my $purl = eval { URI::PackageURL->from_string($purl_string, validate => $validate) };

    if ($test->{expected_failure}) {
        diag "-- URI::PackageURL exception: $@";
        diag "-- Expected message:", $test->{expected_message};
        like($@, qr/(Invalid|Malformed) PURL/i, $test_context);
        return;
    }

    if (!$test->{expected_failure} && $@) {
        fail("$test_context ($@)");
        return;
    }

    is($purl->to_string, $test->{expected_output}, $test_context);

}

done_testing();
