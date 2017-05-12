#!perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;
use Version::Util qw(
                        cmp_version
                        version_eq version_ne
                        version_lt version_le version_gt version_ge
                        version_between
                        version_in
                        add_version subtract_version
                );

subtest cmp_version => sub {
    is(cmp_version("1.1.0", "1.1.0"),  0);
    is(cmp_version("1.1.2", "1.2.0"), -1);
    is(cmp_version("1.11" , "1.9.0"),  1);
};

subtest version_eq => sub {
    ok(!version_eq("1.1.0" , "1.2.0"));
    ok( version_eq("1.1.0" , "1.1.0"));
    ok(!version_eq("1.1.0" , "1.0.1"));
};

subtest version_ne => sub {
    ok( version_ne("1.1.0" , "1.2.0"));
    ok(!version_ne("1.1.0" , "1.1.0"));
    ok( version_ne("1.1.0" , "1.0.1"));
};

subtest version_gt => sub {
    ok(!version_gt("1.1.0" , "1.2.0"));
    ok(!version_gt("1.1.0" , "1.1.0"));
    ok( version_gt("1.1.0" , "1.0.1"));
};

subtest version_ge => sub {
    ok(!version_ge("1.1.0" , "1.2.0"));
    ok( version_ge("1.1.0" , "1.1.0"));
    ok( version_ge("1.1.0" , "1.0.1"));
};

subtest version_lt => sub {
    ok( version_lt("1.1.0" , "1.2.0"));
    ok(!version_lt("1.1.0" , "1.1.0"));
    ok(!version_lt("1.1.0" , "1.0.1"));
};

subtest version_le => sub {
    ok( version_le("1.1.0" , "1.2.0"));
    ok( version_le("1.1.0" , "1.1.0"));
    ok(!version_le("1.1.0" , "1.0.1"));
};

subtest version_between => sub {
    ok( version_between("1.1.0" , "1.0.1", "1.2.0"));
    ok(!version_between("1.0.0" , "1.0.1", "1.2.0"));
    ok( version_between("1.1.0" , "1.0.1", "1.2.0", "1.3.2", "1.4.0"));
    ok( version_between("1.3.11", "1.0.1", "1.2.0", "1.3.2", "1.4.0"));
    ok(!version_between("1.3.1" , "1.0.1", "1.2.0", "1.3.2", "1.4.0"));
};

subtest version_in => sub {
    ok( version_in("1.1.0" , "1.1.0", "1.1.1"));
    ok( version_in("1.1.1" , "1.1.0", "1.1.1"));
    ok(!version_in("1.2.0" , "1.1.0", "1.1.1"));
};

subtest add_version => sub {
    is(add_version("0.1", "0.1"), "0.2");
    is(add_version("0.01", "0.001"), "0.011");
    is(add_version("0.01", "0.1"), "0.11");
    is(add_version("0.9", "0.1"), "1.0");
    is(add_version("0.99", "0.1"), "1.09");
    is(add_version("1.1.0", "0.0.1"), "1.1.1");

    is(add_version("0.89", "0.01"), "0.90");
    is(add_version("0.89", "0.1"), "0.99");
    is(add_version("0", "0.1.2"), "0.1.2");
    is(add_version("9.9", "0.1.2"), "10.0.2");
};

subtest subtract_version => sub {
    is(subtract_version("0.1", "0.1"), "0.0");
    is(subtract_version("1.0", "0.1"), "0.9");
    is(subtract_version("1.0.1", "0.1"), "0.9.1");
    dies_ok { subtract_version("0.1", "0.2") };
};

DONE_TESTING:
done_testing;
