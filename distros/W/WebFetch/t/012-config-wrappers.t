#!/usr/bin/env perl
# t/012-config-wrappers.t - test WebFetch wrapper functions around WebFetch::Data::Config
use strict;
use warnings;
use utf8;
use Carp;
use open ':std', ':encoding(utf8)';
use IO::Capture::Stderr;
use Test::More;
use Test::Exception;
use WebFetch;

# test data
my %samples = (
    "foo" => "bar",
    "🙈"   => "see no evil",
    "🙉"   => "hear no evil",
    "🙊"   => "speak no evil",
);

# count test cases
binmode( STDOUT, ":encoding(UTF-8)" );
binmode( STDERR, ":encoding(UTF-8)" );
plan tests => 17 + int( keys %samples ) * 6;

# test debugging on or off
sub test_debug
{
    my $raw_debug  = shift;
    my $debug_flag = $raw_debug ? 1 : 0;

    # set up to capture STDERR
    my $capture = IO::Capture::Stderr->new();

    # set debugging on or off for test
    my $retval = WebFetch::debug_mode($debug_flag);
    is( $retval,                $debug_flag, "return value matches parameter ($debug_flag)" );
    is( WebFetch::debug_mode(), $debug_flag, "debug mode is $debug_flag" );
    $capture->start();
    WebFetch::debug "testing";
    $capture->stop();
    my @lines = $capture->read();

    if ($debug_flag) {
        ok( ( scalar @lines ) >= 1, "got STDERR output when debug is on" );
    } else {
        ok( ( scalar @lines ) == 0, "no STDERR output when debug is off" );
    }
    return;
}

# test reading and writing configuration data

# insert and verify samples
foreach my $key ( sort keys %samples ) {
    is( WebFetch->has_config($key), 0, "entry '$key' should not exist prior to add" );
    my $value = $samples{$key};
    lives_ok( sub { WebFetch->config( $key, $value ); }, "insert '$key' -> '$value'" );
    is( WebFetch->has_config($key), 1,      "entry '$key' should exist after add" );
    is( WebFetch->config($key),     $value, "verify '$key' -> '$value'" );
}
is_deeply(
    [ sort WebFetch->keys_config() ],
    [ sort keys %samples ],
    "verify instance keys from samples after insertion"
);

# delete and verify config entries
foreach my $key ( sort keys %samples ) {
    lives_ok( sub { WebFetch->del_config($key); }, "delete '$key'" );
    is( WebFetch->has_config($key), 0, "entry '$key' should not exist after delete" );
}
is_deeply( [ sort WebFetch->keys_config() ], [], "verify instance keys empty after deletion" );

# test debug mode flag stored in config
is( WebFetch::debug_mode(),       0, "debug mode read is initially false" );
is( WebFetch::debug_mode(1),      1, "debug mode write returns true when set to true" );
is( WebFetch::debug_mode(),       1, "debug mode read returns true after set to true" );
is( WebFetch::debug_mode(0),      0, "debug mode write returns false when set to false" );
is( WebFetch::debug_mode(),       0, "debug mode read returns false after set to false" );
is( WebFetch::debug_mode("true"), 1, "debug mode string 'true' returns true" );
is( WebFetch::debug_mode(undef),  0, "debug mode undef returns false" );
is( WebFetch::debug_mode("1"),    1, "debug mode string '1' returns true" );
is( WebFetch::debug_mode("0"),    0, "debug mode string '0' returns false" );
test_debug(0);
test_debug(1);

