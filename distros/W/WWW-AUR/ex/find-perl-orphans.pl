#!/usr/bin/perl

use warnings;
use strict;
use WWW::AUR;

sub print_progress
{
    my ($current, $total) = @_;

    my $digits       = length "$total";
    my $frac_cols    = $digits * 2 + 2;
    my $percent      = $current / $total;
    my $percent_cols = 78 - 5 - $frac_cols;
    my $col_count    = int( $percent * $percent_cols );

    local $| = 1;
    printf "\x0D%s%s %3d%% %${digits}d/%d",
        ( q{#} x $col_count,
          q{=} x ($percent_cols-$col_count),
          int( $percent * 100 ),
          $current, $total );
    return;
}

my $aur  = WWW::AUR->new;
my @pkgs = sort { $a->name cmp $b->name }
    grep { $_->name =~ /\Aperl-/ } $aur->search( 'perl' );

my @orphans;
for my $i ( 0 .. $#pkgs ) {
    print_progress( $i + 1, scalar @pkgs );

    my $pkg = $pkgs[ $i ];
    push @orphans, $pkg unless defined $pkg->maintainer;
}

printf "\nFound %d orphaned perl packages.\n", scalar @orphans;

open my $fh, '>orphaned-perl' or die "open: $!";
for my $pkg ( @orphans ) {
    print $fh $pkg->name, "\n";
}
close $fh;
