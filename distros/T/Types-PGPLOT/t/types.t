#! perl

use Test2::V0;
use Test2::API qw( context );

use Test::TypeTiny;

use Types::PGPLOT -types;
use List::Util qw[ pairs ];

sub rand_case {

    join( '', map { rand > 0.5 ? uc $_ : lc $_ } split //, $_[0] );
}

sub test_coercions {

    my ( $Type, %Map ) = @_;

    my $ctx = context();


    is( $Type->coerce( rand_case $_->[0] ), $_->[1], "coerce $_->[0]" )
      for pairs %Map;

    $ctx->release;
}

subtest Angle => sub {

    should_pass( $_, Angle ) for -275, -275, -360, +360;

    should_fail( $_, Angle ) for -435, +435;
};

subtest ArrowHeadFillStyle => sub {

    my $Type = ArrowHeadFillStyle;

    should_pass( $_, $Type ) for 1, 2;

    test_coercions( $Type, %Types::PGPLOT::Map_AHFS );

};

subtest CharacterHeight => sub {

    should_pass( 1,   CharacterHeight );
    should_pass( 1.5, CharacterHeight );

    should_fail( 0,  CharacterHeight );
    should_fail( -1, CharacterHeight );
};

subtest Color => sub {

    my $Type = Color;

    should_pass( $_, $Type ) for 0 .. 255;
    should_fail( $_, $Type ) for 0.5, -1, 299;

    test_coercions( $Type, %Types::PGPLOT::Map_Color );

};

subtest FillAreaStyle => sub {

    my $Type = FillAreaStyle;

    should_pass( $_, $Type ) for 1 .. 4;
    should_fail( $_, $Type ) for 0.5, -1, 0, 8;

    test_coercions( $Type, %Types::PGPLOT::Map_FillAreaStyle );
};

subtest Font => sub {

    my $Type = Font;

    should_pass( $_, $Type ) for 1 .. 4;
    should_fail( $_, $Type ) for 0.5, -1, 0, 8;

    test_coercions( $Type, %Types::PGPLOT::Map_Font );

};

subtest LineStyle => sub {

    my $Type = LineStyle;

    should_pass( $_, $Type ) for 1 .. 5;
    should_fail( $_, $Type ) for 0.5, -1, 0, 8;

    test_coercions( $Type, %Types::PGPLOT::Map_LineStyle );

};

subtest LineWidth => sub {

    my $Type = LineWidth;

    should_pass( $_, $Type ) for 1 .. 201;
    should_fail( $_, $Type ) for -1, 0, 0.5, 202;

};

subtest PlotUnits => sub {

    my $Type = PlotUnits;

    should_pass( $_, $Type ) for 0 .. 4;
    should_fail( $_, $Type ) for 0.5, -1, 8;

    test_coercions( $Type, %Types::PGPLOT::Map_PlotUnits );

};

subtest Symbol => sub {

    my $Type = Symbol;
    should_pass( $_, $Type ) for -8 .. 255;

    should_fail( $_, $Type ) for -32, 256;

    test_coercions( $Type, %Types::PGPLOT::Map_SymbolName );

    for my $ord ( 32 .. 127 ) {
        my $char = chr( $ord );

        next if $char =~ /^[0-9]$/;    # something that looks
                                       # like an integer will get treated
                                       # as an integer, not as a character

        is( $Type->coerce( $char ),  $ord, "coerce $char" );
        is( $Type->coerce( \$char ), $ord, "coerce \\$char" );
    }

};

subtest XAxisOptions => sub {

    my $Type = XAxisOptions;

    should_pass( 'ABCGILNPMTS12', $Type );
    should_fail( 'AACGILNPMTS12', $Type );

};

subtest YAxisOptions => sub {

    my $Type = YAxisOptions;

    should_pass( 'ABCGILNPMTSV12', $Type );
    should_fail( 'AACGILNPMTSV12', $Type );

};

done_testing;

1;

