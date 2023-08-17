#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

BEGIN {
    $^V ge v5.36.0 or
        plan skip_all => "builtin::created_as_* requires Perl v5.36 or later";
}

# created_as_...
{
    use builtin qw( created_as_string created_as_number );

    # some literal constants
    ok(!created_as_string(undef), 'undef created as !string');
    ok(!created_as_number(undef), 'undef created as !number');

    ok( created_as_string("abc"), 'abc created as string');
    ok(!created_as_number("abc"), 'abc created as number');

    ok(!created_as_string(123),   '123 created as !string');
    ok( created_as_number(123),   '123 created as !number');

    ok(!created_as_string(1.23),   '1.23 created as !string');
    ok( created_as_number(1.23),   '1.23 created as !number');

    ok(!created_as_string([]),    '[] created as !string');
    ok(!created_as_number([]),    '[] created as !number');

    ok(!created_as_string(builtin::true), 'true created as !string');
    ok(!created_as_number(builtin::true), 'true created as !number');

    ok(builtin::is_bool(created_as_string(0)), 'created_as_string returns bool');
    ok(builtin::is_bool(created_as_number(0)), 'created_as_number returns bool');

    # variables
    my $just_pv = "def";
    ok( created_as_string($just_pv), 'def created as string');
    ok(!created_as_number($just_pv), 'def created as number');

    my $just_iv = 456;
    ok(!created_as_string($just_iv), '456 created as string');
    ok( created_as_number($just_iv), '456 created as number');

    my $just_nv = 4.56;
    ok(!created_as_string($just_nv), '456 created as string');
    ok( created_as_number($just_nv), '456 created as number');

    # variables reused
    my $originally_pv = "1";
    my $pv_as_iv = $originally_pv + 0;
    ok( created_as_string($originally_pv), 'PV reused as IV created as string');
    ok(!created_as_number($originally_pv), 'PV reused as IV created as !number');
    ok(!created_as_string($pv_as_iv), 'New number from PV created as !string');
    ok( created_as_number($pv_as_iv), 'New number from PV created as number');

    my $originally_iv = 1;
    my $iv_as_pv = "$originally_iv";
    ok(!created_as_string($originally_iv), 'IV reused as PV created as !string');
    ok( created_as_number($originally_iv), 'IV reused as PV created as number');
    ok( created_as_string($iv_as_pv), 'New string from IV created as string');
    ok(!created_as_number($iv_as_pv), 'New string from IV created as !number');

    my $originally_nv = 1.1;
    my $nv_as_pv = "$originally_nv";
    ok(!created_as_string($originally_nv), 'NV reused as PV created as !string');
    ok( created_as_number($originally_nv), 'NV reused as PV created as number');
    ok( created_as_string($nv_as_pv), 'New string from NV created as string');
    ok(!created_as_number($nv_as_pv), 'New string from NV created as !number');

    # magic
    local $1;
    "hello" =~ m/(.*)/;
    ok(created_as_string($1), 'magic string');

    is(prototype(\&builtin::created_as_string), '$', 'created_as_string prototype');
    is(prototype(\&builtin::created_as_number), '$', 'created_as_number prototype');
}

done_testing;
