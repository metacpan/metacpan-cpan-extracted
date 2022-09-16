#!/usr/bin/env perl
# t/011-config.t - test WebFetch::Data::Config
use strict;
use warnings;
use utf8;
use Carp;
use WebFetch::Data::Config;
use open ':std', ':encoding(utf8)';
use Test::More;
use Test::Exception;

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
plan tests => 10 + int( keys %samples ) * 12;

# test instantiation
is( WebFetch::Data::Config->has_instance(), undef, "no instance before initialization" );
my $instance;
lives_ok( sub { $instance = WebFetch::Data::Config->instance(); }, 'instantiation runs without throwing exception' );
ok( ref $instance, "instance is a ref after initialization" );
isa_ok( $instance, "WebFetch::Data::Config", '$instance' );
isa_ok( $instance, "Class::Singleton",       '$instance' );
ok( $instance == WebFetch::Data::Config->instance(), "2nd call to instance() returns same instance" );

# test reading and writing configuration data

# insert and verify samples by instance methods
foreach my $key ( sort keys %samples ) {
    is( $instance->contains($key), 0, "by instance method: entry '$key' should not exist prior to add" );
    my $value = $samples{$key};
    lives_ok( sub { $instance->accessor( $key, $value ); }, "by instance method: insert '$key' -> '$value'" );
    is( $instance->contains($key), 1,      "by instance method: entry '$key' should exist after add" );
    is( $instance->accessor($key), $value, "by instance method: verify '$key' -> '$value'" );
}
is_deeply(
    [ sort keys %$instance ],
    [ sort keys %samples ],
    "by instance method: verify instance keys from samples after insertion"
);

# delete and verify config entries by instance methods
foreach my $key ( sort keys %samples ) {
    lives_ok( sub { $instance->del($key); }, "by instance method: delete '$key'" );
    is( $instance->contains($key), 0, "by instance method: entry '$key' should not exist after delete" );
}
is_deeply( [ sort keys %$instance ], [], "by instance method: verify instance keys empty after deletion" );

# insert and verify samples by class methods
foreach my $key ( sort keys %samples ) {
    is( WebFetch::Data::Config->contains($key), 0, "by class method: entry '$key' should not exist prior to add" );
    my $value = $samples{$key};
    lives_ok( sub { WebFetch::Data::Config->accessor( $key, $value ); }, "by class method: insert '$key' -> '$value'" );
    is( WebFetch::Data::Config->contains($key), 1,      "by class method: entry '$key' should exist after add" );
    is( WebFetch::Data::Config->accessor($key), $value, "by class method: verify '$key' -> '$value'" );
}
is_deeply(
    [ sort keys %{ WebFetch::Data::Config->instance() } ],
    [ sort keys %samples ],
    "by class method: verify instance keys from samples after insertion"
);

# delete and verify config entries by class methods
foreach my $key ( sort keys %samples ) {
    lives_ok( sub { WebFetch::Data::Config->del($key); }, "by class method: delete '$key'" );
    is( WebFetch::Data::Config->contains($key), 0, "by class method: entry '$key' should not exist after delete" );
}
is_deeply( [ sort keys %{ WebFetch::Data::Config->instance() } ],
    [], "by class method: verify instance keys empty after deletion" );

