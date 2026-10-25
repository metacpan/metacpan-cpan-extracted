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

# Every module the code loads must be a declared prerequisite. The base url
# may be an https url, so without LWP::Protocol::https a fresh install fails on
# the first request.
for my $module (
  qw(HTTP::Request JSON::MaybeXS LWP::UserAgent LWP::Protocol::https Moo Safe::Isa URI)
  ) {
    ok( $requires{$module}, "$module is a declared prerequisite" );
}

done_testing;
