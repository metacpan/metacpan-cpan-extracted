#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree mkpath);
use File::Spec;
use Time::HiRes qw(time);

my $cache_dir = '_CACHED_XS_test_cache';
remove_tree($cache_dir) if -d $cache_dir;

use_ok('XS::JIT');

# Basic caching test
{
    my $code = <<'C_CODE';
SV* cache_test_func(SV* self) {
    dTHX;
    return newSVpv("cached", 0);
}
C_CODE

    # First compile - should create cache
    my $start1 = time();
    my $ok1 = XS::JIT->compile(
        code      => $code,
        name      => 'CacheBasic::JIT_0',
        functions => { 'CacheBasic::get' => 'cache_test_func' },
        cache_dir => $cache_dir,
    );
    my $time1 = time() - $start1;
    ok($ok1, 'First compile succeeds');

    # Check that cache was created
    ok(-d $cache_dir, 'Cache directory created');
    ok(-d "$cache_dir/lib", 'Cache lib directory created');
    ok(-d "$cache_dir/lib/auto", 'Cache auto directory created');

    # Check is_cached
    ok(XS::JIT->is_cached($code, 'CacheBasic::JIT_0', $cache_dir),
       'is_cached returns true after compile');

    # Second compile - should be from cache (faster)
    my $start2 = time();
    my $ok2 = XS::JIT->compile(
        code      => $code,
        name      => 'CacheBasic::JIT_0',
        functions => { 'CacheBasic::get' => 'cache_test_func' },
        cache_dir => $cache_dir,
    );
    my $time2 = time() - $start2;
    ok($ok2, 'Second compile (from cache) succeeds');

    # Cache should be faster (at least 10x typically)
    # But we can't guarantee timing, so just check it works
    diag("First compile: ${time1}s, Second compile: ${time2}s");

    # Verify function still works
    is(CacheBasic->get, 'cached', 'Cached function returns correct value');
}

# Test that different code produces different cache entries
{
    my $code_v1 = <<'C_CODE';
SV* versioned_func_a(SV* self) {
    dTHX;
    return newSVpv("version1", 0);
}
C_CODE

    my $code_v2 = <<'C_CODE';
SV* versioned_func_b(SV* self) {
    dTHX;
    return newSVpv("version2", 0);
}
C_CODE

    # Compile v1 into one package
    my $ok1 = XS::JIT->compile(
        code      => $code_v1,
        name      => 'VersionA::JIT_0',
        functions => { 'VersionA::version' => 'versioned_func_a' },
        cache_dir => $cache_dir,
    );
    ok($ok1, 'VersionA compiles');
    is(VersionA->version, 'version1', 'VersionA returns version1');

    # Compile v2 into different package
    my $ok2 = XS::JIT->compile(
        code      => $code_v2,
        name      => 'VersionB::JIT_0',
        functions => { 'VersionB::version' => 'versioned_func_b' },
        cache_dir => $cache_dir,
    );
    ok($ok2, 'VersionB compiles');
    is(VersionB->version, 'version2', 'VersionB returns version2');

    # Both should be cached separately
    ok(XS::JIT->is_cached($code_v1, 'VersionA::JIT_0', $cache_dir),
       'VersionA is cached');
    ok(XS::JIT->is_cached($code_v2, 'VersionB::JIT_0', $cache_dir),
       'VersionB is cached');

    # Note: is_cached only checks if the module NAME exists in cache,
    # not if the specific code matches. Different code should use different names.
}

# Multiple packages with same cache directory
{
    my $code_a = <<'C_CODE';
SV* get_a(SV* self) {
    dTHX;
    return newSVpv("A", 0);
}
C_CODE

    my $code_b = <<'C_CODE';
SV* get_b(SV* self) {
    dTHX;
    return newSVpv("B", 0);
}
C_CODE

    my $code_c = <<'C_CODE';
SV* get_c(SV* self) {
    dTHX;
    return newSVpv("C", 0);
}
C_CODE

    # Compile all three
    ok(XS::JIT->compile(
        code => $code_a, name => 'MultiA::JIT_0',
        functions => { 'MultiA::get' => 'get_a' },
        cache_dir => $cache_dir,
    ), 'MultiA compiles');

    ok(XS::JIT->compile(
        code => $code_b, name => 'MultiB::JIT_0',
        functions => { 'MultiB::get' => 'get_b' },
        cache_dir => $cache_dir,
    ), 'MultiB compiles');

    ok(XS::JIT->compile(
        code => $code_c, name => 'MultiC::JIT_0',
        functions => { 'MultiC::get' => 'get_c' },
        cache_dir => $cache_dir,
    ), 'MultiC compiles');

    # All should be cached
    ok(XS::JIT->is_cached($code_a, 'MultiA::JIT_0', $cache_dir), 'MultiA is cached');
    ok(XS::JIT->is_cached($code_b, 'MultiB::JIT_0', $cache_dir), 'MultiB is cached');
    ok(XS::JIT->is_cached($code_c, 'MultiC::JIT_0', $cache_dir), 'MultiC is cached');

    # All should work correctly
    is(MultiA->get, 'A', 'MultiA returns A');
    is(MultiB->get, 'B', 'MultiB returns B');
    is(MultiC->get, 'C', 'MultiC returns C');
}

# Different cache directories
{
    my $cache_dir2 = '_CACHED_XS_test_cache2';
    remove_tree($cache_dir2) if -d $cache_dir2;

    my $code = <<'C_CODE';
SV* diff_cache_func(SV* self) {
    dTHX;
    return newSVpv("diff_cache", 0);
}
C_CODE

    ok(XS::JIT->compile(
        code => $code, name => 'DiffCache::JIT_0',
        functions => { 'DiffCache::get' => 'diff_cache_func' },
        cache_dir => $cache_dir2,
    ), 'Compile with different cache dir');

    ok(-d $cache_dir2, 'Second cache directory created');
    ok(XS::JIT->is_cached($code, 'DiffCache::JIT_0', $cache_dir2),
       'Cached in second directory');
    ok(!XS::JIT->is_cached($code, 'DiffCache::JIT_0', $cache_dir),
       'Not cached in first directory');

    is(DiffCache->get, 'diff_cache', 'Function works from second cache');

    remove_tree($cache_dir2);
}

# Test cache with force option
{
    my $code = <<'C_CODE';
SV* force_test(SV* self) {
    dTHX;
    return newSVpv("force_compiled", 0);
}
C_CODE

    # First compile
    ok(XS::JIT->compile(
        code => $code, name => 'ForceOption::JIT_0',
        functions => { 'ForceOption::get' => 'force_test' },
        cache_dir => $cache_dir,
    ), 'Initial compile');

    ok(XS::JIT->is_cached($code, 'ForceOption::JIT_0', $cache_dir),
       'Is cached');

    # Force recompile (should still work)
    # Suppress expected "Subroutine redefined" warning
    {
        no warnings 'redefine';
        ok(XS::JIT->compile(
            code => $code, name => 'ForceOption::JIT_0',
            functions => { 'ForceOption::get' => 'force_test' },
            cache_dir => $cache_dir,
            force => 1,
        ), 'Force recompile succeeds');
    }

    is(ForceOption->get, 'force_compiled', 'Function works after force recompile');
}

# Test cache directory structure
{
    my $code = <<'C_CODE';
SV* struct_test(SV* self) {
    dTHX;
    return newSViv(42);
}
C_CODE

    ok(XS::JIT->compile(
        code => $code, name => 'StructTest::JIT_0',
        functions => { 'StructTest::val' => 'struct_test' },
        cache_dir => $cache_dir,
    ), 'StructTest compiles');

    # Check directory structure
    ok(-d "$cache_dir/lib/auto/StructTest_JIT_0", 'Module directory created');

    # Check for .bundle or .so file
    my @files = glob("$cache_dir/lib/auto/StructTest_JIT_0/*");
    ok(@files > 0, 'Compiled files exist in cache');

    # Should have a .c file and compiled library
    my $has_c = grep { /\.c$/ } @files;
    ok($has_c, 'C source file cached');
}

# Test that same code + same name uses cache
{
    my $code = <<'C_CODE';
SV* same_code_func(SV* self) {
    dTHX;
    return newSViv(123);
}
C_CODE

    # First call
    ok(XS::JIT->compile(
        code => $code, name => 'SameCode::JIT_0',
        functions => { 'SameCode::val' => 'same_code_func' },
        cache_dir => $cache_dir,
    ), 'First compile of SameCode');

    ok(XS::JIT->is_cached($code, 'SameCode::JIT_0', $cache_dir),
       'SameCode is cached after first compile');

    # Second call with exact same args
    ok(XS::JIT->compile(
        code => $code, name => 'SameCode::JIT_0',
        functions => { 'SameCode::val' => 'same_code_func' },
        cache_dir => $cache_dir,
    ), 'Second compile of SameCode (should use cache)');

    is(SameCode->val, 123, 'SameCode returns correct value');
}

# Clean up
remove_tree($cache_dir) if -d $cache_dir;

done_testing();
