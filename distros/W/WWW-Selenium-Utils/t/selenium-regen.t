#!/usr/bin/perl
use Test::More tests => 5;
use File::Path;
use t::Regen qw(test_setup write_config);
use lib "lib";

my $verbose = 1;

No_args: {
    like run(), qr#Must provide a directory of tests#;
}

With_testdir: {
    my $testdir = test_setup();
    my $output = run($testdir);
    like $output, qr#Adding row for bar\.html#;
    like $output, qr#Adding row for foo\.wiki#;
    like $output, qr#Generating html for \(some title\): t/tests/foo.html#;
    like $output, qr#Created new t/tests/TestSuite\.html#;
}

sub run {
    my $args = shift || '';
    my $regen = "$^X -Ilib bin/selenium-regen";
    my $cmd = "$regen $args 2>&1";
    print "Running \"$cmd\"\n";
    return qx($cmd);
}
