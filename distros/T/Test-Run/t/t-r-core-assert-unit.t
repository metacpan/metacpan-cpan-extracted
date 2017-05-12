#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use Test::Run::Obj;

my $tester = Test::Run::Obj->new(
    {
        test_files => ["t/sample-tests/simple"],
    }
);

$tester->runtests();

{
    no warnings qw(redefine);
    local *Test::Run::Core::_all_ok = sub { return 0 };

    eval
    {
        $tester->_check_for_ok();
    };

    my $err = $@;

    # TEST
    like ($err, qr{\$ok is mutually exclusive},
        "Got the right error."
    );
}
