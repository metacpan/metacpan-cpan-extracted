#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Bars;

my $mw = MainWindow->new(
  -title      => 'Tk::Chart::Bars - cumulate percent + zoom menu',
  -background => 'white',
);

my $chart = $mw->Bars(
  -title           => 'Tk::Chart::Bars - cumulate percent + zoom menu',
  -xlabel          => 'X Label',
  -background      => 'snow',
  -ylabel          => 'Percent',
  -linewidth       => 2,
  -zeroaxisonly    => 1,
  -cumulatepercent => 1,
  -showvalues      => 0,
  -outlinebar      => 'blue',
  -xvaluefont      => '{Times} 12 {normal}',
  -xvaluecolor     => '#336699',
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st',     '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', 'dernier' ],
  [ 1,         '--',  0,     116,   3,     1.5,   1,     3,     4 ],
  [ 'mistake', 247,   57,    2,     3,     'NA',  7,     9,     4 ],
  [ 1,         452,   52,    69,    3,     17.5,  1,     43,    4 ],
);

# Add a legend to our graph
my @legends = ( 'legend 1', 'legend 2', 'legend 3' );
$chart->set_legend(
  -title       => 'Title legend',
  -data        => \@legends,
  -titlecolors => 'blue',
);

# Add help identification
$chart->set_balloon();

# Create the graph
$chart->plot( \@data, -substitutionvalue => 12, );

$chart->add_data( [ 1 .. 9 ], 'legend 4' );

my $menu = Menu( $chart, [qw/30 50 80 100 150 200/] );

MainLoop();

sub CanvasMenu {
  my ( $canvas, $x, $y, $canvas_menu ) = @_;
  $canvas_menu->post( $x, $y );

  return;
}

sub Menu {
  my ( $chart, $ref_data ) = @_;
  my %config_menu = (
    -tearoff    => 0,
    -takefocus  => 1,
    -background => 'white',
    -menuitems  => [],
  );
  my $menu = $chart->Menu(%config_menu);
  $menu->add( 'cascade', -label => 'Zoom' );
  $menu->add( 'cascade', -label => 'Zoom X-axis' );
  $menu->add( 'cascade', -label => 'Zoom Y-axis' );

  my $zoomx_menu = $menu->Menu(%config_menu);
  my $zoomy_menu = $menu->Menu(%config_menu);
  my $zoom_menu  = $menu->Menu(%config_menu);

  for my $zoom ( @{$ref_data} ) {
    $zoom_menu->add(
      'command',
      -label   => "$zoom \%",
      -command => sub { $chart->zoom($zoom); }
    );
    $zoomx_menu->add(
      'command',
      -label   => "$zoom \%",
      -command => sub { $chart->zoomx($zoom); }
    );
    $zoomy_menu->add(
      'command',
      -label   => "$zoom \%",
      -command => sub { $chart->zoomy($zoom); }
    );

  }

  $menu->entryconfigure( 'Zoom X-axis', -menu => $zoomx_menu );
  $menu->entryconfigure( 'Zoom Y-axis', -menu => $zoomy_menu );
  $menu->entryconfigure( 'Zoom',        -menu => $zoom_menu );

  $chart->Tk::bind( '<ButtonPress-3>', [ \&CanvasMenu, Ev('X'), Ev('Y'), $menu, $chart ] );

  return $menu;
}
