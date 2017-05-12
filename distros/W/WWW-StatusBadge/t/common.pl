#!/usr/bin/perl

use strict;
use warnings;

use FindBin ();
use Data::Dumper;
use WWW::StatusBadge;

sub common_class { 'WWW::StatusBadge' }

sub common_args {(
    'repo'   => 'WWW-StatusBadge.pm',
    'dist'   => 'WWW-StatusBadge',
    'user'   => 'ARivottiC',
    'branch' => 'develop',
    'for'    => 'pl',
);}

sub common_object { common_class()->new( common_args(), @_ ); }

my $pwd   = $ENV{'PWD'};
( my $bin = $FindBin::Bin ) =~ s!^$pwd/!!;
my @dirs  = split qr{/}, $bin;

my $path;
while ( my $dir = shift @dirs ) {
    $path = join( q{/}, $path || (), $dir );
    next if $dir eq 't';

    my $file = sprintf '%s/%s/common.pl', $pwd, $path;
    next unless -f $file;

    require $file;
}

1;
