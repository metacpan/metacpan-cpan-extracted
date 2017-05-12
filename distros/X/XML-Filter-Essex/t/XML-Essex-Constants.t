use Test;
BEGIN {
    # enable variable control over threading.
    $threads::VERSION ||= 1;
    $XML::Essex::Constants::threading = 1;
}

use XML::Essex::Constants;
use strict;

package Foo;

use XML::Essex::Constants qw( debugging );

package main;


my @tests = (
sub { ok 1 },
sub { ok debugging,           qr/./, "debugging" },
sub { ok threaded_essex,      1,     "threaded_essex(1)" },
sub {
    local $XML::Essex::Constants::threading = 0;
    ok threaded_essex,      0,     "threaded_essex(0)";
},
sub { ok BOD,                 qr/./, "BOD" },
sub { ok EOD,                 qr/./, "EOD" },
sub { ok SEPPUKU,             qr/./, "SEPPUKU" },
sub { ok Foo::debugging,      qr/./, "Foo::debugging" },
sub { ok !defined &Foo::BOD,  1, "! Foo::BOD" },
);

plan tests => 0+@tests;

$_->() for @tests;
