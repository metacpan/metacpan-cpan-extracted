#!perl

use strict;
use warnings;

use File::Find qw(find);
use JSON::PP;
use Test::More;

require_ok('URI::VersionRange');

my $purl_tests_dir = File::Spec->catdir('t', 'vers');

BAIL_OUT('"vers" tests directory not found') if (!-d $purl_tests_dir);

find {wanted => \&execute_test, no_chdir => 1}, $purl_tests_dir;

sub test_context {
    my $test = shift;
    return sprintf '[group:%s / type:%s] %s', $test->{test_group}, $test->{test_type}, $test->{description};
}

sub execute_test {

    my $test_file = $_;

    return if -d $test_file;
    return unless $test_file =~ /\.json/;

    if (my $vers_scheme = $ENV{VERS_SCHEME}) {
        return unless ($test_file =~ /$vers_scheme/);
        diag "Test only $ENV{VERS_SCHEME} testcases";
    }

    note "--- $test_file ---";

    open my $fh, '<', $test_file or Carp::croak "Can't open file: $!";

    my $test_content = do { local $/; <$fh> };
    my $test_data    = eval { JSON::PP::decode_json($test_content) };

    BAIL_OUT("$test_file - $@") if $@;

    foreach my $test (@{$test_data->{tests}}) {

    TODO: {
            execute_containment_test($test) if $test->{test_type} eq 'containment';
            execute_validate_test($test)    if $test->{test_type} eq 'validate';
            execute_from_native_test($test) if $test->{test_type} eq 'from_native';
            execute_comparison_test($test)  if $test->{test_type} eq 'comparison';
            execute_parse_test($test)       if $test->{test_type} eq 'parse';
            execute_equality_test($test)    if $test->{test_type} eq 'equality';
        }

    }

}

sub execute_containment_test {

    my $test = shift;

    my $test_description = test_context($test);
    my $vers_string      = $test->{input}->{vers};
    my $version          = $test->{input}->{version};
    my $expected_output  = $test->{expected_output};

    my $vers = eval { URI::VersionRange->from_string($vers_string) };

    is $vers->contains($version), !!1, "$version version in range ($vers)" if $expected_output;
    is $vers->contains($version), !!0, "$version version not in range ($vers)" unless $expected_output;

}

sub execute_validate_test {

    my $test = shift;

    my $test_description = test_context($test);
    my $vers_string      = $test->{input};
    my $expected         = $test->{expected_output};

    my $got = eval { URI::VersionRange->from_string($vers_string) };

    is "$got", $expected, "$test_description ($got)";

}

sub execute_from_native_test {

    my $test = shift;

    my $test_description = test_context($test);
    my $native_range     = $test->{input}->{native_range};
    my $scheme           = $test->{input}->{scheme};
    my $expected         = $test->{expected_output};

    local $TODO = "SKIP vers:conan/" if ($expected // q{}) eq 'vers:conan/';

    my $got = eval { URI::VersionRange->from_native(scheme => $scheme, range => $native_range) };

    if ($test->{expected_failure}) {
        ok($@, "[$scheme] $test_description ($native_range)");
        return;
    }

    local $TODO = 'Skip because VERS require a range' if $expected eq 'vers:conan/';
    local $TODO = 'Skip include_prerelease=True'      if $native_range =~ 'include_prerelease=True';

    is "$got", $expected, "[$scheme] $test_description ($native_range --> $got)";

}

sub execute_comparison_test {

    my $test = shift;

    my $test_description = test_context($test);
    my $scheme           = $test->{input}->{input_scheme} || $test->{input}->{input_type};    # test schema --> v1 or v2
    my @versions         = @{$test->{input}->{versions}};
    my @expected_output  = @{$test->{expected_output}};

    # Comparators for other schemes are provided by the user (see URI::VersionRange::Version)
    local $TODO = "No comparator class for '$scheme' scheme"
        if URI::VersionRange::Version->load($scheme) eq 'URI::VersionRange::Version';

    my $encoded = eval { URI::VersionRange->new(scheme => $scheme, constraints => \@versions) };
    diag $@ if $@;

    my $got = eval { URI::VersionRange->from_string("$encoded") };
    my @got = map { $_->version } @{$got->constraints};

    is_deeply(\@got, \@expected_output, "$test_description --> $got");

}

sub execute_equality_test {

    my $test = shift;

    my $test_description = test_context($test);
    my $scheme           = $test->{input}->{input_scheme} || $test->{input}->{input_type};    # test schema --> v1 or v2
    my ($left, $right) = @{$test->{input}->{versions}};
    my $expected = $test->{expected_output};

    # Comparators for other schemes are provided by the user (see URI::VersionRange::Version)
    local $TODO = "No comparator class for '$scheme' scheme"
        if URI::VersionRange::Version->load($scheme) eq 'URI::VersionRange::Version';

    my $got = eval { URI::VersionRange::Util::version_compare($scheme, $left, $right) == 0 };
    diag $@ if $@;

    is(!!$got, !!$expected, "$test_description --> $left " . ($expected ? '==' : '!=') . " $right");

}

sub execute_parse_test {

    my $test = shift;

    # TODO: VERS canonical form validation
    my @TODO = (
        'Parsing fails when ASCII whitespace is present.',
        'Parsing fails when constraints start with a pipe.',
        'Parsing fails when constraints end with a pipe.',
        'Parsing fails when constraints are not in canonical order.',
        "Parsing fails when explicit equality comparator '=' is used.",
        "Parsing fails when double equality prefix '==' is used.",
        'Parsing fails when literal ASCII whitespace occurs in a version.',
        'Parsing fails for datetime when lowercase t and z are used.',
    );

    local $TODO = 'VERS canonical form validation' if grep { $test->{description} eq $_ } @TODO;

    my $test_description = test_context($test);
    my $vers_string      = $test->{input};

    my $got = eval { URI::VersionRange->from_string($vers_string) };

    if ($test->{expected_failure}) {
        ok($@, "$test_description ($vers_string)");
        return;
    }

    my $expected = $test->{expected_output};

    is($@, '', "$test_description ($vers_string)");

    is($got->scheme, $expected->{type}, "$test_description ($vers_string) - type");

    my @got = map { [$_->comparator, $_->version] } @{$got->constraints};
    is_deeply(\@got, $expected->{constraints}, "$test_description ($vers_string) - constraints");

}

done_testing();
