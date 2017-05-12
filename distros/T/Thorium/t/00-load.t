#/usr/bin/env perl

use strict;

use FindBin qw($Bin);

use File::Spec;
use Test::More;

use File::Find::Rule;

BEGIN {
    my @libs = File::Find::Rule->file->name('*.pm')->in(File::Spec->catdir($Bin, '..', 'lib'));

    my @module_names = map {
        my $module = $_;
        my @s = split('/', $module);
        shift(@s) until ($s[0] =~ /^lib$/);
        shift(@s);

        $module = join('::', @s);

        $module =~ s/\.pm//;
        $module;
    } sort(@libs);

    require Test::More;

    Test::More->import(tests => scalar(@module_names));

    foreach my $module_name (@module_names) {
        use_ok($module_name) || print "Bail out!\n";
    }
}
