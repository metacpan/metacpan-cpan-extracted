#!perl

use strict;
use warnings;

use File::Find;
use File::Util;
use Test::More;
use Test::Pod::Coverage;

my @on_disk;
my $sep = File::Util::SL();
sub collect {
    return if $File::Find::name !~ m/\.pm$/;

    my $module = $File::Find::name;
    $module =~ s#^lib/##;
    $module =~ s/\.pm//;
    $module =~ s#\Q$sep\E#::#g;
    push @on_disk, $module
}
find(\&collect, 'lib/');

pod_coverage_ok($_) for (@on_disk);

done_testing;
