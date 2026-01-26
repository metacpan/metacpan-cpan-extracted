#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);

# Helper functions to replace Test::Exception
sub throws_ok (&$;$) {
    my ($code, $regex, $name) = @_;
    my $lived = eval { $code->(); 1 };
    if ($lived) {
        fail($name // "threw exception");
        diag("Expected exception matching $regex but code succeeded");
        return 0;
    }
    like($@, $regex, $name // "threw exception");
}

sub lives_ok (&;$) {
    my ($code, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok($lived, $name // "lived");
    diag("Died: $@") unless $lived;
}

my $cache_dir = '_CACHED_XS_test_errors';
remove_tree($cache_dir) if -d $cache_dir;

use_ok('XS::JIT');

# Test compile() argument validation
{
    # Missing 'code'
    throws_ok {
        XS::JIT->compile(
            name      => 'Test::Missing',
            functions => { 'Test::Missing::foo' => 'foo' },
        );
    } qr/'code' is required/, 'Missing code throws error';

    # Missing 'name'
    throws_ok {
        XS::JIT->compile(
            code      => 'SV* foo(SV* s) { return s; }',
            functions => { 'Test::Missing::foo' => 'foo' },
        );
    } qr/'name' is required/, 'Missing name throws error';

    # Missing 'functions'
    throws_ok {
        XS::JIT->compile(
            code => 'SV* foo(SV* s) { return s; }',
            name => 'Test::Missing',
        );
    } qr/'functions' is required/, 'Missing functions throws error';

    # Invalid 'functions' (not a hashref)
    throws_ok {
        XS::JIT->compile(
            code      => 'SV* foo(SV* s) { return s; }',
            name      => 'Test::Invalid',
            functions => ['not', 'a', 'hash'],
        );
    } qr/'functions' must be a hashref/, 'Non-hashref functions throws error';

    # Empty 'functions'
    throws_ok {
        XS::JIT->compile(
            code      => 'SV* foo(SV* s) { return s; }',
            name      => 'Test::Empty',
            functions => {},
        );
    } qr/'functions' must not be empty/, 'Empty functions throws error';

    # Odd number of arguments
    throws_ok {
        XS::JIT->compile('code', 'value', 'name');
    } qr/key => value pairs/, 'Odd arguments throws error';
}

# Test generate_code() argument validation
{
    # Empty functions hash
    throws_ok {
        XS::JIT->generate_code('SV* foo(SV* s) { return s; }', 'Test::Gen', {});
    } qr/must not be empty/, 'generate_code with empty functions throws error';
}

# Test C code with croak (runtime errors from compiled code)
{
    package CroakTest;

    my $code = <<'C_CODE';
SV* must_have_arg(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) {
        croak("Argument required");
    }
    return newSVsv(ST(1));
}

SV* must_be_positive(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("Argument required");
    IV val = SvIV(ST(1));
    if (val <= 0) {
        croak("Value must be positive, got %ld", (long)val);
    }
    return newSViv(val);
}

SV* must_be_arrayref(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("Argument required");
    SV* arg = ST(1);
    if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV) {
        croak("Expected array reference");
    }
    return newSViv(av_len((AV*)SvRV(arg)) + 1);
}

SV* divide_safe(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("Two arguments required");
    NV a = SvNV(ST(1));
    NV b = SvNV(ST(2));
    if (b == 0.0) {
        croak("Cannot divide by zero");
    }
    return newSVnv(a / b);
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'CroakTest::JIT_0',
        functions => {
            'CroakTest::must_have_arg'    => 'must_have_arg',
            'CroakTest::must_be_positive' => 'must_be_positive',
            'CroakTest::must_be_arrayref' => 'must_be_arrayref',
            'CroakTest::divide_safe'      => 'divide_safe',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'CroakTest compiles');

    # Test croak messages
    main::throws_ok { CroakTest->must_have_arg() }
        qr/Argument required/, 'must_have_arg() without arg croaks';

    main::lives_ok { CroakTest->must_have_arg(42) }
        'must_have_arg(42) lives';
    main::is(CroakTest->must_have_arg(42), 42, 'must_have_arg(42) returns 42');

    main::throws_ok { CroakTest->must_be_positive(0) }
        qr/must be positive/, 'must_be_positive(0) croaks';

    main::throws_ok { CroakTest->must_be_positive(-5) }
        qr/must be positive.*-5/, 'must_be_positive(-5) croaks with value';

    main::lives_ok { CroakTest->must_be_positive(10) }
        'must_be_positive(10) lives';

    main::throws_ok { CroakTest->must_be_arrayref("not an array") }
        qr/Expected array reference/, 'must_be_arrayref("string") croaks';

    main::throws_ok { CroakTest->must_be_arrayref({}) }
        qr/Expected array reference/, 'must_be_arrayref({}) croaks';

    main::lives_ok { CroakTest->must_be_arrayref([1, 2, 3]) }
        'must_be_arrayref([1,2,3]) lives';

    main::throws_ok { CroakTest->divide_safe(10, 0) }
        qr/Cannot divide by zero/, 'divide_safe(10, 0) croaks';

    main::lives_ok { CroakTest->divide_safe(10, 2) }
        'divide_safe(10, 2) lives';
    main::is(CroakTest->divide_safe(10, 2), 5, 'divide_safe(10, 2) = 5');
}

# Test that bad C code fails compilation (syntax errors)
{
    my $bad_code = <<'C_CODE';
SV* syntax_error(SV* self, ...) {
    dTHX;
    dXSARGS;
    this is not valid C code!!!
    return &PL_sv_undef;
}
C_CODE

    # Suppress expected compilation error message
    my $ok;
    {
        local $SIG{__WARN__} = sub { };
        $ok = XS::JIT->compile(
            code      => $bad_code,
            name      => 'BadCode::JIT_0',
            functions => { 'BadCode::syntax_error' => 'syntax_error' },
            cache_dir => $cache_dir,
        );
    }

    ok(!$ok, 'Bad C code returns false from compile()');
}

# Test warning behavior
{
    package WarnTest;

    my $code = <<'C_CODE';
SV* issue_warning(SV* self, ...) {
    dTHX;
    dXSARGS;
    warn("This is a test warning");
    return &PL_sv_yes;
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'WarnTest::JIT_0',
        functions => { 'WarnTest::warn' => 'issue_warning' },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'WarnTest compiles');

    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };
    my $result = WarnTest->warn();
    main::ok($result, 'warn() returns true');
    main::like($warning, qr/test warning/, 'Warning was issued');
}

# Test edge cases with special characters in names
{
    package Special_Name_123;

    my $code = <<'C_CODE';
SV* get_value(SV* self) {
    dTHX;
    return newSViv(42);
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'Special_Name_123::JIT_0',
        functions => { 'Special_Name_123::value' => 'get_value' },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'Package with underscores and numbers compiles');
    main::is(Special_Name_123->value, 42, 'Can call function in special-named package');
}

# Clean up
remove_tree($cache_dir) if -d $cache_dir;

done_testing();
