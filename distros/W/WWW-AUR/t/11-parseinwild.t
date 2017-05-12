#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More;

use WWW::AUR::PKGBUILD;

opendir my $pbdh, 't/PKGBUILDs' or die "opendir: $!";
for my $filename ( grep { -f "t/PKGBUILDs/$_" } readdir $pbdh ) {
    open my $pbfh, '<', "t/PKGBUILDs/$filename" or die "open: $!";
    my $pb = eval { WWW::AUR::PKGBUILD->new( $pbfh ) };
    ok !$@, "Parse ${filename}'s funky PKGBUILD";
    close $pbfh;
}
closedir $pbdh;

done_testing;
