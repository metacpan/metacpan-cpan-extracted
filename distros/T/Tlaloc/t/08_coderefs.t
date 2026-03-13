#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Tlaloc 'all';

# Tlaloc can attach wetness magic to code references.
# Use wet($coderef) to attach magic to the CV.
#
# IMPORTANT: With PERL_MAGIC_ext, the mg_get callback does NOT automatically
# fire when the coderef is invoked. Evaporation only occurs when wetness(),
# is_wet(), or is_dry() are called. This mirrors the behavior of arrays/hashes.

# ==================================================================
# BASIC CODEREF TESTS
# ==================================================================

subtest 'wet coderef basics' => sub {
    my $code = sub { return 42 };
    ok(is_dry($code), 'coderef starts dry');
    
    wet($code);
    ok(is_wet($code), 'coderef is wet after wet()');
    is(evap_rate($code), 10, 'default evap_rate is 10');
};

subtest 'drench coderef sets wetness to 100' => sub {
    my $code = sub { "hello" };
    drench($code, 5);  # evap=5
    
    # First wetness() call decrements: 100-5=95
    is(wetness($code), 95, 'after drench, first read = 95');
    is(wetness($code), 90, 'second read = 90');
};

subtest 'coderef evap_rate can be configured' => sub {
    my $code = sub { };
    drench($code, 20);  # evap=20
    is(evap_rate($code), 20, 'evap_rate is 20');
    
    is(wetness($code), 80, 'first read: 100-20=80');
    is(wetness($code), 60, 'second read: 80-20=60');
};

subtest 'coderef evap_rate 0 means no evaporation' => sub {
    my $code = sub { };
    drench($code, 0);  # evap=0
    
    is(wetness($code), 100, 'no evaporation');
    is(wetness($code), 100, 'still 100');
    is(wetness($code), 100, 'still 100 after many reads');
};

# ==================================================================
# INVOCATION DOES NOT FIRE MG_GET
# ==================================================================

subtest 'invoking coderef does not fire mg_get' => sub {
    my $count = 0;
    my $code = sub { $count++; return $count };
    drench($code, 10);

    # Invoke multiple times
    my $r1 = $code->();
    my $r2 = $code->();
    my $r3 = $code->();
    
    # Only wetness() call decrements
    is(wetness($code), 90, 'invocations did not fire mg_get');
    is($r1, 1, 'first call returned 1');
    is($r2, 2, 'second call returned 2');
    is($r3, 3, 'third call returned 3');
};

subtest 'various call styles do not fire mg_get' => sub {
    my $code = sub { shift };
    drench($code, 10);
    
    # Different call styles
    $code->();               # arrow
    &$code();                # ampersand
    $code->('arg');          # with args
    my @results = $code->();  # list context
    
    is(wetness($code), 90, 'none of the call styles fired mg_get');
};

# ==================================================================
# CODEREF DRIES OUT
# ==================================================================

subtest 'coderef dries out after many wetness reads' => sub {
    my $code = sub { };
    wet($code);  # default 50 wetness, evap=10
    
    # 50 -> 40 -> 30 -> 20 -> 10 -> 0
    is(wetness($code), 40, 'first read: 50-10=40');
    is(wetness($code), 30, 'second read');
    is(wetness($code), 20, 'third read');
    is(wetness($code), 10, 'fourth read');
    is(wetness($code), 0, 'fifth read - dry');
    ok(is_dry($code), 'coderef is now dry');
};

subtest 'dry() removes coderef magic' => sub {
    my $code = sub { };
    wet($code);
    ok(is_wet($code), 'coderef is wet');
    
    dry($code);
    ok(is_dry($code), 'coderef is dry after dry()');
    is(wetness($code), 0, 'wetness is 0');
};

# ==================================================================
# CLOSURES
# ==================================================================

subtest 'closure wetness' => sub {
    my $counter = 0;
    my $incrementer = sub { $counter++ };
    my $getter = sub { $counter };
    
    # Wet both closures independently
    drench($incrementer, 5);
    drench($getter, 10);
    
    is(wetness($incrementer), 95, 'incrementer wetness');
    is(wetness($getter), 90, 'getter wetness');
    
    # Using them doesn't affect wetness
    $incrementer->();
    $incrementer->();
    is($getter->(), 2, 'counter is 2');
    
    is(wetness($incrementer), 90, 'incrementer still at 90 after use');
    is(wetness($getter), 80, 'getter decreased only from wetness() call');
};

subtest 'closure over wet scalar' => sub {
    my $value = "data";
    drench(\$value, 10);
    
    my $getter = sub { return $value };  # closes over $value
    drench($getter, 5);
    
    # Both have independent wetness
    is(wetness(\$value), 90, '$value wetness');
    is(wetness($getter), 95, '$getter wetness');
    
    # Calling getter reads $value (fires mg_get on $value, not on $getter)
    my $result = $getter->();
    is($result, "data", 'getter returns value');
    
    # $value should have evaporated from the read inside the closure
    is(wetness(\$value), 70, '$value evaporated from closure read + wetness()');
    is(wetness($getter), 90, '$getter only evaporated from wetness() call');
};

# ==================================================================
# MULTIPLE CODEREFS
# ==================================================================

subtest 'multiple coderefs independent wetness' => sub {
    my $a = sub { 'a' };
    my $b = sub { 'b' };
    my $c = sub { 'c' };
    
    drench($a, 5);
    drench($b, 10);
    drench($c, 20);
    
    is(wetness($a), 95, '$a wetness with evap=5');
    is(wetness($b), 90, '$b wetness with evap=10');
    is(wetness($c), 80, '$c wetness with evap=20');
    
    # They don't affect each other
    is(wetness($a), 90, '$a second read');
    is(wetness($b), 80, '$b second read');
    is(wetness($c), 60, '$c second read');
};

# ==================================================================
# EVAP_RATE CHANGES
# ==================================================================

subtest 'change evap_rate mid-stream' => sub {
    my $code = sub { };
    drench($code, 10);  # start at evap=10
    
    is(wetness($code), 90, 'first read at evap=10');
    
    evap_rate($code, 5);  # change to evap=5
    is(evap_rate($code), 5, 'evap_rate changed to 5');
    
    is(wetness($code), 85, 'next read at evap=5: 90-5=85');
};

# ==================================================================
# EDGE CASES
# ==================================================================

subtest 'anonymous sub' => sub {
    my $anon = sub { 1 };
    drench($anon, 10);
    is(wetness($anon), 90, 'anonymous sub works');
};

subtest 'named sub reference' => sub {
    sub named_sub { return "named" }
    my $ref = \&named_sub;
    
    drench($ref, 10);
    is(wetness($ref), 90, 'reference to named sub works');
    is($ref->(), "named", 'sub still works');
};

subtest 'method reference' => sub {
    package TestClass {
        sub new { bless {}, shift }
        sub method { return "method result" }
    }
    
    my $obj = TestClass->new();
    my $method_ref = $obj->can('method');
    
    drench($method_ref, 10);
    is(wetness($method_ref), 90, 'method reference works');
    is($method_ref->($obj), "method result", 'method still works');
};

done_testing;
