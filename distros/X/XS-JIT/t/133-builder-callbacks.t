#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder qw(:types);

# Phase 4 tests: Callbacks & Triggers
# Tests for call_sv, call_method, rw_accessor_trigger, accessor_lazy_builder, destroy_with_demolish

my $cache_dir = tempdir(CLEANUP => 1);

# Test 1-3: rw_accessor_trigger generates correct code
subtest 'rw_accessor_trigger code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->rw_accessor_trigger('TClass::name', 'name', 4, '_on_name_change');
    
    my $code = $b->code;
    
    like($code, qr/call_method\s*\(\s*"_on_name_change"/, 
        'trigger accessor calls trigger method');
    like($code, qr/hv_store\s*\(\s*hv\s*,\s*"name"/, 
        'trigger accessor stores value');
    like($code, qr/G_DISCARD/, 
        'trigger uses G_DISCARD');
};

# Test 4-6: accessor_lazy_builder generates correct code
subtest 'accessor_lazy_builder code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->accessor_lazy_builder('LClass::data', 'data', 4, '_build_data');
    
    my $code = $b->code;
    
    like($code, qr/call_method\s*\(\s*"_build_data"/, 
        'lazy builder calls builder method');
    like($code, qr/G_SCALAR/, 
        'lazy builder uses G_SCALAR to get return value');
    like($code, qr/hv_store.*data/, 
        'lazy builder caches result');
};

# Test 7-9: destroy_with_demolish generates correct code
subtest 'destroy_with_demolish code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->destroy_with_demolish('DClass::DESTROY');
    
    my $code = $b->code;
    
    like($code, qr/gv_fetchmethod_autoload.*DEMOLISH/, 
        'DESTROY checks for DEMOLISH method');
    like($code, qr/call_method\s*\(\s*"DEMOLISH"/, 
        'DESTROY calls DEMOLISH if found');
    like($code, qr/PL_dirty/, 
        'DESTROY passes global destruction flag');
};

# Test 10-12: call_sv generates correct code
subtest 'call_sv code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('CallSvClass::test_call')
      ->xs_preamble
      ->call_sv('my_callback', ['self', 'ST(1)'])
      ->line('XSRETURN_EMPTY;')
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/call_sv\s*\(\s*my_callback/, 
        'call_sv calls the coderef');
    like($code, qr/XPUSHs\s*\(\s*self\s*\)/, 
        'call_sv pushes first argument');
    like($code, qr/XPUSHs\s*\(\s*ST\(1\)\s*\)/, 
        'call_sv pushes second argument');
};

# Test 13-15: call_method generates correct code
subtest 'call_method code generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('CallMethodClass::test_method')
      ->xs_preamble
      ->call_method('on_event', 'self', ['event_name', 'event_data'])
      ->line('XSRETURN_EMPTY;')
      ->xs_end;
    
    my $code = $b->code;
    
    like($code, qr/call_method\s*\(\s*"on_event"/, 
        'call_method calls named method');
    like($code, qr/XPUSHs\s*\(\s*self\s*\)/, 
        'call_method pushes invocant');
    like($code, qr/XPUSHs\s*\(\s*event_data\s*\)/, 
        'call_method pushes arguments');
};

# Test 16-18: Functional trigger accessor integration
subtest 'rw_accessor_trigger integration' => sub {
    my $b = XS::JIT::Builder->new;
    $b->new_simple('tp_new')
      ->rw_accessor('tp_call_count', 'call_count', 10)
      ->rw_accessor_trigger('tp_name', 'name', 4, '_on_name_change');
    
    # Define the trigger method in Perl
    no strict 'refs';
    *{'TriggeredPerson::_on_name_change'} = sub {
        my ($self, $new_val) = @_;
        $self->{call_count} //= 0;
        $self->{call_count}++;
    };
    
    XS::JIT->compile(
        code      => $b->code,
        name      => 'TriggeredPerson',
        cache_dir => $cache_dir,
        functions => {
            'TriggeredPerson::new'        => { source => 'tp_new', is_xs_native => 1 },
            'TriggeredPerson::name'       => { source => 'tp_name', is_xs_native => 1 },
            'TriggeredPerson::call_count' => { source => 'tp_call_count', is_xs_native => 1 },
        },
    );
    
    my $obj = TriggeredPerson->new();
    $obj->name('Alice');
    is($obj->call_count, 1, 'trigger called once after set');
    is($obj->name, 'Alice', 'name was stored');
    
    $obj->name('Bob');
    is($obj->call_count, 2, 'trigger called again on second set');
};

done_testing;
