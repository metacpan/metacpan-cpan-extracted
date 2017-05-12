# $Id$

use strict;
use warnings;

use Test::More;

use File::Find;
use lib './t/lib2';

my @files = ();
find(sub { /\.pm$/ and push @files, $File::Find::name }, qw/blib/);

plan tests => @files + 1;

ok(@files, "At least one module found");

for my $module (@files) {
    $module =~ s!^blib/lib/!!;
    $module =~ s!/!::!g;
    $module =~ s/\.pm$//;
    use_ok($module);
}
