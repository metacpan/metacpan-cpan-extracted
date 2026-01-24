#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);

# Clean up any previous test cache
my $cache_dir = '_CACHED_XS_test';
remove_tree($cache_dir) if -d $cache_dir;

use_ok('XS::JIT');

# Test 1: Basic module loading
can_ok('XS::JIT', 'compile');
can_ok('XS::JIT', 'is_cached');
can_ok('XS::JIT', 'generate_code');

# Test 2: Generate code (doesn't compile, just generates)
my $c_code = <<'C_CODE';
SV* test_add(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) {
        croak("test_add requires 2 arguments");
    }
    IV a = SvIV(ST(1));
    IV b = SvIV(ST(2));
    return newSViv(a + b);
}
C_CODE

my $generated = XS::JIT->generate_code(
    $c_code,
    'Test::Generated',
    { 'Test::Generated::add' => 'test_add' }
);

ok(defined $generated, 'generate_code returns defined value');
like($generated, qr/XS_EXTERNAL\(boot_Test_Generated\)/, 'Generated code contains boot function');
like($generated, qr/XS_EUPXS\(XS_Test_Generated_add\)/, 'Generated code contains wrapper function');
like($generated, qr/newXS_deffile\("Test::Generated::add"/, 'Generated code registers function');
like($generated, qr/Inline_Stack_Vars/, 'Generated code includes Inline compatibility macros');

# Test 3: Compile and use a simple function
{
    package TestMath;

    my $math_code = <<'C_CODE';
SV* math_add(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) {
        croak("math_add requires 2 arguments");
    }
    IV a = SvIV(ST(1));
    IV b = SvIV(ST(2));
    return newSViv(a + b);
}

SV* math_multiply(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) {
        croak("math_multiply requires 2 arguments");
    }
    IV a = SvIV(ST(1));
    IV b = SvIV(ST(2));
    return newSViv(a * b);
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $math_code,
        name      => 'TestMath::JIT_0',
        functions => {
            'TestMath::add'      => 'math_add',
            'TestMath::multiply' => 'math_multiply',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'compile() returns true');
    main::can_ok('TestMath', 'add');
    main::can_ok('TestMath', 'multiply');

    main::is(TestMath->add(2, 3), 5, 'add(2, 3) = 5');
    main::is(TestMath->add(10, 20), 30, 'add(10, 20) = 30');
    main::is(TestMath->multiply(4, 5), 20, 'multiply(4, 5) = 20');
    main::is(TestMath->multiply(7, 8), 56, 'multiply(7, 8) = 56');
}

# Test 4: Check caching
{
    my $simple_code = <<'C_CODE';
SV* cached_func(SV* self) {
    dTHX;
    return newSVpv("cached", 0);
}
C_CODE

    # First compile
    my $ok1 = XS::JIT->compile(
        code      => $simple_code,
        name      => 'CacheTest::JIT_0',
        functions => { 'CacheTest::get' => 'cached_func' },
        cache_dir => $cache_dir,
    );
    ok($ok1, 'First compile succeeds');

    # Should be cached now
    my $is_cached = XS::JIT->is_cached($simple_code, 'CacheTest::JIT_0', $cache_dir);
    ok($is_cached, 'is_cached returns true after compile');

    # Second compile should use cache
    my $ok2 = XS::JIT->compile(
        code      => $simple_code,
        name      => 'CacheTest::JIT_0',
        functions => { 'CacheTest::get' => 'cached_func' },
        cache_dir => $cache_dir,
    );
    ok($ok2, 'Second compile (from cache) succeeds');
}

# Test 5: Object-like usage
{
    package Person;

    my $person_code = <<'C_CODE';
SV* person_new(SV* class_sv, ...) {
    dTHX;
    dXSARGS;

    const char* classname = SvPV_nolen(class_sv);
    HV* self_hv = newHV();
    SV* self = sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));

    /* Parse name argument */
    if (items >= 3) {
        SV* key = ST(1);
        SV* val = ST(2);
        if (strEQ(SvPV_nolen(key), "name")) {
            hv_store(self_hv, "name", 4, newSVsv(val), 0);
        }
    }

    return self;
}

SV* person_name(SV* self, ...) {
    dTHX;
    dXSARGS;

    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
        croak("Not an object");
    }
    HV* hv = (HV*)SvRV(self);

    /* Setter */
    if (items > 1) {
        SV* val = ST(1);
        hv_store(hv, "name", 4, newSVsv(val), 0);
    }

    /* Getter */
    SV** valp = hv_fetch(hv, "name", 4, 0);
    if (valp && SvOK(*valp)) {
        return newSVsv(*valp);
    }
    return &PL_sv_undef;
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $person_code,
        name      => 'Person::JIT_0',
        functions => {
            'Person::new'  => 'person_new',
            'Person::name' => 'person_name',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'Person class compiles');
    main::can_ok('Person', 'new');
    main::can_ok('Person', 'name');

    my $p = Person->new(name => 'Alice');
    main::isa_ok($p, 'Person');
    main::is($p->name, 'Alice', 'Constructor sets name');

    $p->name('Bob');
    main::is($p->name, 'Bob', 'Setter changes name');
}

# Clean up
remove_tree($cache_dir) if -d $cache_dir;

done_testing();
