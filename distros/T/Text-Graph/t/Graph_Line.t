#!/usr/bin/perl
# Test building Line graphs

use strict;
use warnings;
use Test::More tests => 19;
use Data::Dumper;

use Text::Graph;
use Text::Graph::DataSet;

sub test_dataset
{
    return Text::Graph::DataSet->new(
        [ 1 .. 4, 10, 20, 5 ],
        [
            qw/Monday Tuesday Wednesday Thursday
                Friday Saturday Sunday/
        ]
    );
}

{
    my $label = 'Default Lines';
    my $graph = Text::Graph->new( 'Line' );

    my @expected = ( '', '*', ' *', '  *', '        *', '                  *', '   *', );

    my $out = $graph->make_lines( test_dataset() );

    is_deeply( $out, \@expected, $label )
        or note explain $out;
}

{
    my $label = 'Default Line graph';
    my $graph = Text::Graph->new( 'Line' );

    my @expected = (
        'Monday    :',
        'Tuesday   :*',
        'Wednesday : *',
        'Thursday  :  *',
        'Friday    :        *',
        'Saturday  :                  *',
        'Sunday    :   *',
    );

    my $dset = test_dataset();
    my $out = $graph->make_labelled_lines( $dset );

    is_deeply( $out, \@expected, "$label: lines" )
        or note explain $out;

    my $expected = join( "\n", @expected, '' );
    is( $graph->to_string( $dset ), $expected, "$label: full graph" );
}

{
    my $label = 'Not a dataset';
    my $graph = Text::Graph->new( 'Line' );
    my $out = $graph->make_labelled_lines( [ 1 .. 4, 10, 20, 5 ] );

    my @unlabelledExpected =
        ( ' :', ' :*', ' : *', ' :  *', ' :        *', ' :                  *', ' :   *', );

    is_deeply( $out, \@unlabelledExpected, "$label: lines" )
        or note explain $out;

    my $expected = join( "\n", @unlabelledExpected, '' );

    $out = $graph->to_string( [ 1 .. 4, 10, 20, 5 ] );

    is( $out, $expected, "$label: full graph" );
}

{
    my $label = 'right-justified labels';
    my $expected = <<'EOF';
   Monday :
  Tuesday :*
Wednesday : *
 Thursday :  *
   Friday :        *
 Saturday :                  *
   Sunday :   *
EOF

    my $graph = Text::Graph->new( 'Line', right => 1 );
    is( $graph->to_string( test_dataset() ), $expected, $label );
}

{
    my $label    = 'Different label separator';
    my $expected = <<'EOF';
Monday   |
Tuesday  |*
Wednesday| *
Thursday |  *
Friday   |        *
Saturday |                  *
Sunday   |   *
EOF

    my $graph = Text::Graph->new( 'Line', separator => '|' );
    is( $graph->to_string( test_dataset() ), $expected, $label );
}

{
    my $label = 'showing values';
    # test showing values
    my $expected = <<'EOF';
Monday    :                     (1)
Tuesday   :*                    (2)
Wednesday : *                   (3)
Thursday  :  *                  (4)
Friday    :        *            (10)
Saturday  :                  *  (20)
Sunday    :   *                 (5)
EOF

    my $graph = Text::Graph->new( 'Line', showval => 1 );
    is( $graph->to_string( test_dataset() ), $expected, $label );
}

{
    my $label = 'Different Marker';
    my $expected = <<'EOF';
Monday    :
Tuesday   :+
Wednesday : +
Thursday  :  +
Friday    :        +
Saturday  :                  +
Sunday    :   +
EOF

    my $graph = Text::Graph->new( 'Line', marker => '+' );
    is( $graph->to_string( test_dataset() ), $expected, $label );
}

{
    my $label = 'Different Fill';
    my $expected = <<'EOF';
Monday    :
Tuesday   :*
Wednesday :.*
Thursday  :..*
Friday    :........*
Saturday  :..................*
Sunday    :...*
EOF

    my $graph = Text::Graph->new( 'Line', fill => '.' );
    is( $graph->to_string( test_dataset() ), $expected, $label );
}

{
    my $label ='Min/Max values supplied';
    my $expected = <<'EOF';
Monday    :*
Tuesday   : *
Wednesday :  *
Thursday  :   *
Friday    :         *
Saturday  :              *
Sunday    :    *
EOF

    my $graph = Text::Graph->new( 'Line', minval => 0, maxval => 15 );
    is( $graph->to_string( test_dataset() ), $expected, $label );
}

{
    my $label = 'Limit Max length';
    my $expected = <<'EOF';
Monday    :*
Tuesday   :*
Wednesday : *
Thursday  : *
Friday    :    *
Saturday  :         *
Sunday    :  *
EOF

    my $graph = Text::Graph->new( 'Line', minval => 0, maxlen => 10 );
    is( $graph->to_string( test_dataset() ), $expected, $label );
}

{
    my $label = 'Supplied maxval only';
    my $expected = <<'EOF';
Monday    :
Tuesday   :*
Wednesday : *
Thursday  :  *
Friday    :        *
Saturday  :                  *
Sunday    :   *
EOF

    my $graph = Text::Graph->new( 'Line', maxval => 20 );
    is( $graph->to_string( test_dataset() ), $expected, $label );
}

{
    my $label ='Log graph';
    my $expected = <<'EOF';
Monday    :    *
Tuesday   :*
Wednesday : *
Thursday  : *
Friday    :  *
Saturday  :   *
Sunday    :
EOF

    my $dset = Text::Graph::DataSet->new(
        [ 1000, 20, 30, 40, 100, 200, 5 ],
        [
            qw/Monday Tuesday Wednesday Thursday
                Friday Saturday Sunday/
        ]
    );
    my $graph = Text::Graph->new( 'Line', log => 1 );
    is( $graph->to_string( $dset ), $expected, $label );
}

{
    my $label ='Log graph, with values';
    my $expected = <<'EOF';
Monday    :    *  (1000)
Tuesday   :*      (20)
Wednesday : *     (30)
Thursday  : *     (40)
Friday    :  *    (100)
Saturday  :   *   (200)
Sunday    :       (5)
EOF

    my $dset = Text::Graph::DataSet->new(
        [ 1000, 20, 30, 40, 100, 200, 5 ],
        [
            qw/Monday Tuesday Wednesday Thursday
                Friday Saturday Sunday/
        ]
    );
    my $graph = Text::Graph->new( 'Line', log => 1, showval => 1 );
    is( $graph->to_string( $dset ), $expected, $label );
}

{
    my $label ='Log graph, with 0 minval';
    my $expected = <<'EOF';
Monday    :      *
Tuesday   :  *
Wednesday :  *
Thursday  :   *
Friday    :    *
Saturday  :    *
Sunday    : *
EOF

    my $dset = Text::Graph::DataSet->new(
        [ 1000, 20, 30, 40, 100, 200, 5 ],
        [
            qw/Monday Tuesday Wednesday Thursday
                Friday Saturday Sunday/
        ]
    );
    my $graph = Text::Graph->new( 'Line', log => 1, minval => 0 );
    is( $graph->to_string( $dset ), $expected, $label );
}

{
    my $label ='Log graph, with 1 minval';
    my $expected = <<'EOF';
Monday    :      *
Tuesday   :  *
Wednesday :  *
Thursday  :   *
Friday    :    *
Saturday  :    *
Sunday    : *
EOF

    my $dset = Text::Graph::DataSet->new(
        [ 1000, 20, 30, 40, 100, 200, 5 ],
        [
            qw/Monday Tuesday Wednesday Thursday
                Friday Saturday Sunday/
        ]
    );
    my $graph = Text::Graph->new( 'Line', log => 1, minval => 1 );
    is( $graph->to_string( $dset ), $expected, $label );
}

{
    my $label = 'Log graph, with min and max';
    my $expected = <<'EOF';
Monday    :      *
Tuesday   :  *
Wednesday :  *
Thursday  :   *
Friday    :    *
Saturday  :    *
Sunday    : *
EOF

    my $dset = Text::Graph::DataSet->new(
        [ 1000, 20, 30, 40, 100, 200, 5 ],
        [
            qw/Monday Tuesday Wednesday Thursday
                Friday Saturday Sunday/
        ]
    );
    my $graph = Text::Graph->new( 'Line', log => 1, minval => 1, maxval => 1000 );
    is( $graph->to_string( $dset ), $expected, $label );
}

{
    my $label = 'Clip both ends of range';
    my $expected = <<'EOF';
Monday    :
Tuesday   :
Wednesday :*
Thursday  : *
Friday    :       *
Saturday  :         *
Sunday    :  *
EOF

    my $dset = Text::Graph::DataSet->new(
        [ 1 .. 4, 10, 20, 5 ],
        [
            qw/Monday Tuesday Wednesday Thursday
                Friday Saturday Sunday/
        ]
    );
    my $graph = Text::Graph->new( 'Line', minval => 2, maxval => 12 );
    is( $graph->to_string( $dset ), $expected, $label );
}
