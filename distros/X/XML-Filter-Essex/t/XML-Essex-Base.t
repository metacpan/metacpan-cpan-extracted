BEGIN {
    package C0;
    $INC{"C0.pm"} = 1;

    use XML::Essex::Base;
    @ISA = qw( XML::Essex::Base );
    @EXPORT = qw( f0 );
    @EXPORT_OK = qw( f0a );

    sub f0  { "f0: "  . $_[0] }
    sub f0a  { "f0a: "  . $_[0] }
#    sub m0  { "m0: "  . ref $_[0] }
#    sub m0a { "m0a: " . ref $_[0] }

    package C1;
    $INC{"C1.pm"} = 1;

    @ISA = qw( C0 );
    @EXPORT = qw( f1 );
    @EXPORT_OK = qw( f1a );
#    @EXPORT_WRAPPER = qw( m1 );
#    @EXPORT_WRAPPER_OK = qw( m1a );

    sub f1  { "f1: "  . $_[0] }
    sub f1a  { "f1a: "  . $_[0] }
    sub m1  { "m1: " .  ref $_[0] }
    sub m1a { "m1a: " . ref $_[0] }
}

use Test;
use XML::Essex::Base;
use strict;

my @tests = (
( sub {} ) x 1, # 2 ok()s in the next one...
#( sub {} ) x 3, # 4 ok()s in the next one...

sub {
    package T0;

    use C0;

    $XML::Essex::Base::self = bless {}, "C0";

    main::ok f0( "hey" ), "f0: hey";
#    main::ok m0(), "m0: C0";
    main::ok eval { f0a() } || $@, qr/Undefined subroutine \&T0::f0a/;
#    main::ok eval { m0a() } || $@, qr/Undefined subroutine \&T0::m0a/;
},

( sub {} ) x 3, # 4 ok()s in the next one...
#( sub {} ) x 7, # 8 ok()s in the next one...

sub {
    package T1;

    use C1;

    $XML::Essex::Base::self = bless {}, "C1";

    main::ok f0( "hey" ), "f0: hey";
#    main::ok m0(), "m0: C1";
    main::ok eval { f0a() } || $@, qr/Undefined subroutine \&T1::f0a/;
#    main::ok eval { m0a() } || $@, qr/Undefined subroutine \&T1::m0a/;
    main::ok f1( "hey" ), "f1: hey";
#    main::ok m1(), "m1: C1";
    main::ok eval { f1a() } || $@, qr/Undefined subroutine \&T1::f1a/;
#    main::ok eval { m1a() } || $@, qr/Undefined subroutine \&T1::m1a/;
},

#sub {
#    package T2;
#
#    use C1 ();
#
#    $XML::Essex::Base::self = bless {}, "C1";
#
#    main::ok eval { m1() } || $@, qr/Undefined subroutine \&T2::m1/;
#},

( sub {} ) x 3,
#( sub {} ) x 7,

sub {
    package T3;

    use C1 qw( :default );

    $XML::Essex::Base::self = bless {}, "C1";

    main::ok f0( "hey" ), "f0: hey";
#    main::ok m0(), "m0: C1";
    main::ok f1( "hey" ), "f1: hey";
#    main::ok m1(), "m1: C1";
    main::ok eval { f0a() } || $@, qr/Undefined subroutine \&T3::f0a/;
#    main::ok eval { m0a() } || $@, qr/Undefined subroutine \&T3::m0a/;
    main::ok eval { f1a() } || $@, qr/Undefined subroutine \&T3::f1a/;
#    main::ok eval { m1a() } || $@, qr/Undefined subroutine \&T3::m1a/;
},

( sub {} ) x 3,
#( sub {} ) x 7,

sub {
    package T4;

    use C1 qw( :all );

    $XML::Essex::Base::self = bless {}, "C1";

    main::ok f0( "hey" ),  "f0: hey";
#    main::ok m0(),  "m0: C1";
    main::ok f1( "hey" ),  "f1: hey";
#    main::ok m1(),  "m1: C1";
    main::ok f0a( "hey" ),  "f0a: hey";
#    main::ok m0a(), "m0a: C1";
    main::ok f1a( "hey" ),  "f1a: hey";
#    main::ok m1a(), "m1a: C1";
},
);

plan tests => 0+@tests;

$_->() for @tests;
