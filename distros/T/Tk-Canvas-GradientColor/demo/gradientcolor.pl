#!/usr/bin/perl
#================================================
# Author : Djibril Ousmanou
# Aim    : Allow you to configure as you want your widget to test
#          all options of Tk::Canvas::GradientColor.
#================================================
use strict;
use warnings;

use Tk;
use Tk::Canvas::GradientColor;
use Tk::BrowseEntry;

my $mw = MainWindow->new(
	-title      => 'gradient color with canvas',
	-background => 'snow',
);

my $canvas = $mw->GradientColor(
	-background => '#005500',
	-width      => 500,
	-height     => 500,
)->pack(qw/ -fill both -expand 1 /);

my %arg_gradient = (
	-type         => undef,
	-start_color  => '#A780C1',
	-end_color    => 'white',
	-start        => undef,
	-end          => undef,
	-number_color => undef,
);

# configure start color
my $bouton_color1 = $canvas->Button(
	-text    => 'select color start',
	-command => sub {
		$arg_gradient{-start_color} = $canvas->chooseColor( -title => 'select color start' );
		$canvas->set_gradientcolor(%arg_gradient);
	},
);

# configure end color
my $bouton_color2 = $canvas->Button(
	-text    => 'select color end',
	-command => sub {
		$arg_gradient{-end_color} = $canvas->chooseColor( -title => 'select color end' );
		$canvas->set_gradientcolor(%arg_gradient);
	},
);

my $type = $canvas->BrowseEntry(
	-label   => 'Type gradient color',
	-choices => [
		qw/ linear_horizontal linear_vertical mirror_horizontal mirror_vertical radial losange corner_right corner_left/
	],
	-background         => 'white',
	-state              => 'readonly',
	-disabledbackground => 'yellow',
	-browsecmd          => sub {
		my ( $widget, $selection ) = @_;
		$arg_gradient{-type} = $selection;
		$canvas->set_gradientcolor(%arg_gradient);
	},
);

my $start_num = $canvas->Scale(
	-background   => 'white',
	-label        => 'Start',
	-from         => 0,
	-to           => 100,
	-variable     => 0,
	-orient       => 'horizontal',
	-sliderlength => 10,
	-command      => sub {
		my $selection = shift;
		$arg_gradient{-start} = $selection;
		$canvas->set_gradientcolor(%arg_gradient);
	},
);

my $end_num = $canvas->Scale(
	-background   => 'white',
	-label        => 'End',
	-from         => 0,
	-to           => 100,
	-variable     => '100',
	-orient       => 'horizontal',
	-sliderlength => 10,
	-command      => sub {
		my $selection = shift;
		$arg_gradient{-end} = $selection;
		$canvas->set_gradientcolor(%arg_gradient);
	},
);
my $num                = 100;
my $entry_number_color = $canvas->BrowseEntry(
	-label              => 'Number color',
	-choices            => [qw/ 2 3 4 5 10 50 100 150 200 250 300 400 500 750 1000 1500 2000 2500/],
	-state              => 'readonly',
	-disabledbackground => 'yellow',
	-background         => 'white',
	-variable           => \$num,
	-browsecmd          => sub {
		my ( $widget, $selection ) = @_;
		$arg_gradient{-number_color} = $selection;
		$canvas->set_gradientcolor(%arg_gradient);
	},
);

my $disabled_gradientcolor = $canvas->Button(
	-text    => 'disabled_gradientcolor',
	-command => sub { $canvas->disabled_gradientcolor; },
);
my $enabled_gradientcolor = $canvas->Button(
	-text    => 'enabled_gradientcolor',
	-command => sub { $canvas->enabled_gradientcolor; },
);

$canvas->createWindow( 100, 100, -window => $bouton_color1 );
$canvas->createWindow( 400, 100, -window => $bouton_color2 );
$canvas->createWindow( 100, 150, -window => $start_num );
$canvas->createWindow( 100, 200, -window => $end_num );
$canvas->createWindow( 350, 150, -window => $entry_number_color );
$canvas->createWindow( 350, 200, -window => $type );
$canvas->createWindow( 100, 350, -window => $disabled_gradientcolor );
$canvas->createWindow( 400, 350, -window => $enabled_gradientcolor );

MainLoop;