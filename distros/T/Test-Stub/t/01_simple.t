use strict;
use warnings;
use utf8;

use Test::More;
use Test::Stub;

{
    package MyClass;
    sub new { bless {}, shift }
    sub connect { die "Not implemented yet" }
}

my $stuff = MyClass->new();
stub($stuff)->connect("OK");
is($stuff->connect(), 'OK');

done_testing;

