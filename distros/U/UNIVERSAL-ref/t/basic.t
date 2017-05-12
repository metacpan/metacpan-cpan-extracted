#!perl
use strict;
use warnings;
use Test::More;
our $TESTS;

# # ok( not( defined undef ), 'undef is undefined' );
# # ok( defined 1,            '1 is defined' );
# # ok( defined '...',        '"..." is defined' );
# # ok( defined [], '[] is defined' );
# #
# # sub X1::defined {1}
# # sub X2::defined {0}
# # ok( defined( bless [], 'X1' ), 'X1 is defined because ->defined is true' );
# # ok( not( defined bless [], 'X2' ),
# #     'X2 is not defined because ->defined is false' );
# #
# # sub Y::defined { }
# # ok( not( defined bless [], 'Y' ),
# #     'Y is not defined because ->defined returned empty' );
# #
# # sub Z::defined { return ( 0, 0 ) }
# # ok( not( defined bless [], 'Z' ), q[Z returned (0,0) so it is undefined] );
# #
# # ok( defined( bless [], 'A' ), 'A has no ->defined method so it is fine' );
#

TODO: {

    # This test must occur before UNIVERSAL::ref is compiled.
    BEGIN { $TESTS += 1 }
    local $TODO = q[Impossible using current technology.];

    # Fixing this requires peeking at the optrees being used by yylex
    # that haven't been fed to newATTRSUB yet. Is there some ultra
    # sneaky way to get access to these ops uh... without going
    # through a CV's ROOT?

    package main;
    is( ref( bless [], 'PAST' ), 'lie', 'I even fix the past' );

    package PAST;
    use UNIVERSAL::ref;
    sub ref {'lie'}

}

{
    BEGIN { $TESTS += 1 }

    package LIAR;
    use UNIVERSAL::ref;
    sub ref {'lie'}

    package main;

    # Validate that ref() lies for us.
    is( CORE::ref( bless [], 'LIAR' ), 'lie', 'Lying 101' );
}

SKIP: {
    BEGIN { $TESTS += 1 }

    eval q[use Data::Dumper 'Dumper'];
    skip( q[Don't have Data::Dumper], 1 )
        if not defined &Dumper;

    like( Dumper( bless [], 'LIAR' ), qr/LIAR/,
        'Data::Dumper is unpeturbed' );
}

SKIP: {
    BEGIN { $TESTS += 1 }

    eval q[use Data::Dump::Streamer 'Dump'];
    skip( q[Don't have Data::Dump::Streamer], 1 )
        if not defined &Dump;

    like( Dump( bless [], 'LIAR' )->Out,
        qr/LIAR/, 'Data::Dump::Streamer is ok' );
}

{
    BEGIN { $TESTS += 3 }

    # Validate that ref() works as normal for non-hooked things.
    is( ref(''), '', 'Ordinary things are ordinary 1' );
    is( ref( [] ), 'ARRAY', 'Ordinary things are ordinary 2' );
    is( ref( bless [], 'A1' ), 'A1', 'Ordinary things are ordinary 3' );
}

{
    BEGIN { $TESTS += 2 }

    package DELUSION;
    use UNIVERSAL::ref;
    sub ref    {'blah blah blah'}
    sub myself { CORE::ref $_[0] }

    package main;
    is( ref( bless( [], 'DELUSION' ) ), 'blah blah blah', 'Self delusion 1' );
    is( bless( [], 'DELUSION' )->myself, 'DELUSION', 'Self delusion 2' );
}

{
    BEGIN { $TESTS += 2 }

    package OVERLOADED;
    sub ref { warn; 'NOT-OVERLOADED' }
    use overload 'bool' => sub () {'FALSE'};
    use UNIVERSAL::ref;

    package main;
    my $obj = bless [], 'OVERLOADED';
    ok( overload::Overloaded($obj),
        'Overloaded objects still look overloaded' );
    like(
        overload::StrVal($obj),
        qr/\A\QOVERLOADED=ARRAY(0x\E[\da-fA-F]+\)\z/,
        'Overloaded objects stringify normally too'
    );
}

BEGIN { plan('no_plan') }
