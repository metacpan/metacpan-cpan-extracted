#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

use_ok('X11::Xlib::XEvent') or die;
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

subtest blank_event => sub {
    # Create a new XEvent
    my $blank_event= new_ok( 'X11::Xlib::XEvent', [], 'blank event' );
    ok( defined $blank_event->buffer, 'buffer is defined' );
    ok( length($blank_event->buffer) > 0, 'and has non-zero length' );
    is( $blank_event->type,    0,     'type=0' );
    is( $blank_event->display, undef, 'display=undef' );
    is( $blank_event->serial,  0,     'serial=0' );
    is( $blank_event->send_event, 0,  'send_event=0' );

    # Any method from other subtypes should not exist
    like( err{ $blank_event->x }, qr/locate object method "x"/, 'subtype methods don\'t exist on root event class' );
    # The XS version should also throw an exception after checking the type
    like( err{ $blank_event->_x }, qr/XEvent\.x/, 'XS refuses to fetch subtype fields' );
    
    done_testing;
};

# Test coercions:
subtest coercions => sub {
    sub lvalue_err { my $v= shift; err{ X11::Xlib::XEvent::_initialize($v) } }
    sub rvalue_err { my $v= shift; err{ X11::Xlib::XEvent::_unpack($v, my $x= {}); } }
    my $sz= X11::Xlib::XEvent::_sizeof('');

    # "rvalue" should fail if it is not: scalar, scalarref, hashref, class/subclass
    like( rvalue_err(' 'x$sz),        qr/^$/,             'scalar can be rvalue' );
    like( rvalue_err(''),             qr/length/i,        'too small cannot be rvalue' );

    like( rvalue_err(\(' 'x$sz)),     qr/^$/,             'scalar ref can be rvalue' );
    like( rvalue_err(\my $foo),       qr/coerce.*undef/,  'undef ref cannot be rvalue' );
    like( rvalue_err(\' '),           qr/length/i,        'short scalar cannot be rvalue' );

    like( rvalue_err({}),             qr/^$/,        'hashref can be rvalue' );
    like( rvalue_err(sub { +{} }),    qr/coerce/,    'coderef cannot be rvalue' );

    like( rvalue_err(bless \(' 'x$sz), 'X11::Xlib::XEvent'),       qr/^$/, 'class can be rvalue' );
    like( rvalue_err(bless \(' 'x$sz), 'X11::Xlib::XButtonEvent'), qr/^$/, 'subclass can be rvalue' );
    like( rvalue_err(bless \(' 'x$sz), 'Unrelated'),               qr/coerce.*rvalue/, 'unrelated obj cannot be rvalue' );
    like( rvalue_err(bless \(' 'x$sz), 'X11::Xlib::Struct'),       qr/coerce.*rvalue/, 'parent class cannot be rvalue' );

    # "lvalue" should fail if it is not scalar, scalarref, undef, undef ref, subclass of Struct
    like( lvalue_err(undef),          qr/^$/,             'undef can be lvalue' );
    like( lvalue_err(' 'x$sz),        qr/^$/,             'scalar can be lvalue' );
    like( lvalue_err(' '),            qr/length/,         'short scalar cannot be lvalue' );
    
    like( lvalue_err(\(' 'x$sz)),     qr/^$/,             'scalar ref can be lvalue' );
    like( lvalue_err(\(my $foo1)),    qr/^$/,             'undef ref can be lvalue' );
    like( lvalue_err(\' '),           qr/length/,         'short scalar cannot be lvalue' );

    like( lvalue_err({}),             qr/coerce.*lvalue/, 'hashref cannot be lvalue' );
    like( lvalue_err([]),             qr/coerce.*lvalue/, 'arrayref cannot be lvalue' );
    like( lvalue_err(sub {' 'x$sz}),  qr/coerce.*lvalue/, 'coderef cannot be lvalue' );

    like( lvalue_err(bless \(' 'x$sz), 'X11::Xlib::XEvent'),       qr/^$/, 'class can be lvalue' );
    like( lvalue_err(bless \(' 'x$sz), 'X11::Xlib::XButtonEvent'), qr/^$/, 'subclass can be lvalue' );
    like( lvalue_err(bless \(' 'x$sz), 'Unrelated'),               qr/coerce.*lvalue/, 'unrelated obj cannot be lvalue' );
    like( lvalue_err(bless \(' 'x$sz), 'X11::Xlib::Struct'),       qr/^$/, 'parent class can be lvalue' );
    
    done_testing;
};

subtest event_types => sub {
    # Create an XEvent with constructor arguments
    my $bp_ev;
    is( err{ $bp_ev= X11::Xlib::XEvent->new(type => 'ButtonPress'); }, '', 'create buttonpress event' );
    isa_ok( $bp_ev, 'X11::Xlib::XButtonEvent', 'event' )
        or diag explain $bp_ev;

    is( $bp_ev->type, X11::Xlib::ButtonPress(), 'button press correct type' );

    # Should be able to set button-only fields now
    is( err{ $bp_ev->x(50) }, '', 'set x on button event' );
    is( err{ $bp_ev->y(-7) }, '', 'set y on button event' );

    # Clone an event via its fields:
    my $clone= new_ok( 'X11::Xlib::XEvent', [$bp_ev->unpack], 'clone event with pack(unpack)' )
        or diag explain $bp_ev->unpack;
    is( $clone->buffer, $bp_ev->buffer, 'clone contains identical bytes' );

    is( $clone->x, 50, 'x value preserved' );
    is( $clone->y, -7, 'y value preserved' );
    
    done_testing;
};
