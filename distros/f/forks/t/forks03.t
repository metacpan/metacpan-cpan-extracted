#!/usr/local/bin/perl -w
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, ('../blib/lib', '../blib/arch');
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

use forks; # must be done _before_ Test::More which loads real threads.pm
use forks::shared;

diag( <<EOD );

The following tests check that blessing shared variables is fully transparent.

EOD

# "Unpatch" Test::More, who internally tries to disable threads
BEGIN {
    no warnings 'redefine';
    if ($] < 5.008001) {
        require forks::shared::global_filter;
        import forks::shared::global_filter 'Test::Builder';
        require Test::Builder;
        *Test::Builder::share = \&threads::shared::share;
        *Test::Builder::lock = \&threads::shared::lock;
        Test::Builder->new->reset;
    }
}

# Patch Test::Builder to add fork-thread awareness
{
    no warnings 'redefine';
    my $_sanity_check_old = \&Test::Builder::_sanity_check;
    *Test::Builder::_sanity_check = sub {
        my $self = $_[0];
        # Don't bother with an ending if this is a forked copy.  Only the parent
        # should do the ending.
        if( $self->{Original_Pid} != $$ ) {
            return;
        }
        $_sanity_check_old->(@_);
    };
}

use Test::More tests => 64;
use strict;
use warnings;

my $dummy = {};
bless ($dummy, 'simple');
ok(ref($dummy) eq 'simple', "regular blessing still works");

my ($hobj, $aobj, $sobj) : shared;

$hobj = &share({});
$aobj = &share([]);
my $sref = \do{ my $x };
share($sref);
$sobj = $sref;

threads->new(sub {
                # Bless objects
                bless $hobj, 'foo';
                bless $aobj, 'bar';
                bless $sobj, 'baz';

                # Add data to objects
                $$aobj[0] = bless(&share({}), 'yin');
                $$aobj[1] = bless(&share([]), 'yang');
                $$aobj[2] = $sobj;

                $$hobj{'hash'}   = bless(&share({}), 'yin');
                $$hobj{'array'}  = bless(&share([]), 'yang');
                $$hobj{'scalar'} = $sobj;

                $$sobj = 3;

                # Test objects in child thread
                ok(ref($hobj) eq 'foo', "hash blessing does work");
                ok(ref($aobj) eq 'bar', "array blessing does work");
                ok(ref($sobj) eq 'baz', "scalar blessing does work");
                ok($$sobj eq '3', "scalar contents okay");

                ok(ref($$aobj[0]) eq 'yin', "blessed hash in array");
                ok(ref($$aobj[1]) eq 'yang', "blessed array in array");
                ok(ref($$aobj[2]) eq 'baz', "blessed scalar in array");
                ok(${$$aobj[2]} eq '3', "blessed scalar in array contents");

                ok(ref($$hobj{'hash'}) eq 'yin', "blessed hash in hash");
                ok(ref($$hobj{'array'}) eq 'yang', "blessed array in hash");
                ok(ref($$hobj{'scalar'}) eq 'baz', "blessed scalar in hash");
                ok(${$$hobj{'scalar'}} eq '3', "blessed scalar in hash contents");

             })->join;

# Test objects in parent thread
ok(ref($hobj) eq 'foo', "hash blessing does work");
ok(ref($aobj) eq 'bar', "array blessing does work");
ok(ref($sobj) eq 'baz', "scalar blessing does work");
ok($$sobj eq '3', "scalar contents okay");

ok(ref($$aobj[0]) eq 'yin', "blessed hash in array");
ok(ref($$aobj[1]) eq 'yang', "blessed array in array");
ok(ref($$aobj[2]) eq 'baz', "blessed scalar in array");
ok(${$$aobj[2]} eq '3', "blessed scalar in array contents");

ok(ref($$hobj{'hash'}) eq 'yin', "blessed hash in hash");
ok(ref($$hobj{'array'}) eq 'yang', "blessed array in hash");
ok(ref($$hobj{'scalar'}) eq 'baz', "blessed scalar in hash");
ok(${$$hobj{'scalar'}} eq '3', "blessed scalar in hash contents");

threads->new(sub {
                # Rebless objects
                bless $hobj, 'oof';
                bless $aobj, 'rab';
                bless $sobj, 'zab';

                my $data = $$aobj[0];
                bless $data, 'niy';
                $$aobj[0] = $data;
                $data = $$aobj[1];
                bless $data, 'gnay';
                $$aobj[1] = $data;

                $data = $$hobj{'hash'};
                bless $data, 'niy';
                $$hobj{'hash'} = $data;
                $data = $$hobj{'array'};
                bless $data, 'gnay';
                $$hobj{'array'} = $data;

                $$sobj = 'test';
             })->join;

# Test reblessing
ok(ref($hobj) eq 'oof', "hash reblessing does work");
ok(ref($aobj) eq 'rab', "array reblessing does work");
ok(ref($sobj) eq 'zab', "scalar reblessing does work");
ok($$sobj eq 'test', "scalar contents okay");

ok(ref($$aobj[0]) eq 'niy', "reblessed hash in array");
ok(ref($$aobj[1]) eq 'gnay', "reblessed array in array");
ok(ref($$aobj[2]) eq 'zab', "reblessed scalar in array");
ok(${$$aobj[2]} eq 'test', "reblessed scalar in array contents");

ok(ref($$hobj{'hash'}) eq 'niy', "reblessed hash in hash");
ok(ref($$hobj{'array'}) eq 'gnay', "reblessed array in hash");
ok(ref($$hobj{'scalar'}) eq 'zab', "reblessed scalar in hash");
ok(${$$hobj{'scalar'}} eq 'test', "reblessed scalar in hash contents");
#36

ok(UNIVERSAL::isa($hobj, 'oof') == 1, "hash object with UNIVERSAL::isa does work");
ok(UNIVERSAL::isa($aobj, 'rab') == 1, "array object with UNIVERSAL::isa does work");
ok(UNIVERSAL::isa($sobj, 'zab') == 1, "scalar object with UNIVERSAL::isa does work");
ok(UNIVERSAL::isa($$aobj[0], 'niy') == 1, "hash in array object with UNIVERSAL::isa does work");
ok(UNIVERSAL::isa($$aobj[1], 'gnay') == 1, "array in array object with UNIVERSAL::isa does work");
ok(UNIVERSAL::isa($$aobj[2], 'zab') == 1, "scalar in array object with UNIVERSAL::isa does work");
ok(UNIVERSAL::isa($$hobj{'hash'}, 'niy') == 1, "hash in hash object with UNIVERSAL::isa does work");
ok(UNIVERSAL::isa($$hobj{'array'}, 'gnay') == 1, "array in hash object with UNIVERSAL::isa does work");
ok(UNIVERSAL::isa($$hobj{'scalar'}, 'zab') == 1, "scalar in hash object with UNIVERSAL::isa does work");

ok($hobj->isa('oof') == 1, "hash object method isa() does work");
ok($aobj->isa('rab') == 1, "array object method isa() does work");
ok($sobj->isa('zab') == 1, "scalar object method isa() does work");
ok($$aobj[0]->isa('niy') == 1, "hash in array object method isa() does work");
ok($$aobj[1]->isa('gnay') == 1, "array in array object method isa() does work");
ok($$aobj[2]->isa('zab') == 1, "scalar in array object method isa() does work");
ok($$hobj{'hash'}->isa('niy') == 1, "hash in hash object method isa() does work");
ok($$hobj{'array'}->isa('gnay') == 1, "array in hash object method isa() does work");
ok($$hobj{'scalar'}->isa('zab') == 1, "scalar in hash object method isa() does work");

sub oof::test_me { return "yes1"; }
sub rab::test_me { return "yes2"; }
sub zab::test_me { return "yes3"; }
sub niy::test_me { return "yes4"; }
sub gnay::test_me { return "yes5"; }

ok($hobj->test_me eq "yes1", "hash object method does work");
ok($aobj->test_me eq "yes2", "array object method does work");
ok($sobj->test_me eq "yes3", "scalar object method does work");
ok($$aobj[0]->test_me eq "yes4", "hash in array object method does work");
ok($$aobj[1]->test_me eq "yes5", "array in array object method does work");
ok($$aobj[2]->test_me eq "yes3", "scalar in array object method does work");
ok($$hobj{'hash'}->test_me eq "yes4", "hash in hash object method does work");
ok($$hobj{'array'}->test_me eq "yes5", "array in hash object method does work");
ok($$hobj{'scalar'}->test_me eq "yes3", "scalar in hash object method does work");

1;
