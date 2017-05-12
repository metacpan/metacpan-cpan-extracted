use Test::More tests => 82;
BEGIN { use_ok('Tk::Taxis') };

use Tk;
use strict;
use warnings;
my $mw = new MainWindow;

diag "\nDuring these tests, some windows may appear temporarily";

# create with defaults
my $taxis = $mw->Taxis();
ok( ref $taxis eq "Tk::Taxis", 'default class' );
ok( $taxis->height() == 400, 'default height' );
ok( $taxis->cget( -width ) == 400, 'default width' );
my $default_pref = $taxis->cget( -preference );
ok( $default_pref->[0] == 100, 'default x preference' );
ok( $default_pref->[1] == 100, 'default y preference' );
ok( $taxis->cget( -population ) == 20, 'default population' );
ok( $taxis->cget( -tumble ) == 0.03, 'default tumble' );
ok( $taxis->cget( -speed ) == 0.006, 'default speed' );
ok( $taxis->cget( -images ) eq "woodlice", 'default image set' );
my $default_fill = $taxis->cget( -fill );
ok( $default_fill->[0][0] eq 'white' , 'default fill top left');
ok( $default_fill->[0][1] eq 'gray', 'default fill top right' );
ok( $default_fill->[1][0] eq 'white', 'default bottom left' );
ok( $default_fill->[1][1] eq 'gray', 'default bottom right' );
my $calc = $taxis->cget( -calculation );
ok( ref $calc eq "CODE", 'default calculation' );

# create with options
$taxis = $mw->Taxis
	( -width => 100, -height => 200, -population => 50, -tumble => 0.02,
	  -speed => 0.05, -images => 'bacteria' );
ok( ref $taxis eq "Tk::Taxis", 'class' );
ok( $taxis->cget( -height ) == 200, 'height cget' );
ok( $taxis->height() == 200, 'height method' );
ok( $taxis->cget( -width ) == 100, 'width cget' );
ok( $taxis->width() == 100, 'width method' );
ok( $taxis->cget( -population ) == 50, 'population cget' );
ok( $taxis->population() == 50, 'population method' );
ok( $taxis->cget( -tumble ) == 0.02, 'tumble cget' );
ok( $taxis->tumble() == 0.02, 'tumble method' );
ok( $taxis->cget( -speed ) == 0.05, 'speed cget' );
ok( $taxis->speed() == 0.05, 'speed class' );
ok( $taxis->cget( -images ) eq 'bacteria', 'images cget' );
ok( $taxis->images() eq 'bacteria', 'images method' );

# images
$taxis->configure( -images => 'woodlice' );
my $img = $taxis->cget( -images );
ok( $img eq 'woodlice', 'images set' );
ok ( $taxis->image_height() == 50, 'images height' );
ok ( $taxis->image_width() == 50, 'images width' );

# preference
$taxis->configure( -preference => [ 0.1, -50 ] );
my $pref = $taxis->cget( -preference );
ok( $pref->[0] == 1, 'preference set too low' );
ok( $pref->[1] == -50, 'preference set too low' );
$taxis->configure( -preference => [ 20 ] );
$pref = $taxis->cget( -preference );
ok( $pref->[0] == 20, 'preference set single value' );
ok( $pref->[1] == 1, 'preference set single value' );
$taxis->configure( -preference => 200 );
$pref = $taxis->cget( -preference );
ok( $pref->[0] == 200, 'preference set simple value' );
ok( $pref->[1] == 1, 'preferences set simple value' );

# tumble
$taxis->tumble( 0.5 );
my $tumble = $taxis->cget( -tumble );
ok( $tumble == 0.5, 'tumble set' );
$taxis->configure( -tumble => 20 );
$tumble = $taxis->tumble();
ok( $tumble == 1, 'tumble set too high' );
$taxis->configure( -tumble => -20 );
$tumble = $taxis->cget( -tumble );
ok( $tumble == 0, 'tumble set too low' );

# speed
$taxis->configure( -width => 30 ); 
$taxis->configure( -height => 40 ); 
$taxis->configure( -speed => 0.06 );
ok( $taxis->cget( -speed ) == 0.06, 'speed set' );
$taxis->configure( -speed => 0.02 );
ok( $taxis->cget( -speed ) == 0.04, 'speed set too low' );

# calculation
my $coderef = $taxis->cget( -calculation );
$taxis->configure( -calculation => sub { return 1, 1000 } );
my ( $x, $y ) = $taxis->cget( -calculation )->();
ok( $x == 1, 'calculation set' );
ok( $y == 1000, 'calculation set' );
$taxis->configure( -calculation => $coderef );

# population
$taxis->population( 100 );
my %c = $taxis->cget( -population );
ok( $c{ total } == 100, 'population set' ); 
$taxis->population( -10 );
%c = $taxis->cget( -population, 'population set too low' );
ok( $c{ total } == 10, 'population total' ); 
ok( $c{ bottom } == $c{ bottom_left } + $c{ bottom_right }, 'population bottom' ); 
ok( $c{ top } == $c{ top_left } + $c{ top_right }, 'population top' ); 
ok( $c{ right } == $c{ bottom_right } + $c{ top_right }, 'population right' ); 
ok( $c{ left } == $c{ bottom_left } + $c{ top_left }, 'population left' ); 
ok( $c{ total } == $c{ bottom } + $c{ top }, 'population total sum' ); 
ok( $taxis->cget( -population ) == 10, 'population set cget' );

# fill
$taxis->configure( -fill => '#667766' );
my $fill = $taxis->cget( -fill );
ok( $fill->[0][0] eq '#667766', 'fill set hex top left' );
ok( $fill->[0][1] eq '#667766', 'fill set hex top right' );
ok( $fill->[1][0] eq '#667766', 'fill set hex bottom left' );
ok( $fill->[1][1] eq '#667766', 'fill set hex bottom right' );
$taxis->configure( -fill => [ 'red', 'blue' ] );
$fill = $taxis->cget( -fill );
ok( $fill->[0][0] eq 'red', 'fill set word top left' );
ok( $fill->[0][1] eq 'blue', 'fill set word top right' );
ok( $fill->[1][0] eq 'red', 'fill set word bottom left' );
ok( $fill->[1][1] eq 'blue', 'fill set word bottom right' );
$taxis->configure( -fill => [ 'red', 'blue' ] );
$fill = $taxis->cget( -fill );
ok( $fill->[0][0] eq 'red', 'fill set arrayref top left' );
ok( $fill->[0][1] eq 'blue', 'fill set arrayref top right' );
ok( $fill->[1][0] eq 'red', 'fill set arrayref bottom left' );
ok( $fill->[1][1] eq 'blue', 'fill set arrayref bottom right' );
$taxis->configure( -fill => [ [ 'red', 'yellow' ], [ 'blue', '#888888' ] ] );
$fill = $taxis->cget( -fill );
ok( $fill->[0][0] eq 'red', 'fill set aoa top left' );
ok( $fill->[0][1] eq 'yellow', 'fill set aoa top right' );
ok( $fill->[1][0] eq 'blue', 'fill set aoa bottom left' );
ok( $fill->[1][1] eq '#888888', 'fill set aoa bottom right' );

# taxis methods
my $return = $taxis->taxis();
ok( ref $return eq 'Tk::Taxis', 'return value of taxis' );
$return = $taxis->refresh();
ok( ref $return eq 'Tk::Taxis', 'return value of refresh' );

# critters
$taxis = $mw->Taxis();
my $critter = $taxis->{ critters }[ 1 ];
my @pos = $critter->get_pos();
ok( defined $pos[0], 'position x' );
ok( defined $pos[1], 'position y' );
my $obj = $critter->move();
ok( ref $obj eq 'Tk::Taxis::Critter', 'critter class' );
$obj = $critter->randomise();
ok( ref $obj eq 'Tk::Taxis::Critter', 'critter randomise' );
my %b = $critter->get_boundries();
ok( $b{min_x} == 25, 'critter boundries min_x' ); 
ok( $b{min_y} == 25, 'critter boundries min_y' ); 
ok( $b{max_x} == 375, 'critter boundries max_x' ); 
ok( $b{max_y} == 375, 'critter boundries max_y' ); 
ok( $b{height} == 400, 'critter boundries height' ); 
ok( $b{width} == 400, 'critter boundries width' ); 
$critter->set_orient('s');
ok( $critter->get_orient() eq 's', 'critter boundries get_orient' );
$critter->{ direction } = 0.01;
$critter->set_orient();
ok( $critter->get_orient() eq 'e', 'critter boundries set_orient' );
