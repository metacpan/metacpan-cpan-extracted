#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);

my $cache_dir = '_CACHED_XS_test_objects';
remove_tree($cache_dir) if -d $cache_dir;

use_ok('XS::JIT');

# Test basic object with constructor and accessors
{
    package Point;

    my $code = <<'C_CODE';
SV* point_new(SV* class_sv, ...) {
    dTHX;
    dXSARGS;
    const char* classname = SvPV_nolen(class_sv);
    HV* self_hv = newHV();
    SV* self = sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));

    /* Default values */
    hv_store(self_hv, "x", 1, newSViv(0), 0);
    hv_store(self_hv, "y", 1, newSViv(0), 0);

    /* Parse key-value args */
    int i;
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            STRLEN klen;
            const char* key = SvPV(ST(i), klen);
            SV* val = ST(i + 1);
            hv_store(self_hv, key, klen, newSVsv(val), 0);
        }
    }
    return self;
}

SV* point_x(SV* self, ...) {
    dTHX;
    dXSARGS;
    HV* hv = (HV*)SvRV(self);
    if (items > 1) {
        hv_store(hv, "x", 1, newSVsv(ST(1)), 0);
    }
    SV** val = hv_fetch(hv, "x", 1, 0);
    return val ? newSVsv(*val) : &PL_sv_undef;
}

SV* point_y(SV* self, ...) {
    dTHX;
    dXSARGS;
    HV* hv = (HV*)SvRV(self);
    if (items > 1) {
        hv_store(hv, "y", 1, newSVsv(ST(1)), 0);
    }
    SV** val = hv_fetch(hv, "y", 1, 0);
    return val ? newSVsv(*val) : &PL_sv_undef;
}

SV* point_distance(SV* self, ...) {
    dTHX;
    dXSARGS;
    HV* hv = (HV*)SvRV(self);
    SV** x_sv = hv_fetch(hv, "x", 1, 0);
    SV** y_sv = hv_fetch(hv, "y", 1, 0);
    NV x = x_sv ? SvNV(*x_sv) : 0;
    NV y = y_sv ? SvNV(*y_sv) : 0;
    return newSVnv(sqrt(x*x + y*y));
}

SV* point_move(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 3) croak("move requires dx, dy");
    HV* hv = (HV*)SvRV(self);
    SV** x_sv = hv_fetch(hv, "x", 1, 0);
    SV** y_sv = hv_fetch(hv, "y", 1, 0);
    NV x = x_sv ? SvNV(*x_sv) : 0;
    NV y = y_sv ? SvNV(*y_sv) : 0;
    NV dx = SvNV(ST(1));
    NV dy = SvNV(ST(2));
    hv_store(hv, "x", 1, newSVnv(x + dx), 0);
    hv_store(hv, "y", 1, newSVnv(y + dy), 0);
    SvREFCNT_inc(self);
    return self;
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'Point::JIT_0',
        functions => {
            'Point::new'      => 'point_new',
            'Point::x'        => 'point_x',
            'Point::y'        => 'point_y',
            'Point::distance' => 'point_distance',
            'Point::move'     => 'point_move',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'Point class compiles');

    # Test constructor with defaults
    my $p1 = Point->new;
    main::isa_ok($p1, 'Point');
    main::is($p1->x, 0, 'Default x is 0');
    main::is($p1->y, 0, 'Default y is 0');

    # Test constructor with args
    my $p2 = Point->new(x => 3, y => 4);
    main::is($p2->x, 3, 'Constructor x = 3');
    main::is($p2->y, 4, 'Constructor y = 4');

    # Test distance (3-4-5 triangle)
    main::is($p2->distance, 5, 'distance from origin = 5');

    # Test setters
    $p2->x(6);
    $p2->y(8);
    main::is($p2->x, 6, 'Setter x = 6');
    main::is($p2->y, 8, 'Setter y = 8');
    main::is($p2->distance, 10, 'distance = 10');

    # Test move (returns self for chaining)
    $p1->move(1, 2)->move(2, 3);
    main::is($p1->x, 3, 'After moves, x = 3');
    main::is($p1->y, 5, 'After moves, y = 5');
}

# Test object with array storage
{
    package Stack;

    my $code = <<'C_CODE';
SV* stack_new(SV* class_sv, ...) {
    dTHX;
    const char* classname = SvPV_nolen(class_sv);
    HV* self_hv = newHV();
    SV* self = sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));

    /* Initialize empty array */
    AV* items = newAV();
    hv_store(self_hv, "items", 5, newRV_noinc((SV*)items), 0);

    return self;
}

SV* stack_push(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) croak("push requires an argument");
    HV* hv = (HV*)SvRV(self);
    SV** arr_ref = hv_fetch(hv, "items", 5, 0);
    if (!arr_ref || !SvROK(*arr_ref)) croak("Invalid stack");
    AV* arr = (AV*)SvRV(*arr_ref);
    av_push(arr, newSVsv(ST(1)));
    SvREFCNT_inc(self);
    return self;
}

SV* stack_pop(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** arr_ref = hv_fetch(hv, "items", 5, 0);
    if (!arr_ref || !SvROK(*arr_ref)) croak("Invalid stack");
    AV* arr = (AV*)SvRV(*arr_ref);
    SV* val = av_pop(arr);
    return val ? val : &PL_sv_undef;
}

SV* stack_peek(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** arr_ref = hv_fetch(hv, "items", 5, 0);
    if (!arr_ref || !SvROK(*arr_ref)) croak("Invalid stack");
    AV* arr = (AV*)SvRV(*arr_ref);
    IV len = av_len(arr);
    if (len < 0) return &PL_sv_undef;
    SV** val = av_fetch(arr, len, 0);
    return val ? newSVsv(*val) : &PL_sv_undef;
}

SV* stack_size(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** arr_ref = hv_fetch(hv, "items", 5, 0);
    if (!arr_ref || !SvROK(*arr_ref)) croak("Invalid stack");
    AV* arr = (AV*)SvRV(*arr_ref);
    return newSViv(av_len(arr) + 1);
}

SV* stack_is_empty(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** arr_ref = hv_fetch(hv, "items", 5, 0);
    if (!arr_ref || !SvROK(*arr_ref)) croak("Invalid stack");
    AV* arr = (AV*)SvRV(*arr_ref);
    return av_len(arr) < 0 ? &PL_sv_yes : &PL_sv_no;
}

SV* stack_clear(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** arr_ref = hv_fetch(hv, "items", 5, 0);
    if (!arr_ref || !SvROK(*arr_ref)) croak("Invalid stack");
    AV* arr = (AV*)SvRV(*arr_ref);
    av_clear(arr);
    SvREFCNT_inc(self);
    return self;
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'Stack::JIT_0',
        functions => {
            'Stack::new'      => 'stack_new',
            'Stack::push'     => 'stack_push',
            'Stack::pop'      => 'stack_pop',
            'Stack::peek'     => 'stack_peek',
            'Stack::size'     => 'stack_size',
            'Stack::is_empty' => 'stack_is_empty',
            'Stack::clear'    => 'stack_clear',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'Stack class compiles');

    my $s = Stack->new;
    main::isa_ok($s, 'Stack');
    main::ok($s->is_empty, 'New stack is empty');
    main::is($s->size, 0, 'New stack size is 0');

    $s->push(1)->push(2)->push(3);
    main::ok(!$s->is_empty, 'Stack not empty after push');
    main::is($s->size, 3, 'Size is 3 after 3 pushes');
    main::is($s->peek, 3, 'Peek returns 3');

    main::is($s->pop, 3, 'Pop returns 3');
    main::is($s->pop, 2, 'Pop returns 2');
    main::is($s->size, 1, 'Size is 1 after 2 pops');

    $s->clear;
    main::ok($s->is_empty, 'Stack empty after clear');
}

# Test object with callbacks/coderefs
{
    package Counter;

    my $code = <<'C_CODE';
SV* counter_new(SV* class_sv, ...) {
    dTHX;
    dXSARGS;
    const char* classname = SvPV_nolen(class_sv);
    HV* self_hv = newHV();
    SV* self = sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));

    hv_store(self_hv, "count", 5, newSViv(0), 0);

    /* Store callback if provided */
    int i;
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            STRLEN klen;
            const char* key = SvPV(ST(i), klen);
            if (strEQ(key, "on_change") && SvROK(ST(i+1))) {
                hv_store(self_hv, "on_change", 9, newSVsv(ST(i+1)), 0);
            }
        }
    }

    return self;
}

SV* counter_increment(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** count_sv = hv_fetch(hv, "count", 5, 0);
    IV count = count_sv ? SvIV(*count_sv) : 0;
    count++;
    hv_store(hv, "count", 5, newSViv(count), 0);

    /* Call callback if set */
    SV** cb_sv = hv_fetch(hv, "on_change", 9, 0);
    if (cb_sv && SvROK(*cb_sv) && SvTYPE(SvRV(*cb_sv)) == SVt_PVCV) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(count)));
        PUTBACK;
        call_sv(*cb_sv, G_DISCARD);
        FREETMPS;
        LEAVE;
    }

    return newSViv(count);
}

SV* counter_decrement(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** count_sv = hv_fetch(hv, "count", 5, 0);
    IV count = count_sv ? SvIV(*count_sv) : 0;
    count--;
    hv_store(hv, "count", 5, newSViv(count), 0);

    /* Call callback if set */
    SV** cb_sv = hv_fetch(hv, "on_change", 9, 0);
    if (cb_sv && SvROK(*cb_sv) && SvTYPE(SvRV(*cb_sv)) == SVt_PVCV) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(count)));
        PUTBACK;
        call_sv(*cb_sv, G_DISCARD);
        FREETMPS;
        LEAVE;
    }

    return newSViv(count);
}

SV* counter_get(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** count_sv = hv_fetch(hv, "count", 5, 0);
    return count_sv ? newSVsv(*count_sv) : newSViv(0);
}

SV* counter_reset(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    hv_store(hv, "count", 5, newSViv(0), 0);
    SvREFCNT_inc(self);
    return self;
}
C_CODE

    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'Counter::JIT_0',
        functions => {
            'Counter::new'       => 'counter_new',
            'Counter::increment' => 'counter_increment',
            'Counter::decrement' => 'counter_decrement',
            'Counter::get'       => 'counter_get',
            'Counter::reset'     => 'counter_reset',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'Counter class compiles');

    # Test without callback
    my $c1 = Counter->new;
    main::is($c1->get, 0, 'Initial count is 0');
    main::is($c1->increment, 1, 'After increment, count is 1');
    main::is($c1->increment, 2, 'After increment, count is 2');
    main::is($c1->decrement, 1, 'After decrement, count is 1');
    $c1->reset;
    main::is($c1->get, 0, 'After reset, count is 0');

    # Test with callback
    my @changes;
    my $c2 = Counter->new(on_change => sub { push @changes, shift });
    $c2->increment;
    $c2->increment;
    $c2->decrement;
    main::is_deeply(\@changes, [1, 2, 1], 'Callback called with correct values');
}

# Test multiple objects of same class
{
    my $code = <<'C_CODE';
SV* multi_new(SV* class_sv, ...) {
    dTHX;
    dXSARGS;
    const char* classname = SvPV_nolen(class_sv);
    HV* self_hv = newHV();
    SV* self = sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));
    if (items > 1) {
        hv_store(self_hv, "id", 2, newSVsv(ST(1)), 0);
    }
    return self;
}

SV* multi_id(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** val = hv_fetch(hv, "id", 2, 0);
    return val ? newSVsv(*val) : &PL_sv_undef;
}
C_CODE

    package MultiObj;
    my $ok = XS::JIT->compile(
        code      => $code,
        name      => 'MultiObj::JIT_0',
        functions => {
            'MultiObj::new' => 'multi_new',
            'MultiObj::id'  => 'multi_id',
        },
        cache_dir => $cache_dir,
    );

    main::ok($ok, 'MultiObj compiles');

    # Create multiple independent objects
    my @objs;
    for my $i (1..10) {
        push @objs, MultiObj->new($i);
    }

    # Verify each has correct id
    for my $i (0..9) {
        main::is($objs[$i]->id, $i + 1, "Object $i has id " . ($i + 1));
    }

    # Verify they're truly independent
    main::isnt($objs[0], $objs[1], 'Objects are different references');
}

# Clean up
remove_tree($cache_dir) if -d $cache_dir;

done_testing();
