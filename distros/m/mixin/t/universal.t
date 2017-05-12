#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::NoWarnings;

my $Error;
{
    package My::Errors;
    use mixin::with 'UNIVERSAL';

    sub error { $Error = $_[1]; }
}

{
    package My::Stuff;
    use mixin 'My::Errors';

    sub new { bless {}, __PACKAGE__ }
}

my $stuff = My::Stuff->new;
$stuff->error("foo");
is $Error, "foo";
