#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use FindBin;
use Test::More;

my $cpanfile = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, 'cpanfile' );

plan skip_all => 'cpanfile is not part of the distribution' unless -f $cpanfile;

open my $fh, '<', $cpanfile or die "cannot read $cpanfile: $!";
my %requires;
while ( my $line = <$fh> ) {
    next unless $line =~ /^\s*requires\s+'([^']+)'/;
    $requires{ $1 } = 1;
}
close $fh;

# The runtime modules the distribution loads. Both API base URLs are HTTPS
# only, so LWP::Protocol::https belongs to the transport chain: without it
# LWP::UserAgent answers 501 and no request ever reaches the API.
my @runtime = qw(
    Moo
    MooX::Cmd
    MooX::Options
    LWP::UserAgent
    LWP::Protocol::https
    JSON::MaybeXS
    URI
    HTTP::Request
    namespace::clean
    Log::Any
    Path::Tiny
);

my @test = qw(
    Test::More
    Log::Any::Test
);

for my $module ( @runtime ) {
    ok( $requires{$module}, "$module is a declared prerequisite" );
}

for my $module ( @test ) {
    ok( $requires{$module}, "$module is a declared test prerequisite" );
}

done_testing;
