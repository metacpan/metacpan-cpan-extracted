use strict;
use warnings;
use Test::More tests => 6;
use Test::Steering::Wheel;

my $wheel = Test::Steering::Wheel->new;
isa_ok $wheel, 'Test::Steering::Wheel';

my @got     = ();
my $printer = sub {
    my ( $parser, $type, $line ) = @_;
    push @got, $line;
};

my ( $demux, $done, $finish )
  = $wheel->_output_demux( $printer, sub { } );
is( ( scalar grep { 'CODE' eq ref $_ } ( $demux, $done, $finish ) ),
    3, "Code references OK" );

my ( $p1, $p2 ) = map { [] } 1 .. 2;
$demux->( $p1, 'raw', "p1.1\n" );
is_deeply \@got, ["p1.1\n"], "Output OK 1";
$demux->( $p2, 'raw', "p2.1\n" );
is_deeply \@got, ["p1.1\n"], "Output OK 2";
$demux->( $p1, 'raw', "p1.2\n" );
is_deeply \@got, [ "p1.1\n", "p1.2\n" ], "Output OK 3";
$done->( $p1 );
$demux->( $p2, 'raw', "p2.2\n" );
$finish->();
is_deeply \@got, [ "p1.1\n", "p1.2\n", "p2.1\n", "p2.2\n" ],
  "Output OK at end";

