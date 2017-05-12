#!perl

use strict;
use warnings;

use File::Find;
use File::Util;
use Test::More;
use Test::Pod::Coverage;

my @on_disk;
sub collect {
    return if $File::Find::name !~ m/\.pm$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'lib/');

my $sep = File::Util::SL();
for my $f (@on_disk) {
    $f =~ s/\.pm//;
    $f =~ s#^lib/##;
    $f =~ s#\Q$sep\E#::#g;

    pod_coverage_ok($f);
}

done_testing;
