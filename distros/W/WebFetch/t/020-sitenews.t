#!/usr/bin/env perl
# t/020-sitenews.t - unit tests for WebFetch::Input::SiteNews
use strict;
use warnings;
use utf8;
use autodie;
use open ':std', ':encoding(utf8)';
use Carp qw(croak);
use Data::Dumper;
use String::Interpolate::Named qw(interpolate);
use File::Temp;
use File::Basename;
use File::Compare;
use Readonly;
use Scalar::Util qw(reftype);
use YAML::XS;
use Try::Tiny;

use Test::More;
use Test::Exception;
use WebFetch "0.15.1";
use WebFetch::Input::SiteNews;
use WebFetch::Output::Capture;

# configuration & constants
Readonly::Scalar my $classname        => "WebFetch::Input::SiteNews";
Readonly::Scalar my $service_name     => "sitenews";
Readonly::Scalar my $debug_mode       => ( exists $ENV{WEBFETCH_TEST_DEBUG} and $ENV{WEBFETCH_TEST_DEBUG} ) ? 1 : 0;
Readonly::Scalar my $input_dir        => "t/test-inputs/" . basename( $0, ".t" );
Readonly::Scalar my $yaml_file        => "test.yaml";
Readonly::Scalar my $basic_tests      => 9;
Readonly::Scalar my $file_init_tests  => 3;
Readonly::Scalar my $tmpdir_template  => "WebFetch-XXXXXXXXXX";
Readonly::Array my @dt_param_optional => qw(testing_faketime);
Readonly::Hash my %dt_param_defaults  => (
    locale    => "en-US",
    time_zone => "UTC",
);

#
# main
#

#
# test operations functions op_* used for tests specified in YAML data
#

# autopass test just does a pass() - for starter tests to check test infrastructure runs
sub op_autopass
{
    my ( $test_index, $name, $item, $news, $data ) = @_;
    pass("autopass: $name ($test_index)");    # don't test anything - just do a pass
    return;
}

# autofail test just does a fail() - called in case of an op with missing implementation function
# this may appear in test data with intentional skip to test skipping
sub op_autofail
{
    my ( $test_index, $name, $item, $news, $data ) = @_;
    fail("autofail: $name ($test_index)");    # don't test anything - just do a fail
    return;
}

# test: count data records
sub op_record_count
{
    my ( $test_index, $name, $item, $news, $data ) = @_;
    my $expected_count = $item->{count};
    my $found_count    = exists $data->{webfetch}{data}{records} ? int( @{ $data->{webfetch}{data}{records} } ) : 0;
    is( $found_count, $expected_count, "record count: $name / expect $expected_count ($test_index)" );
    return;
}

sub op_output_cmp
{
    my ( $test_index, $name, $item, $news, $data ) = @_;
    my $expected_file = $input_dir . "/" . $item->{file};
    my $test_file     = $data->{webfetch}{dir} . "/" . $item->{file};
    ok( compare( "file1", "file2" ), $item->{file} . " output comparison ($test_index)" );
    return;
}

sub op_value_recurse
{
    my ( $data_root, $depth, $path ) = @_;
    my $head_path  = shift @$path;
    my $empty_path = ( int @$path ) == 0;    # flag: true if remainder of path is empty

    # increment depth
    $depth++;
    WebFetch::debug "op_value_recurse at $head_path depth=$depth";

    # check hash
    if ( reftype($data_root) eq "HASH" ) {
        WebFetch::debug "op_value_recurse hash has " . join( " ", sort keys %$data_root );
        if ( not exists $data_root->{$head_path} ) {
            die "op_value_recurse: $head_path does not exist (depth $depth)";
        }
        if ($empty_path) {
            return $data_root->{$head_path};
        }
        return op_value_recurse( $data_root->{$head_path}, $depth, $path );
    }

    # check array
    if ( reftype($data_root) eq "ARRAY" ) {
        WebFetch::debug "op_value_recurse array has " . join( " ", sort @$data_root );
        if ( not exists $data_root->[$head_path] ) {
            die "op_value_recurse: $head_path does not exist (depth $depth)";
        }
        if ($empty_path) {
            return $data_root->[$head_path];
        }
        return op_value_recurse( $data_root->[$head_path], $depth, $path );
    }

    # error if we got here - no container object to descend into for remaining path items
    WebFetch::debug "op_value_recurse unknown: ref:" . ( ref $data_root ) . " raw:$data_root";
    die "path attempts to descend below available data at $head_path (depth $depth)";
}

sub op_value
{
    my ( $test_index, $name, $item, $news, $data ) = @_;
    my $expected_value = $item->{expected};
    my $valid_path     = ( ( exists $item->{path} ) and ( ref $item->{path} eq "ARRAY" ) );
    my $path_name      = $valid_path ? join( " ", @{ $item->{path} } ) : "";
    my $test_name      = "path[$path_name] expect '$expected_value' ($test_index)";
    WebFetch::debug "op_value path=$path_name";
    if ( not $valid_path ) {
        fail( $test_name . " - fail: no path" );
        return;
    }
    my ( $value, $error );
    try {
        $value = op_value_recurse( $data, 0, $item->{path} );
    } catch {
        $error = $_;
    };
    WebFetch::debug "op_value value=" . ( $value // "undef" ) . " error=" . ( $error // "undef" );
    if ( defined $error ) {
        fail( $test_name . " - fail: $error" );
    } else {
        is( $value, $expected_value, $test_name );
    }
    return;
}

# from test operation name get function name & ref
# returns a ref to the test operation function, or undef if it doesn't exist
sub test_op
{
    my $op_name   = shift;
    my $func_name = "op_" . $op_name;
    return main->can($func_name);
}

# count tests from data file
sub count_tests
{
    my $test_data = shift;
    my $count     = 0;
    foreach my $file ( keys %{ $test_data->{files} } ) {
        next if ref $test_data->{files}{$file} ne "ARRAY";
        $count += $file_init_tests + int( @{ $test_data->{files}{$file} } );
    }
    return $count;
}

# call WebFetch to process a SiteNews feed
# uses test_probe option of WebFetch->run() so we can inspect WebFetch::Input::SiteNews object and errors
sub capture_feed
{
    my ( $dir, $sn_file, $params ) = @_;

    # generate short and long output file names
    my $short_name = basename( $sn_file, ".webfetch" ) . "-short.out";
    my $long_name  = basename( $sn_file, ".webfetch" ) . "-long.out";

    # set up WebFetch->new() options
    WebFetch::debug "capture_feed: sn_file=$sn_file short_name=$short_name long_name=$long_name";
    my %test_probe;
    my %Options = (
        dir           => $dir,
        source_format => "sitenews",
        source        => $sn_file,
        short_path    => $short_name,
        long_path     => $long_name,
        dest          => "capture",
        dest_format   => "capture",
        test_probe    => \%test_probe,
        debug         => $debug_mode,
        ( defined $params ? %$params : () ),
    );

    # run WebFetch
    try {
        my $result = $classname->run( \%Options );
    } catch {
        WebFetch::debug "capture_feed: $classname->run() threw exception: " . Dumper($_);
        $test_probe{exception} = $_;
    };

    return \%test_probe;
}

# initialize debug mode setting and temporary directory for WebFetch
# In debug mode the temp directory is not cleaned up (deleted) so that its contents can be examined.
# For later manual cleanup, the temp dirs are easy to find named WebFetch-... in the system's temp dir location.
WebFetch::debug_mode($debug_mode);
my $temp_dir = File::Temp->newdir( TEMPLATE => $tmpdir_template, CLEANUP => ( $debug_mode ? 0 : 1 ), TMPDIR => 1 );

# locate YAML file with test data
if ( !-d $input_dir ) {
    BAIL_OUT("can't find test inputs directory: expected $input_dir");
}
my $yaml_path = $input_dir . "/" . $yaml_file;
if ( not -e $yaml_path ) {
    BAIL_OUT("can't find YAML test input $yaml_path");
}

# load test data from YAML
my @yaml_docs   = YAML::XS::LoadFile($yaml_path);
my $test_data   = $yaml_docs[0];
my $total_tests = $basic_tests + count_tests($test_data);
plan tests => $total_tests;

#
# basic tests
#

# verify WebFetch module registry settings arrived from WebFetch::Input::SiteNews
my $cmdline_reg = $classname->_module_registry("cmdline");
my $input_reg   = $classname->_module_registry("input");
is( ( grep { /^$classname$/ } @$cmdline_reg ), 1, "$classname registered as a cmdline module" );
ok( exists $input_reg->{$service_name}, "$classname registered '$service_name' as an input module" );
is( ( grep { /^$classname$/ } @{ $input_reg->{$service_name} } ),
    1, "$classname registered as input:$service_name module" );

# compare Options and Usage from WebFetch::Config with those in WebFetch::Input::SiteNews symbol table
ok( WebFetch->has_config("Options"), "Options has been set in WebFetch::Config" );
ok( WebFetch->has_config("Usage"),   "Usage has been set in WebFetch::Config" );
{
    my $config_params = $classname->_config_params();
    my $got           = $classname->config('Options');
    my $expected      = $config_params->{Options};
    for ( my $entry = 0 ; $entry < int(@$expected) ; $entry++ ) {
        my $value = $expected->[$entry];
        is( $got->[$entry], $value,
            "SiteNews Options[$entry] matches " . ( defined $value ? $value : "undef" ) . " in config" );
    }
    foreach my $field (qw(Usage num_links)) {
        is(
            $classname->config($field),
            $config_params->{$field},
            "SiteNews $field matches " . $config_params->{$field} . " in config"
        );
    }
}

#
# file-based tests
#

# run file-based tests from YAML data
my $test_index = 0;
foreach my $file ( sort keys %{ $test_data->{files} } ) {
    next if ref $test_data->{files}{$file} ne "ARRAY";

    # set parameters per test-file or from defaults: locale, time zone
    # optional parameter: testing_faketime
    my %dt_params;

    #    foreach my $dt_key (keys %dt_param_defaults) {
    #    # parameters with default values
    #    if (exists $test_data->{$dt_key}) {
    #        $dt_params{$dt_key} = $test_data->{$dt_key};
    #    } else {
    #        $dt_params{$dt_key} = $dt_param_defaults{$dt_key};
    #    }
    #}
    foreach my $dt_key (@dt_param_optional) {

        # optional parameters only used if provided in object data
        if ( exists $test_data->{$dt_key} ) {
            $dt_params{$dt_key} = $test_data->{$dt_key};
        }
    }

    # process file as a SiteNews feed
    WebFetch::debug "capture_feed($temp_dir, $input_dir/$file, "
        . ( grep { $_ . "=" . $dt_params{$_} } keys %dt_params ) . ")";
    my $capture_data = capture_feed( $temp_dir, "$input_dir/$file", \%dt_params );
    WebFetch::debug "WebFetch run: " . Dumper($capture_data);
    my @news_items = WebFetch::Output::Capture::data_records();
    WebFetch::debug "news items: " . Dumper( \@news_items );

    # per-file initial tests
    ok( not( exists $capture_data->{webfetch}{data}{exception} ), "no exceptions in $file ($test_index)" );
    $test_index++;
    is( $capture_data->{result}, 0, "success result expected from $file ($test_index)" );
    $test_index++;
    isa_ok( $capture_data->{webfetch}, $classname, "WebFetch instance ($test_index)" );
    $test_index++;

    # run tests specified in YAML
    foreach my $test_item ( @{ $test_data->{files}{$file} } ) {

        # set up control structure for interpolate() from String::Interpolate::Named
        my $interp_ctl = {
            args => {
                file  => $file,
                index => $test_index,
                %$test_item,
            }
        };
    SKIP: {
            my ( $skip_reason, $op_func );
            my $op = $test_item->{op};

            my $name = ( exists $test_item->{name} ) ? interpolate( $interp_ctl, $test_item->{name} ) : "unnamed test";
            if ( not defined $op ) {
                $skip_reason = "test operation not specified: $name ($test_index)";
            } elsif ( exists $test_item->{skip} ) {
                $skip_reason = $test_item->{skip} . ": $name ($test_index)";
            } else {
                $op_func = test_op($op);
                if ( not defined $op_func ) {
                    $skip_reason = "test operation $op not implemented: $name ($test_index)";
                }
            }
            skip $skip_reason, 1 if defined $skip_reason;

            if ( defined $op_func ) {
                $op_func->( $test_index, $name, $test_item, \@news_items, $capture_data );
            } else {
                op_autofail( $test_index, $name, $test_item, \@news_items, $capture_data );
            }
        }
        $test_index++;
    }
}
