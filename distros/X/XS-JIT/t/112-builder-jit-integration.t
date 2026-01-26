#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('XS::JIT');
use_ok('XS::JIT::Builder');

my $cache_dir = tempdir(CLEANUP => 1);

# ============================================
# Test 1: Simple function with builder
# ============================================
subtest 'Simple addition function' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('add_numbers')
      ->xs_preamble
      ->if('items != 2')
        ->croak_usage('num1, num2')
      ->endif
      ->declare('IV', 'a', 'SvIV(ST(0))')
      ->declare('IV', 'b', 'SvIV(ST(1))')
      ->declare('IV', 'result', 'a + b')
      ->line('ST(0) = sv_2mortal(newSViv(result));')
      ->xs_return(1)
      ->xs_end;
    
    my $code = $b->code;
    like($code, qr/XS_EUPXS\(add_numbers\)/, 'Generated function name');
    like($code, qr/SvIV/, 'Uses SvIV for integer conversion');
    
    # Actually compile and run it
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'BuilderTest::Add',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::Add::add' => { source => 'add_numbers', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(BuilderTest::Add::add(2, 3), 5, 'add(2, 3) = 5');
    is(BuilderTest::Add::add(-10, 7), -3, 'add(-10, 7) = -3');
    is(BuilderTest::Add::add(0, 0), 0, 'add(0, 0) = 0');
};

# ============================================
# Test 2: Read-only accessor
# ============================================
subtest 'Read-only accessor via builder' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->ro_accessor('get_name', 'name', 4);
    
    my $code = $b->code;
    like($code, qr/hv_fetch.*"name".*4/, 'Uses hv_fetch for attribute');
    like($code, qr/valp \&\& \*valp/, 'Checks for valid pointer');
    
    ok(XS::JIT->compile(
        code      => $code,
        name      => 'BuilderTest::ROAccessor',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::ROAccessor::name' => { source => 'get_name', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    # Create a test object
    my $obj = bless { name => 'Alice' }, 'BuilderTest::ROAccessor';
    is($obj->name, 'Alice', 'Getter works');
    
    # ro_accessor is read-only (no setter branch in code)
    is($obj->name, 'Alice', 'Value remains unchanged');
};

# ============================================
# Test 3: Read-write accessor
# ============================================
subtest 'Read-write accessor via builder' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->rw_accessor('get_set_age', 'age', 3);
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'BuilderTest::RWAccessor',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::RWAccessor::age' => { source => 'get_set_age', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $obj = bless { age => 25 }, 'BuilderTest::RWAccessor';
    is($obj->age, 25, 'Initial getter works');
    
    $obj->age(30);
    is($obj->age, 30, 'Setter updates value');
    
    my $ret = $obj->age(42);
    is($ret, 42, 'Setter returns new value');
};

# ============================================
# Test 4: Constructor
# ============================================
subtest 'Constructor via builder' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->constructor('new_person', [
        ['name', 4],
        ['age', 3],
        ['email', 5],
    ]);
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'BuilderTest::Constructor',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::Person::new' => { source => 'new_person', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $person = BuilderTest::Person->new({ name => 'Bob', age => 30 });
    isa_ok($person, 'BuilderTest::Person');
    is($person->{name}, 'Bob', 'name attribute set');
    is($person->{age}, 30, 'age attribute set');
    ok(!exists $person->{email}, 'email not set when not provided');
    
    my $person2 = BuilderTest::Person->new({ name => 'Alice', email => 'alice@example.com' });
    is($person2->{name}, 'Alice', 'name set');
    is($person2->{email}, 'alice@example.com', 'email set');
    ok(!exists $person2->{age}, 'age not set when not provided');
};

# ============================================
# Test 5: Multiple functions in one compilation
# ============================================
subtest 'Multiple functions' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Add multiply function
    $b->xs_function('multiply')
      ->xs_preamble
      ->declare('NV', 'a', 'SvNV(ST(0))')
      ->declare('NV', 'b', 'SvNV(ST(1))')
      ->line('ST(0) = sv_2mortal(newSVnv(a * b));')
      ->xs_return(1)
      ->xs_end
      ->blank;
    
    # Add subtract function  
    $b->xs_function('subtract')
      ->xs_preamble
      ->declare('IV', 'a', 'SvIV(ST(0))')
      ->declare('IV', 'b', 'SvIV(ST(1))')
      ->line('ST(0) = sv_2mortal(newSViv(a - b));')
      ->xs_return(1)
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'BuilderTest::Multi',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::Multi::multiply' => { source => 'multiply', is_xs_native => 1 },
            'BuilderTest::Multi::subtract' => { source => 'subtract', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(BuilderTest::Multi::multiply(3, 4), 12, 'multiply(3, 4) = 12');
    is(BuilderTest::Multi::multiply(2.5, 4), 10, 'multiply(2.5, 4) = 10');
    is(BuilderTest::Multi::subtract(10, 4), 6, 'subtract(10, 4) = 6');
};

# ============================================
# Test 6: Array operations
# ============================================
subtest 'Array operations' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('array_sum')
      ->xs_preamble
      ->if('items != 1')
        ->croak_usage('arrayref')
      ->endif
      ->declare_av('av', '(AV*)SvRV(ST(0))')
      ->declare('I32', 'len', 'av_len(av)')
      ->declare('IV', 'sum', '0')
      ->declare('I32', 'i', undef)
      ->for('i = 0', 'i <= len', 'i++')
        ->line('SV** elem = av_fetch(av, i, 0);')
        ->if('elem && SvOK(*elem)')
          ->line('sum += SvIV(*elem);')
        ->endif
      ->endloop
      ->line('ST(0) = sv_2mortal(newSViv(sum));')
      ->xs_return(1)
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'BuilderTest::Array',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::Array::sum' => { source => 'array_sum', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(BuilderTest::Array::sum([1, 2, 3, 4, 5]), 15, 'sum([1..5]) = 15');
    is(BuilderTest::Array::sum([10, -5, 3]), 8, 'sum with negatives');
    is(BuilderTest::Array::sum([]), 0, 'sum of empty array');
};

# ============================================
# Test 7: String handling
# ============================================
subtest 'String handling' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('string_length')
      ->xs_preamble
      ->declare('STRLEN', 'len', undef)
      ->line('(void)SvPV(ST(0), len);')
      ->line('ST(0) = sv_2mortal(newSViv((IV)len));')
      ->xs_return(1)
      ->xs_end
      ->blank;
    
    $b->xs_function('string_concat')
      ->xs_preamble
      ->declare('STRLEN', 'len1', undef)
      ->declare('STRLEN', 'len2', undef)
      ->line('const char* s1 = SvPV(ST(0), len1);')
      ->line('const char* s2 = SvPV(ST(1), len2);')
      ->declare_sv('result', 'newSV(len1 + len2)')
      ->line('SvPOK_on(result);')
      ->line('sv_catpvn(result, s1, len1);')
      ->line('sv_catpvn(result, s2, len2);')
      ->line('ST(0) = sv_2mortal(result);')
      ->xs_return(1)
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'BuilderTest::String',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::String::length' => { source => 'string_length', is_xs_native => 1 },
            'BuilderTest::String::concat' => { source => 'string_concat', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(BuilderTest::String::length('hello'), 5, 'length of hello');
    is(BuilderTest::String::length(''), 0, 'length of empty string');
    is(BuilderTest::String::concat('foo', 'bar'), 'foobar', 'concat works');
};

# ============================================
# Test 8: Hash iteration
# ============================================
subtest 'Hash operations' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->xs_function('hash_keys_count')
      ->xs_preamble
      ->if('!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV')
        ->croak('Expected a hash reference')
      ->endif
      ->declare_hv('hv', '(HV*)SvRV(ST(0))')
      ->declare('I32', 'count', 'HvKEYS(hv)')
      ->line('ST(0) = sv_2mortal(newSViv(count));')
      ->xs_return(1)
      ->xs_end;
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'BuilderTest::Hash',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::Hash::keys_count' => { source => 'hash_keys_count', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    is(BuilderTest::Hash::keys_count({ a => 1, b => 2, c => 3 }), 3, '3 keys');
    is(BuilderTest::Hash::keys_count({}), 0, '0 keys');
};

# ============================================
# Test 9: Full class with constructor + accessors
# ============================================
subtest 'Full class with builder' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Constructor
    $b->constructor('widget_new', [
        ['id', 2],
        ['name', 4],
        ['value', 5],
    ])->blank;
    
    # Read-only accessor for id
    $b->ro_accessor('widget_id', 'id', 2)->blank;
    
    # Read-write accessors
    $b->rw_accessor('widget_name', 'name', 4)->blank;
    $b->rw_accessor('widget_value', 'value', 5);
    
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'BuilderTest::WidgetClass',
        cache_dir => $cache_dir,
        functions => {
            'BuilderTest::Widget::new'   => { source => 'widget_new', is_xs_native => 1 },
            'BuilderTest::Widget::id'    => { source => 'widget_id', is_xs_native => 1 },
            'BuilderTest::Widget::name'  => { source => 'widget_name', is_xs_native => 1 },
            'BuilderTest::Widget::value' => { source => 'widget_value', is_xs_native => 1 },
        },
    ), 'Compile succeeded');
    
    my $widget = BuilderTest::Widget->new({ id => 42, name => 'Sprocket' });
    isa_ok($widget, 'BuilderTest::Widget');
    
    is($widget->id, 42, 'id getter');
    is($widget->name, 'Sprocket', 'name getter');
    ok(!defined $widget->value, 'value is undef');
    
    $widget->name('Gadget');
    is($widget->name, 'Gadget', 'name setter');
    
    $widget->value(100);
    is($widget->value, 100, 'value setter');
    
    # Optimized ro_accessor silently ignores setter calls
    $widget->id(99);
    is($widget->id, 42, 'id is read-only (silently ignores set)');
};

# ============================================
# Test 10: Chained builder operations
# ============================================
subtest 'Builder chaining' => sub {
    my $b = XS::JIT::Builder->new;
    
    # Test that every method returns $self for chaining
    my $result = $b
        ->comment('Start')
        ->xs_function('chained_test')
        ->xs_preamble
        ->blank
        ->declare_int('x', '5')
        ->if('x > 0')
        ->line('x = 10;')
        ->else
        ->line('x = 0;')
        ->endif
        ->xs_return_undef
        ->xs_end;
    
    is($result, $b, 'All methods return $self');
    like($b->code, qr/chained_test/, 'Code was generated');
};

# ============================================
# Test 11: Custom indent width
# ============================================
subtest 'Custom indent width' => sub {
    my $b = XS::JIT::Builder->new(indent_width => 2);
    
    $b->if('x')
      ->line('y;')
      ->endif;
    
    like($b->code, qr/^if.*\n  y;\n\}/m, 'Uses 2-space indent');
    
    my $b4 = XS::JIT::Builder->new(indent_width => 4);
    $b4->if('x')
       ->line('y;')
       ->endif;
    
    like($b4->code, qr/^if.*\n    y;\n\}/m, 'Uses 4-space indent');
};

# ============================================
# Test 12: Reset and reuse builder
# ============================================
subtest 'Reset and reuse' => sub {
    my $b = XS::JIT::Builder->new;
    
    $b->line('first');
    is($b->code, "first\n", 'First line added');
    
    $b->reset;
    is($b->code, '', 'Code cleared after reset');
    
    $b->line('second');
    is($b->code, "second\n", 'Can add code after reset');
    
    # Test that indent is reset too
    $b->reset;
    $b->indent->indent->line('deep');
    $b->reset;
    $b->line('shallow');
    is($b->code, "shallow\n", 'Indent reset too');
};

done_testing();
