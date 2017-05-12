#!perl

# uses package Foo and FooImporter for testing

use 5.010;
use strict 'vars';
use warnings;
use FindBin '$Bin';
use lib $Bin;

package FooImporter;

package main;
use Test::More;

test_import(
    use_stmt => 'use Foo',
    posttest => sub {
        ok(!$Foo::USER_PACKAGES{FooImporter}{version}, "version");
    },
);

test_import(
    use_stmt => 'use Foo 0.11',
    posttest => sub {
        is($Foo::USER_PACKAGES{FooImporter}{version}, "0.11");
    },
);

test_import(
    use_stmt => 'use Foo 0.11 qw(foo bar)',
    posttest => sub {
        is($Foo::USER_PACKAGES{FooImporter}{version}, "0.11");
    },
);

DONE_TESTING:
done_testing;

sub test_import {
    my %args = @_;

    subtest +($args{name} // $args{use_stmt}) => sub {

        # cleanup
        %Foo::USER_PACKAGES = ();

        $args{pretest}->() if $args{pretest};

        eval "package FooImporter; $args{use_stmt};";
        my $err = $@;
        if ($args{dies}) {
            ok($err, "dies");
            return;
        } else {
            ok(!$err, "doesn't die") or do { diag "eval err=$err"; return };
        }

        $args{posttest}->() if $args{posttest};
    };
}
