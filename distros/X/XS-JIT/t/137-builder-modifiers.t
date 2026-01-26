#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder qw(:types);

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test 1: wrap_before - code generation
# ============================================
subtest 'wrap_before - code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_before('wrapped', 'Pkg::orig', 'Pkg::before');
    
    my $code = $b->code;
    like($code, qr/get_sv\s*\(\s*"Pkg::before"/, 'fetches before CV');
    like($code, qr/get_sv\s*\(\s*"Pkg::orig"/, 'fetches original CV');
    like($code, qr/call_sv\s*\(\s*before_cv,\s*G_DISCARD\)/, 'calls before with G_DISCARD');
    like($code, qr/call_sv\s*\(\s*orig_cv/, 'calls original');
};

# ============================================
# Test 2: wrap_after - code generation
# ============================================
subtest 'wrap_after - code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_after('wrapped', 'Pkg::orig', 'Pkg::after');
    
    my $code = $b->code;
    like($code, qr/get_sv\s*\(\s*"Pkg::orig"/, 'fetches original CV');
    like($code, qr/get_sv\s*\(\s*"Pkg::after"/, 'fetches after CV');
    like($code, qr/call_sv\s*\(\s*after_cv,\s*G_DISCARD\)/, 'calls after with G_DISCARD');
    like($code, qr/saved_results/, 'saves original results');
};

# ============================================
# Test 3: wrap_around - code generation
# ============================================
subtest 'wrap_around - code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_around('wrapped', 'Pkg::orig', 'Pkg::around');
    
    my $code = $b->code;
    like($code, qr/get_sv\s*\(\s*"Pkg::around"/, 'fetches around CV');
    like($code, qr/get_sv\s*\(\s*"Pkg::orig"/, 'fetches original CV');
    like($code, qr/PUSHs\s*\(\s*orig_cv\s*\)/, 'pushes orig as first arg');
    like($code, qr/call_sv\s*\(\s*around_cv/, 'calls around');
};

# ============================================
# Test 4: wrap_before - integration
# ============================================
subtest 'wrap_before - integration' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_before('wrapped_add', 'Test::WrapBefore::_orig', 'Test::WrapBefore::_before');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapBefore',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapBefore::add' => { source => 'wrapped_add', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    # Set up the original and before CVs
    my @call_log;
    $Test::WrapBefore::_orig = sub {
        my ($x, $y) = @_;
        push @call_log, "orig($x, $y)";
        return $x + $y;
    };
    $Test::WrapBefore::_before = sub {
        my ($x, $y) = @_;
        push @call_log, "before($x, $y)";
    };
    
    my $result = Test::WrapBefore::add(3, 4);
    
    is($result, 7, 'original return value preserved');
    is_deeply(\@call_log, ['before(3, 4)', 'orig(3, 4)'], 'before called first');
};

# ============================================
# Test 5: wrap_before - before receives same args
# ============================================
subtest 'wrap_before - args passed correctly' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_before('wrapped_greet', 'Test::WrapBeforeArgs::_orig', 'Test::WrapBeforeArgs::_before');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapBeforeArgs',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapBeforeArgs::greet' => { source => 'wrapped_greet', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my @before_args;
    $Test::WrapBeforeArgs::_orig = sub { "Hello, $_[0]!" };
    $Test::WrapBeforeArgs::_before = sub { @before_args = @_ };
    
    my $result = Test::WrapBeforeArgs::greet("World");
    
    is($result, "Hello, World!", 'result correct');
    is_deeply(\@before_args, ["World"], 'before received same args');
};

# ============================================
# Test 6: wrap_after - integration
# ============================================
subtest 'wrap_after - integration' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_after('wrapped_save', 'Test::WrapAfter::_orig', 'Test::WrapAfter::_after');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapAfter',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapAfter::save' => { source => 'wrapped_save', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my @call_log;
    $Test::WrapAfter::_orig = sub {
        push @call_log, "orig(@_)";
        return "saved";
    };
    $Test::WrapAfter::_after = sub {
        push @call_log, "after(@_)";
    };
    
    my $result = Test::WrapAfter::save("data");
    
    is($result, "saved", 'original return value preserved');
    is_deeply(\@call_log, ['orig(data)', 'after(data)'], 'after called after orig');
};

# ============================================
# Test 7: wrap_after - after can access object state
# ============================================
subtest 'wrap_after - object state access' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_after('wrapped_inc', 'Test::WrapAfterObj::_orig', 'Test::WrapAfterObj::_after');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapAfterObj',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapAfterObj::inc' => { source => 'wrapped_inc', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    $Test::WrapAfterObj::_orig = sub {
        my $self = shift;
        $self->{count}++;
        return $self->{count};
    };
    $Test::WrapAfterObj::_after = sub {
        my $self = shift;
        $self->{after_saw} = $self->{count};
    };
    
    my $obj = bless { count => 0 }, 'Test::WrapAfterObj';
    my $result = Test::WrapAfterObj::inc($obj);
    
    is($result, 1, 'original return value correct');
    is($obj->{after_saw}, 1, 'after saw updated state');
};

# ============================================
# Test 8: wrap_around - integration
# ============================================
subtest 'wrap_around - integration' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_around('wrapped_compute', 'Test::WrapAround::_orig', 'Test::WrapAround::_around');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapAround',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapAround::compute' => { source => 'wrapped_compute', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    $Test::WrapAround::_orig = sub {
        my ($x, $y) = @_;
        return $x * $y;
    };
    $Test::WrapAround::_around = sub {
        my ($orig, $x, $y) = @_;
        return $orig->($x, $y) + 1;  # Add 1 to result
    };
    
    my $result = Test::WrapAround::compute(3, 4);
    
    is($result, 13, 'around modified return value (3*4 + 1)');
};

# ============================================
# Test 9: wrap_around - can modify args
# ============================================
subtest 'wrap_around - modify args' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_around('wrapped_double', 'Test::WrapAroundArgs::_orig', 'Test::WrapAroundArgs::_around');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapAroundArgs',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapAroundArgs::double_it' => { source => 'wrapped_double', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    $Test::WrapAroundArgs::_orig = sub {
        my ($x) = @_;
        return $x;
    };
    $Test::WrapAroundArgs::_around = sub {
        my ($orig, $x) = @_;
        return $orig->($x * 2);  # Double the input
    };
    
    my $result = Test::WrapAroundArgs::double_it(5);
    
    is($result, 10, 'around modified args (5 * 2)');
};

# ============================================
# Test 10: wrap_around - can skip original
# ============================================
subtest 'wrap_around - skip original' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_around('wrapped_cached', 'Test::WrapAroundSkip::_orig', 'Test::WrapAroundSkip::_around');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapAroundSkip',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapAroundSkip::get' => { source => 'wrapped_cached', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $orig_called = 0;
    $Test::WrapAroundSkip::_orig = sub {
        $orig_called++;
        return "from_db";
    };
    $Test::WrapAroundSkip::_around = sub {
        my ($orig, $key) = @_;
        return "cached";  # Skip original entirely
    };
    
    my $result = Test::WrapAroundSkip::get("key");
    
    is($result, "cached", 'around returned cached value');
    is($orig_called, 0, 'original was not called');
};

# ============================================
# Test 11: wrap_before - list context
# ============================================
subtest 'wrap_before - list context' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_before('wrapped_list', 'Test::WrapBeforeList::_orig', 'Test::WrapBeforeList::_before');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapBeforeList',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapBeforeList::get_list' => { source => 'wrapped_list', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    $Test::WrapBeforeList::_orig = sub { return (1, 2, 3) };
    $Test::WrapBeforeList::_before = sub { };
    
    my @result = Test::WrapBeforeList::get_list();
    
    is_deeply(\@result, [1, 2, 3], 'list context preserves return values');
};

# ============================================
# Test 12: wrap_after - list context
# ============================================
subtest 'wrap_after - list context' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_after('wrapped_list', 'Test::WrapAfterList::_orig', 'Test::WrapAfterList::_after');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapAfterList',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapAfterList::get_list' => { source => 'wrapped_list', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    $Test::WrapAfterList::_orig = sub { return ('a', 'b', 'c') };
    $Test::WrapAfterList::_after = sub { };
    
    my @result = Test::WrapAfterList::get_list();
    
    is_deeply(\@result, ['a', 'b', 'c'], 'list context preserves return values');
};

# ============================================
# Test 13: wrap_around - list context
# ============================================
subtest 'wrap_around - list context' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_around('wrapped_list', 'Test::WrapAroundList::_orig', 'Test::WrapAroundList::_around');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapAroundList',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapAroundList::get_list' => { source => 'wrapped_list', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    $Test::WrapAroundList::_orig = sub { return (10, 20, 30) };
    $Test::WrapAroundList::_around = sub {
        my ($orig) = @_;
        my @result = $orig->();
        return map { $_ * 2 } @result;
    };
    
    my @result = Test::WrapAroundList::get_list();
    
    is_deeply(\@result, [20, 40, 60], 'around can modify list return');
};

# ============================================
# Test 14: wrap_before - void context
# ============================================
subtest 'wrap_before - void context' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_before('wrapped_void', 'Test::WrapBeforeVoid::_orig', 'Test::WrapBeforeVoid::_before');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapBeforeVoid',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapBeforeVoid::do_it' => { source => 'wrapped_void', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $effect = 0;
    $Test::WrapBeforeVoid::_orig = sub { $effect = 1 };
    $Test::WrapBeforeVoid::_before = sub { };
    
    Test::WrapBeforeVoid::do_it();
    
    is($effect, 1, 'original executed in void context');
};

# ============================================
# Test 15: wrap_around - receives $orig
# ============================================
subtest 'wrap_around - receives orig coderef' => sub {
    my $b = XS::JIT::Builder->new;
    $b->wrap_around('wrapped_check', 'Test::WrapAroundOrig::_orig', 'Test::WrapAroundOrig::_around');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::WrapAroundOrig',
        cache_dir => $cache_dir,
        functions => {
            'Test::WrapAroundOrig::check' => { source => 'wrapped_check', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    $Test::WrapAroundOrig::_orig = sub { return "original" };
    my $received_orig;
    $Test::WrapAroundOrig::_around = sub {
        $received_orig = shift;
        return $received_orig->();
    };
    
    my $result = Test::WrapAroundOrig::check();
    
    is(ref $received_orig, 'CODE', 'around received coderef');
    is($result, 'original', 'calling through orig works');
};

# ============================================
# Test 16: multiple wraps on same original
# ============================================
subtest 'multiple wraps - before and after' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Create both wrapped versions
    $b->wrap_before('inner_wrapped', 'Test::MultiWrap::_orig', 'Test::MultiWrap::_before');
    $b->wrap_after('outer_wrapped', 'Test::MultiWrap::_inner', 'Test::MultiWrap::_after');
    
    my $code = $b->code;
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'Test::MultiWrap',
        cache_dir => $cache_dir,
        functions => {
            'Test::MultiWrap::inner' => { source => 'inner_wrapped', is_xs_native => 1 },
            'Test::MultiWrap::outer' => { source => 'outer_wrapped', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my @log;
    $Test::MultiWrap::_orig = sub { push @log, "orig"; return "result" };
    $Test::MultiWrap::_before = sub { push @log, "before" };
    $Test::MultiWrap::_inner = \&Test::MultiWrap::inner;
    $Test::MultiWrap::_after = sub { push @log, "after" };
    
    my $result = Test::MultiWrap::outer();
    
    is($result, "result", 'return value preserved through chain');
    is_deeply(\@log, ['before', 'orig', 'after'], 'execution order correct');
};

done_testing();
