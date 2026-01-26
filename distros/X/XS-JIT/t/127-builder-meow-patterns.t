#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::Temp qw(tempdir);
use XS::JIT;
use XS::JIT::Builder qw(:types);

my $cache_dir = tempdir(CLEANUP => 1);

# Test type constants are exported correctly
subtest 'type constants exported' => sub {
    is(TYPE_ANY, 0, 'TYPE_ANY');
    is(TYPE_DEFINED, 1, 'TYPE_DEFINED');
    is(TYPE_INT, 2, 'TYPE_INT');
    is(TYPE_NUM, 3, 'TYPE_NUM');
    is(TYPE_STR, 4, 'TYPE_STR');
    is(TYPE_REF, 5, 'TYPE_REF');
    is(TYPE_ARRAYREF, 6, 'TYPE_ARRAYREF');
    is(TYPE_HASHREF, 7, 'TYPE_HASHREF');
    is(TYPE_CODEREF, 8, 'TYPE_CODEREF');
    is(TYPE_OBJECT, 9, 'TYPE_OBJECT');
    is(TYPE_BLESSED, 10, 'TYPE_BLESSED');
};

# Test direct AvARRAY access code generation
subtest 'av_direct generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->av_direct('slots', '(AV*)SvRV(self)');
    like($b->code, qr/SV\*\* slots = AvARRAY/, 'av_direct generates AvARRAY access');
};

subtest 'av_slot_read generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->av_slot_read('val', 'slots', 0);
    like($b->code, qr/slots\[0\] \? slots\[0\] : &PL_sv_undef/, 'av_slot_read generates slot read');
};

subtest 'av_slot_write generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->av_slot_write('slots', 0, 'new_val');
    like($b->code, qr/SvREFCNT_dec/, 'av_slot_write handles refcount');
    like($b->code, qr/SvREFCNT_inc/, 'av_slot_write increments refcount');
};

# Test lazy init code generation
subtest 'lazy_init_dor generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->lazy_init_dor('MyClass_items', 'items', 5, 'newRV_noinc((SV*)newAV())', 0);
    my $code = $b->code;
    like($code, qr/XS_EUPXS.*MyClass_items/, 'creates function');
    like($code, qr/hv_fetch.*items/, 'fetches attribute');
    like($code, qr/!SvOK\(val\)/, 'checks defined-or');
};

subtest 'lazy_init_or generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->lazy_init_or('MyClass_name', 'name', 4, 'newSVpvn("default", 7)', 0);
    my $code = $b->code;
    like($code, qr/!SvTRUE\(val\)/, 'checks or');
};

# Test setter chain
subtest 'setter_chain generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->setter_chain('set_name', 'name', 4);
    my $code = $b->code;
    like($code, qr/items < 2/, 'checks for value argument');
    like($code, qr/ST\(0\) = self/, 'returns self');
};

subtest 'setter_return_value generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->setter_return_value('set_name', 'name', 4);
    my $code = $b->code;
    like($code, qr/ST\(0\) = val/, 'returns value');
};

# Test array attribute operations
subtest 'attr_push generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_push('add_item', 'items', 5);
    my $code = $b->code;
    like($code, qr/av_push/, 'uses av_push');
    like($code, qr/for.*items/, 'loops over items');
};

subtest 'attr_pop generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_pop('pop_item', 'items', 5);
    like($b->code, qr/av_pop/, 'uses av_pop');
};

subtest 'attr_shift generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_shift('shift_item', 'items', 5);
    like($b->code, qr/av_shift/, 'uses av_shift');
};

subtest 'attr_unshift generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_unshift('prepend_item', 'items', 5);
    like($b->code, qr/av_unshift/, 'uses av_unshift');
};

subtest 'attr_count generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_count('item_count', 'items', 5);
    like($b->code, qr/av_len.*\+ 1/, 'uses av_len + 1');
};

subtest 'attr_clear generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_clear('clear_items', 'items', 5);
    like($b->code, qr/av_clear/, 'uses av_clear');
};

# Test hash attribute operations
subtest 'attr_keys generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_keys('cache_keys', 'cache', 5);
    like($b->code, qr/hv_iterinit/, 'uses hv_iterinit');
    like($b->code, qr/hv_iternext/, 'uses hv_iternext');
};

subtest 'attr_values generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_values('cache_values', 'cache', 5);
    like($b->code, qr/HeVAL/, 'uses HeVAL');
};

subtest 'attr_delete generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_delete('delete_cache', 'cache', 5);
    like($b->code, qr/hv_delete/, 'uses hv_delete');
};

subtest 'attr_hash_clear generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->attr_hash_clear('clear_cache', 'cache', 5);
    like($b->code, qr/hv_clear/, 'uses hv_clear');
};

# Test type checking
subtest 'check_value_type generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->check_value_type('ST(1)', TYPE_ARRAYREF, '', 'Expected arrayref');
    my $code = $b->code;
    like($code, qr/SvROK.*SvTYPE.*SVt_PVAV/, 'checks arrayref');
    like($code, qr/croak/, 'croaks on failure');
};

done_testing;
