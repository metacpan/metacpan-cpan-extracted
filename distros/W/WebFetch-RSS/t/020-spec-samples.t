#!/usr/bin/env perl
# 020-spec-samples.t - test WebFetch::Input::RSS with examples from various versions of RSS specifications
# Copyright (c) 2022 by Ian Kluft

use strict;
use warnings;
use utf8;
use autodie;
use Readonly;
use FindBin;
use File::Temp;
use File::Basename qw(basename dirname);
use File::Compare;
use Try::Tiny;
use YAML::XS;
use WebFetch "0.15.5";
use WebFetch::Input::RSS;
use WebFetch::RSS;
use WebFetch::Output::Capture;
use Test::More;
use Data::Dumper;

# configuration & constants
Readonly::Scalar my $classname       => "WebFetch::Input::SiteNews";
Readonly::Scalar my $src_format      => "rss";
Readonly::Scalar my $dest_format     => "capture";
Readonly::Scalar my $debug_mode      => ( exists $ENV{WEBFETCH_TEST_DEBUG} and $ENV{WEBFETCH_TEST_DEBUG} ) ? 1 : 0;
Readonly::Scalar my $base_dir        => dirname($FindBin::Bin);
Readonly::Scalar my $input_dir       => $base_dir . "/t/test-inputs/020-spec-samples";
Readonly::Scalar my $tmpdir_template => "WebFetch-XXXXXXXXXX";
Readonly::Array my @rss_versions     => qw(0.9 0.91 1.0 2.0);
Readonly::Array my @test_classes     => qw(WebFetch::RSS WebFetch::Input::RSS);
Readonly::Array my @test_files       => qw(
    00-notfound-skip.xml rss-0.91-complete.xml rss-0.91-from-2.0-spec.xml rss-0.91-simple.xml
    rss-0.92-from-2.0-spec.xml rss-1.0-modules.xml rss-1.0-simple.xml rss-2.0-sample.xml
);

# count tests from entries in @test_files array
sub count_tests
{
    return ( ( int @test_classes ) * ( int @test_files ) * ( int @rss_versions ) );
}

# read and return input data from RSS/XML file
sub read_in_data
{
    my $params = shift;
    my %test_probe;
    my %Options = (
        dir           => $params->{temp_dir},
        source_format => $src_format,
        source        => "file://" . $input_dir . "/" . $params->{in},
        dest_format   => $dest_format,
        dest          => "",                                             # unused
        rss_version   => $params->{rss_version},
        debug         => $debug_mode,
    );
    try {
        $params->{class}->run( \%Options );
    } catch {

        # return exception as string
        return $_;
    };
    return [ WebFetch::Output::Capture::data_records() ];
}

# read and return expected data from YAML file
sub read_exp_data
{
    my $params = shift;
    my ($hashref) = YAML::XS::LoadFile( $input_dir . "/" . $params->{exp} );
    return $hashref;
}

# test a single RSS input file against its expected output
sub do_test_file
{
    my $params = shift;
    $params->{exp} = basename( $params->{in}, ".xml" ) . "-expected.yml";
SKIP: {
        if ( not -f $input_dir . "/" . $params->{in} ) {
            skip $params->{in} . ": test data file not found", ( int @rss_versions ) * ( int @test_classes );
        }
        if ( not -f $input_dir . "/" . $params->{exp} ) {
            skip $params->{in} . ": expected output data file not found - nothing to compare",
                ( int @rss_versions ) * ( int @test_classes );
        }
        my $exp_data = read_exp_data($params);
        foreach my $test_class (@test_classes) {
            $params->{class} = $test_class;
            foreach my $version (@rss_versions) {
                $params->{rss_version} = $version;
                my $in_data = read_in_data($params);
                my $deep_ok = is_deeply( $in_data, $exp_data->{$version},
                    $params->{class} . ": compare " . $params->{in} . " vs " . $params->{exp} . " (RSS $version)" );
                if ( $debug_mode and not $deep_ok ) {
                    print STDERR "deep compare failed: " . Dumper($in_data);
                }
            }
        }
    }
}

# run tests - compare each RSS input file to expected output
sub do_tests
{
    my $temp_dir = shift;
    foreach my $in_file ( sort @test_files ) {
        my %test_params = ( temp_dir => $temp_dir, in => $in_file );
        do_test_file( \%test_params );
    }
}

#
# mainline
#

# initialize debug mode setting and temporary directory for WebFetch
# In debug mode the temp directory is not cleaned up (deleted) so that its contents can be examined.
# For later manual cleanup, the temp dirs are easy to find named WebFetch-... in the system's temp dir location.
WebFetch::debug_mode($debug_mode);
my $temp_dir = File::Temp->newdir(
    TEMPLATE => $tmpdir_template,
    CLEANUP  => ( $debug_mode ? 0 : 1 ),
    TMPDIR   => 1
);

# run tests
plan tests => count_tests();
do_tests($temp_dir);
