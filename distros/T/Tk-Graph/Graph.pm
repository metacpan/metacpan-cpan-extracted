package Tk::Graph;
#------------------------------------------------
# automagically updated versioning variables -- CVS modifies these!
#------------------------------------------------
our $Revision           = '$Revision: 1.58 $';
our $CheckinDate        = '$Date: 2002/12/12 16:04:55 $';
our $CheckinUser        = '$Author: xpix $';
# we need to clean these up right here
$Revision               =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinDate            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinUser            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
#-------------------------------------------------
#-- package Tk::Graph ----------------------------
#-------------------------------------------------

=head1 NAME

Tk::Graph - A graphical Chartmaker at Canvas (Realtime).

=head1 SYNOPSIS

   use Tk;
   use Tk::Graph;

   $mw = MainWindow->new;

   my $data = {
    	Sleep   => 51,
   	Work    => 135,
   	Access  => 124,
   	mySQL   => 5
   };

   my $ca = $mw->Graph(
   		-type  => 'BARS',
   	)->pack(
   		-expand => 1,
   		-fill => 'both',
   	);

   $ca->configure(-variable => $data);     # bind to data

   # or ...

   $ca->set($data);        # set data

   MainLoop;


=head1 DESCRIPTION

A graphical Chartmaker at Canvas (Realtime). This is a real Canvas widget,
so you can draw with the standard routines in the Canvas object.
For example, you can draw a line with I<$chart>->I<line(x,y,...)>. This is useful for you when you will
add a logo or write some text in your created Chart.

=cut


# -------------------------------------------------------
#
# Graph.pm
#
# A graphical Chartmaker at Canvas (Realtime)
# -------------------------------------------------------

use Carp;
use base qw/Tk::Derived Tk::Canvas/;
use Math::Trig qw(rad2deg acos);
use Tie::Watch;
use strict;

Construct Tk::Widget 'Graph';

#-------------------------------------------------
sub Populate {
#-------------------------------------------------
my ($self, $args) = @_;
$self->SUPER::Populate($args);

=head1 WIDGET-SPECIFIC OPTIONS

=cut

my %specs;

#-------------------------------------------------
$specs{-debug} 		= [qw/PASSIVE debug        Debug/,             undef];

=head2 -debug [I<0>|1]

This is the switch for debug output at the normal console (STDOUT)

=cut

#-------------------------------------------------
$specs{-type}  		= [qw/PASSIVE type         Type/,		undef];

=head2 -type (I<Automatic>, Line, Bars, HBars, Circle)

This is the type of Graph to display the data.

I<Automatic> - analyze the datahash and choose a Chart:

 Hash with values -> PieChart
 Hash with keys with hashes or values (not all) -> Barchart per Key
 Hash with keys with arrays -> Linechart per Key
 Array -> Linechart

I<Line> - Linechart,

I<Bars> - Barchart with vertical Bars,

I<HBars> - Barchart with horizontal bars,

I<Circle> - PieChart

=cut

#-------------------------------------------------
$specs{-foreground} 	= [qw/PASSIVE foreground   Foreground/,		'black'];

=head2 -foreground (I<black>)

Color for the Axis, Legend and Labels.

=cut

#-------------------------------------------------
$specs{-titlecolor}     = [qw/PASSIVE titlecolor   TitleColor          brown/];
$specs{-title}     	= [qw/PASSIVE title        Title/,             ' '];

=head2 -title -titlecolor (I<brown>)

Message at the top of the Widget.

=cut

#-------------------------------------------------
$specs{-headroom}     	= [qw/PASSIVE headroom     HeadRoom/,          20];

=head2 -headroom  (I<20>)

The headroom in percent. This is a clean area at the top of the widget.
When a value is in this area, the graph is redrawn to preserve this headroom.

=cut

#-------------------------------------------------
$specs{-threed}     	= [qw/PASSIVE threed     Threed/,              undef];

=head2 -threed  (I<undef>)

This switch a three dimensional Display on. The Value is deep in Pixel.

=cut

#-------------------------------------------------
$specs{-light}     	= [qw/PASSIVE light      Light/,              [10,5,0]];

=head2 -light  (I<[10,5,0]>)

How many percent is the color in top, side and front (in this direction)
lighter or darker in 3d?

=cut


#-------------------------------------------------
$specs{-max}     	= [qw/PASSIVE max          Max/,               undef];

=head2 -max

Maximum Value for the axis. If this set,
the axis is not dynamically redrawn to the
next maximum value from the data.
Only used in Lines and Bars!

=cut

#-------------------------------------------------
$specs{-sortnames}     	= [qw/PASSIVE sortnames	   SortNames/,         'alpha'];
$specs{-sortreverse}    = [qw/PASSIVE sortreverse  SortReverse/,      	undef];

=head2 -sortnames ('I<alpha>' | 'num') -sortreverse (0, 1)

sort the keys from the data hash.

=cut

#-------------------------------------------------
$specs{-config}    	= [qw/PASSIVE config       Config/,            undef];

=head2 -config (\%cfghash)

A config hash with optional added parameters for more flexibility. The first is the name
of the key from your data hash, followed by a config hash with parameters.
example:

        -config         => {
        	'fr' => {
        		-title => 'Free',
        		-color => 'green',
			-range => {
				'red' 	=> [0, 50],
				'yellow'=> [50, 100],
				'green' => [100, 200],
			},
        	},
                'sl' => {
                	-title => 'Sleep',
                	-color => 'yellow',
                },
                ...
        },

I<-title>

Here you can write another Name to display.

I<-color>

Key name displayed in this color.

I<-range>

A range to display the values in variable colors. You can say values from 0 to 50 display in
green or above in red. if value not in something range, then this draw in original color.
This is only use in LINE (ToDo: BARS and HBARS!)


=cut

#-------------------------------------------------
$specs{-fill}     	= [qw/PASSIVE fill         Fill/,              'both'];

=head2 -fill (I<'both'>)

The same as in perl/tk pack. Redraw only in
I<x>,I<y> or I<both> direction(s).

=cut

#-------------------------------------------------
$specs{-ylabel}     	= [qw/PASSIVE ylabel	    YLabel/,		undef];
$specs{-xlabel}     	= [qw/PASSIVE xlabel	    XLabel/,		undef];

=head2 -xlabel -ylabel (I<text>)

This displays a description for x and y axis.

=cut

#-------------------------------------------------
$specs{-ytick}     	= [qw/PASSIVE ytick	    YTick/,		5];
$specs{-xtick}     	= [qw/PASSIVE xtick	    XTick/,		5];

=head2 -xtick -ytick (I<5>)

Number of ticks at the x or y axis.

=cut

#-------------------------------------------------
$specs{-yformat}     	= [qw/PASSIVE yformat	    YFormat/,		'%g'];
$specs{-xformat}     	= [qw/PASSIVE xformat	    XFormat/,		'%s'];

=head2 -xformat (I<'%s'>) -yformat (I<'%g'>)

This if the sprintf format for display
of the value or key for the axis.
example:

        -xformat => '%d%%'      # This will eg. Display '50%'
        -yformat => '%s host'   # This will eg. Display 'first host'

=cut

#-------------------------------------------------
$specs{-padding}     	= [qw/PASSIVE padding	    Padding/,		[15,20,20,50]];

=head2 -padding (I<[15,20,20,50]>)

Margin display from the Widget border, in this order top, right, bottom,
left.

=cut

#-------------------------------------------------
$specs{-linewidth}     	= [qw/PASSIVE linewidth    Linewidth           1/];

=head2 -linewidth (I<1>)

The weight of the border for the dots, circle and lines.

=cut


#-------------------------------------------------
$specs{-printvalue}     = [qw/PASSIVE printvalue   Printvalue/,        undef];

=head2 -printvalue

This is the sprintf format and switch for display of the value.

=cut

#-------------------------------------------------
$specs{-maxmin}     	= [qw/PASSIVE maxmin       MaxMin/,            undef];

=head2 -maxmin

Draw max/average/min value lines in Bars and Line charts

=cut

#-------------------------------------------------
$specs{-legend}     	= [qw/PASSIVE legend       Legend/,            1];

=head2 -legend [0|I<1>]

Switch on/off the legend in Circle or Lines

=cut

#-------------------------------------------------
$specs{-colors}     	= [qw/PASSIVE colors       Colors/,            'blue,brown,seashell3,red,green,yellow,darkgreen,darkblue,darkred,orange,olivedrab,magenta,black,salmon'];

=head2 -colors (I<red, green, ...>)

A comma-separated list with the allowed colors.


=cut

#-------------------------------------------------
$specs{-shadow}     	= [qw/PASSIVE shadow        Shadow/,            'gray50'];
$specs{-shadowdepth}    = [qw/PASSIVE shadowdepth   Shadowdepth/,        undef];

=head2 -shadow (I<'gray50'>) -shadowdepth (I<0>)

You can add a shadow to all Charts, the
switch is -shadowdepth. This is also the depth in Pixels for the shadow.
-shadow is the color for the shadow. This Option is autoaticly switch off when use 3d.

=cut

#-------------------------------------------------
$specs{-wire}     	= [qw/PASSIVE wire         Wire/,              'white'];

=head2 -wire (I<'white'>)

Switch on/off a wire grid in background from line and bars chart.

=cut

#-------------------------------------------------
$specs{-reference}     	= [qw/PASSIVE reference    Reference/,         undef];

=head2 -reference (I<'name'>, I<'value'>)

This give a Reference value for the keys in datahash. I.e. the data values are displayed relative to this reference value.

example:

        -reference      => 'Free, 1024',        # Free space at host

=cut

#-------------------------------------------------
$specs{-look}     	= [qw/PASSIVE look         Look/,              10];

=head2 -look (I<10>)

The number of values to display in a line chart.
When you refresh the data hash (maybe with the methods set or variable), then this will display
eg. the last 50 values.

example:

        -look   => 50,  # 50 values to display pro key

=cut

#-------------------------------------------------
$specs{-dots}     	= [qw/PASSIVE dots         Dots/,              undef];

=head2 -dots (I<'width'>)

The width and switch for the dots in line chart.

=cut

#-------------------------------------------------
$specs{-barwidth}     	= [qw/PASSIVE barwidth     Barwidth/,          30];

=head2 -barwidth (I<30>)

The width for bars in bar charts.

=cut

#-------------------------------------------------
$specs{-balloon}     	= [qw/PASSIVE balloon      Balloon/,           1];

=head2 -balloon (0|I<1>)

Switch on/off ballon help for segements or lines.
The text format is used from the -printvalue option.

=cut

#-------------------------------------------------
$specs{-font}     	= [qw/PASSIVE font	    Font/,		'-*-Helvetica-Medium-R-Normal--*-100-*-*-*-*-*-*'];

=head2 -font (I<'-*-Helvetica-Medium-R-Normal--*-100-*-*-*-*-*-*'>)

Draw text in this font.

=cut

#-------------------------------------------------
$specs{-lineheight}     = [qw/PASSIVE lineheight   LineHeight/,	15];

=head2 -lineheight (I<15>)

The line height in pixels for text in the legend.

=cut

#-------------------------------------------------


=head1 METHODS

Here come the methods that you can use with this Widget.

=cut


#-------------------------------------------------

#-------------------------------------------------
$specs{-set}     	= [qw/METHOD  set          Set/,               undef];

=head2 $chart->I<set>($data);

Set the data hash to display.

=cut

#-------------------------------------------------
$specs{-variable}     	= [qw/METHOD  variable     Variable/,          undef];

=head2 $chart->I<variable>($data);

Bind the data hash to display the data, write to $data will redraw the widget.

=cut

#-------------------------------------------------
$specs{-register}     	= [qw/METHOD  register	   Register/,               undef];

=head2 $chart->I<register>($to_register);

Set the data hash to register. When you have data for Linegraph
then can you this register with method register. This data
is the registered for the following linegraph, when you set
new datas with 'set' or 'variable' then if this startet at
the end from this data. if you call register without data the
you get the actual datacache.

  my $to_register = {
	'one'  => [0,5,4,8,6,8],
	'two' => [2,5,9,4,6,2],
	'three' => [0,5,6,8,6,8],
  };
  $ca->register($to_register);

=cut


#-------------------------------------------------
$specs{-redraw}     	= [qw/METHOD  redraw       Redraw/,            undef];

=head2 $chart->I<redraw>();

Redraw chart

=cut

#-------------------------------------------------
$specs{-clear}     	= [qw/METHOD  clear        Clear/,             undef];

=head2 $chart->I<clear>();

Clear the canvas.

=cut


        $self->ConfigSpecs(
		%specs,
        );

        # Bindings
        $self->Tk::bind('<Configure>', [ \&redraw, $self ] );                # Redraw

        # Help (CanvasBalloon)
        # $self->{balloon} = $self->Balloon;

} # end Populate

#-------------------------------------------------
sub draw_horizontal_bars {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || return;

	# Check
	return warn("Your data is incorrect, i need a Hashreference!")
		unless(ref $data eq 'HASH');


        my $werte = $self->reference($data);
        my $conf = $self->ReadConfig($werte) || return;

        $self->delete('all');

        # MaxMin Werte ermitteln und ggf Linien zeichnen
        $self->maxmin($conf, $werte);

        # Gitter zeichnen
        $self->wire($conf)
                if( $self->cget(-wire) );

        # Axis (Titel ... usw
        $self->axis($conf, $werte);


        $self->debug("Count: %d,Typ: %s, Max: %s", $conf->{count}, $conf->{typ}, $conf->{max_value});
        if($conf->{count} > 0 && $conf->{typ} eq 'HASH' && $conf->{max_value} > 0)
        {
                my $i = -0.5;
                my @linepoints;
                my $c;
		my $shadowcolor = $self->cget(-shadow);
		my $sd = $self->cget(-shadowdepth);
		my $td = $self->cget(-threed) || 0;

                foreach my $point (sort { $self->sorter } keys %$werte ) {
                        next if(ref $werte->{$point});
                        next unless($conf->{max_value});
                        $i++;

                        my $xi = ($conf->{x_null} + round( ( ($conf->{width} - $conf->{x_null}) / $conf->{max_value} ) * $werte->{$point}));
                        my $yi = ($conf->{y_null}) - (round(($conf->{y_null} - $conf->{ypad}) / $conf->{count}) * $i);
                        $yi-=($self->cget(-barwidth) / 2);

                        # Values
                        $self->createText($xi+12, $yi + ($self->cget(-barwidth) / 2),
				-text => sprintf($self->cget(-printvalue), '', $werte->{$point}),
                                -anchor => 'w',
                                -font => $conf->{font},
                                -fill => $self->cget(-titlecolor)
                                        ) if($self->cget(-printvalue));


                        # Shadow Bar
                        if($sd && $werte->{$point} && ! $td) {
                                my $bar = $self->createRectangle(
                                                ($xi+$sd), ($yi+$sd),
                                                ($conf->{x_null}), ($yi + $self->cget(-barwidth) + $sd),
                                        -fill => $shadowcolor,
                                        -outline => $shadowcolor,
                                        );
                        }

                        # ThreeD Bar
			# Oben
                        $self->createPolygon(
				$conf->{x_null}, $yi,
                                ($conf->{x_null} + $td), ($yi - $td),
                                ($xi + $td), ($yi - $td),
                                ($xi), ($yi ),
				-fill => $self->color_change( $self->{colors}->{$point}, $conf->{light_top}),
				-outline => 'black',
                        ) if($td);

			# Side
                        $self->createPolygon(
                                ($xi  ), ($yi + $self->cget(-barwidth)) ,
                                ($xi + $td ), ($yi + $self->cget(-barwidth) - $td) ,
                                ($xi + $td), ($yi - $td),
                                ($xi ), ($yi ),
				-fill => $self->color_change( $self->{colors}->{$point}, $conf->{light_side}),
				-outline => 'black',
                        ) if($td);

                        # Normaler Bar
                        $self->{elements}->{$point} = $self->createRectangle($xi, $yi,
                                $conf->{x_null}, ($yi + $self->cget(-barwidth)),
				-fill => ( $self->cget(-threed) ? $self->color_change( $self->{colors}->{$point}, $conf->{light_front}) : $self->{colors}->{$point} ),
                                -width => 1,
			) if($werte->{$point});
                }

	        # balloon
	        $self->balloon($self->{elements}, $werte);

        }
}


#-------------------------------------------------
sub draw_bars {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || return;

	# Check
	return warn("Your data is incorrect, i need a Hashreference!")
		unless(ref $data eq 'HASH');


        my $werte = $self->reference($data);
        my $conf = $self->ReadConfig($werte) || return;

        $self->delete('all');

        # MaxMin Werte ermitteln und ggf Linien zeichnen
        $self->maxmin($conf, $werte);

        # Gitter zeichnen
        $self->wire($conf)
                if( $self->cget(-wire) );

        # Axis (Titel ... usw
        $self->axis($conf, $werte);



        if($conf->{count} > 0 && $conf->{typ} eq 'HASH')
        {
                my $i = 0;
                my ($xi, $yi);
                my @linepoints;
                my $c;
		my $td = $self->cget(-threed) || 0;

                foreach my $point (sort { $self->sorter } keys %$werte ) {
                        next if(ref $werte->{$point});
                        next unless($conf->{max_value});
			$werte->{$point} = 0
				unless(defined $werte->{$point});
                        $i++;

                        $xi = $self->calc_x($i) - ($self->cget(-barwidth) / 2);
                       	$yi = $self->calc_y($werte->{$point});

			$self->debug("---------------------");
			$self->debug("DrawBar: Name: %s, Wert: %d", $point, $werte->{$point});

			$self->bar( $point, $werte->{$point}, $i );
                }
        } else {
                return $self->error("I need a hash to display Bars!");
        }

        # balloon
        $self->balloon($self->{elements}, $werte);
}

#-------------------------------------------------
sub bar {
#-------------------------------------------------
        my $self 	= shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
	my $name	= shift || return error('No Name!');
	my $wert	= shift || 0;
	my $i		= shift;

        my $conf 	= $self->{cfg};
        my $xi 		= $self->calc_x($i) - round($self->cget(-barwidth) / 2);
        my $yi 		= $self->calc_y($wert);
	my $width 	= $self->cget(-barwidth);
        my $height 	= $conf->{y_null};
        my $td 		= $self->cget(-threed) || 0;

	$self->debug('Name: %s, X: %d, Y:%d, Width: %d, Hight: %d, 3D: %d',
			$name, $xi, $yi, $width, $height, $td);


        # ThreeD Bar
	# -----------------------------------
        if( $td ) {
		# Oben
                $self->createPolygon(
			$xi, $yi,
                        ($xi + $td), ($yi - $td),
                        ($xi + $width + $td), ($yi - $td),
                        ($xi + $width ), ($yi ),
			-fill => $self->color_change( $self->{colors}->{$name}, $conf->{light_top}),
			-outline => 'black',
                );
		# Side
                $self->createPolygon(
                        ($xi + $width ), $conf->{y_null} ,
                        ($xi + $width+$td ), ($conf->{y_null} - $td) ,
                        ($xi + $width+$td), ($yi - $td),
                        ($xi + $width ), ($yi ),
			-fill => $self->color_change( $self->{colors}->{$name}, $conf->{light_side}),
			-outline => 'black',
                );
        }

        # Shadow Bar
        if($wert && $self->cget(-shadowdepth) && (my $shadowcolor = $self->cget(-shadow)) && (my $sd = $self->cget(-shadowdepth)) && ! $self->cget(-threed)) {
                $self->createRectangle(
                        ($xi+$sd), ($yi+$sd),
                        ($xi + $self->cget(-barwidth)+$sd), $conf->{y_null},
                        -fill => $shadowcolor,
                        -outline => $shadowcolor,
                 );
        }

        # Normaler Bar
        $self->{elements}->{$name} = $self->createRectangle(
        		$xi, $yi,
                        ($xi + $width), $height,
                        -fill => ( $self->cget(-threed) ? $self->color_change( $self->{colors}->{$name}, $conf->{light_front}) : $self->{colors}->{$name} ),
                        -width => 1,
                  ) if($wert);
	# -----------------------------------

        # Values
        $self->createText($xi+12+$td, $yi-12-$td,
                -text => sprintf($self->cget(-printvalue), '', $wert),
                -anchor => 'n',
                -font => $conf->{font},
                -fill => $self->cget(-titlecolor)
                        ) if($self->cget(-printvalue));




}

#-------------------------------------------------
sub color_change {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $col = shift || return error("No Color!");
        my $fac = shift || return $col;

	my @colors = $self->rgb($col);
	my $wert = '#';
	foreach (@colors) {
		my $dec = $_;
		my $w = ($dec + (($dec * $fac) / 100));
		$w = 0xFFFF if($w > 0xFFFF);
		$w = 0 if($w < 0);
		$wert .= sprintf('%X', $w);
	}

	$self->debug(
		'Col: %s, Fac: %s, ColAfter: %s',
		$col, $fac, $wert);

	return $wert;
}

#-------------------------------------------------
sub draw_line {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || return;
        my $werte = $self->reference($data);
        my $conf = $self->ReadConfig($werte) || return;
        my $MAX;

        $self->delete('all');

        # Zeitverfolgung
        $self->look($werte)	if($data);

        # MaxMin Werte ermitteln und ggf. Linien zeichnen
        $self->maxmin($conf, $werte);

        # Gitter zeichnen
        $self->wire($conf, $data);

        # Axis (Titel ... usw
        $self->axis($conf, $werte);

        if( $conf->{count} > 0 && ( $conf->{typ} eq 'HASH' || $self->cget(-look)))
        {
                my $z = 0;
		my $data = ($self->cget(-look) ? $self->{look} : $werte);
		my $w;
		my $td = $self->cget(-threed) || 0;
		my $th = round($td / 3)	if(defined $td);
		my $ti = -1;

                foreach my $name (sort { $self->sorter } keys %{$data}) {
			$ti++;
                        my @linepoints;
                        my $i = 0;
                        my ($xi, $yi, $xi_old, $yi_old);

                        foreach my $point (@{$data->{$name}}) {
                                $xi = $conf->{x_null} + ((round( ($conf->{width} - $conf->{x_null})/$conf->{count})) * $i++);
                                push(@linepoints, $xi);
                                $yi = $conf->{y_null} - (( $conf->{y_null} - $conf->{ypad_top})/$conf->{max_value} * $point);
                                push(@linepoints, $yi);


				# 3d
                                if( $td && $#linepoints > 1 ) {
					my $winkel = winkel( ($xi - $xi_old), ($yi - $yi_old) );

					# Top
	                                my $top = $self->createPolygon(
						$xi, $yi,
                                                ($xi + $td), ($yi - $td),
                                                ($xi_old + $td), ($yi_old - $td),
                                                ($xi_old), ($yi_old),

						-fill => $self->color_change(
							$self->color($name, $point),
							( $yi_old >= $yi ? $conf->{light_top} : $conf->{light_side} ),
							),
						-outline => $self->color($name, $point),
	                                );

					# Bottom
	                                my $bottom = $self->createPolygon(
						$xi, ($yi + $th),
                                                ($xi + $td), ($yi - $td + $th),
                                                ($xi_old + $td), ($yi_old - $td + $th),
                                                ($xi_old), ($yi_old + $th),

						-fill => $self->color_change( $self->color($name, $point), $conf->{light_side} ),
						-outline => $self->color($name, $point),
	                                ) if($winkel > 45 && $yi < $yi_old);


					# Side
	                                my $side = $self->createPolygon(
						$xi, $yi,
                                                ($xi ), ($yi + $th),
                                                $xi_old, ($yi_old + $th),
                                                $xi_old , $yi_old,

						-fill => $self->color_change( $self->color($name, $point), $conf->{light_front}),
						-outline => $self->color($name, $point),
	                                );
                                }


                                # Values
                                $self->createText($xi+12, $yi-12,
                                        -text => sprintf($self->cget(-printvalue), '', $werte->{$point}),
                                        -anchor => 'n',
                                        -font => $conf->{font},
                                        -fill => $self->cget(-titlecolor)
                                                ) if($self->cget(-printvalue));

                                # Dots
                                $self->createRectangle($xi-$self->cget(-dots), $yi-$self->cget(-dots),
                                        $xi+$self->cget(-dots), $yi+$self->cget(-dots),
                                        -fill => 'gray65',
                                        -width => 1,
                                                ) if($self->cget(-dots));

				# 3d (Abschluss)
                                if( $td && $i >= ( $#{$data->{$name}} + 1 ) ) {
					# Side
	                                $self->createPolygon(
						$xi, $yi,
                                                ($xi + $td), ($yi - $td),
                                                ($xi + $td), ($yi - $td + $th),
						$xi , $yi + $th,

						-fill => $self->color_change( $self->color($name, $point), $conf->{light_side} ),
						-outline => $self->color($name, $point),
	                                );
				}

	                        # Graph Line
	                        $self->{elements}->{$name} = $self->createLine(
		                        	$xi, $yi,
		                        	$xi_old, $yi_old,
		                                -width => $self->cget(-linewidth),
		                                -fill => $self->color($name, $point),
	                                 ) if($xi_old);


				$xi_old = $xi;
				$yi_old = $yi;
                        }

                }

	        # balloon
	        $self->balloon($self->{elements}, $werte);

		# Legend
		$self->legend($data, $conf);
        }
}

#-------------------------------------------------
sub color {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
	my $name = shift || return error("No Name in color");
	my $wert = shift;
	my $color = $self->{colors}->{$name} || 'black';

	if(defined $self->{ranges}->{$name} && defined $wert) {
		foreach $color ( keys %{$self->{ranges}->{$name}} ) {
			my ($min, $max) = @{ $self->{ranges}->{$name}->{$color} };
			if($wert >= $min and $wert <= $max) {
        			$self->debug('Name: %s, Color: %s, Wert: %g', $name, $color, ($wert || 'undef'));
				return $color;
			};
		}
	}


	return $color;
}


#-------------------------------------------------
sub redraw {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        $self->debug('Redraw');
        $self->set();
}


#-------------------------------------------------
sub automatic {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
	return uc($self->cget(-type)) if($self->cget(-type));

        my $data = shift || $self->{data};

	my $type;

	if(ref $data eq 'ARRAY') {
		$type = 'LINE'
	} elsif (ref $data eq 'HASH') {
		foreach my $n (keys %$data) {
			if(ref $data->{$n} eq 'ARRAY') {
				$type = 'LINE';
				last;
			} elsif (ref $data->{$n} eq 'HASH'){
				$type = 'BARS';
				last;
			} else {
				$type = 'CIRCLE';
				last;
			}
		}
	}
	return $type;
}

#-------------------------------------------------
sub set {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift;

	return error('The Widget has no width and height values, you must pack before you can set!')
		unless($self->width || $self->height);

	# Make a LineGraph
	if(ref $data eq 'ARRAY') {
		my $werte;
		$werte->{' '} = $data;
		$data = $werte;
	}

	my $type = $self->automatic( $data );

        $self->{data} = $data if($data);

        if( $type eq 'LINE' ) {
                $self->draw_line($data);

        } elsif(  $type eq 'CIRCLE'  ) {
                $self->draw_circle($data);

        } elsif(  $type eq 'BARS' ) {
                $self->draw_bars($data);

        } elsif(  $type eq 'HBARS' ) {
                $self->draw_horizontal_bars( $data );

        } else {
		return error("Option \'-type\' is incorrect! ($type)");
        }


}

#-------------------------------------------------
sub window_size {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);

        my ($width, $height);
        my $conf = $self->{conf};
        $self->update;
	return unless( $self->cget(-fill) );
        unless(defined $conf->{width} && $conf->{width} > 1 && defined $conf->{height} && $conf->{height} > 1) {
                $width  = $self->width;
                $height = $self->height;
        } else {
                $width  = ( $self->cget(-fill) eq 'x' || $self->cget(-fill) eq 'both' ? $self->width : $conf->{width} );
                $height = ( $self->cget(-fill) eq 'y' || $self->cget(-fill) eq 'both' ? $self->height : $conf->{height} );
        }
        $self->debug('Width: %d, Height: %d', $width, $height);
        return ($width, $height);
}

#-------------------------------------------------
sub reference {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || $self->{data} || return;
        my $reference = $self->cget(-reference) || return $data;
        my ($ref_name, $ref_value) = split(/,/, $reference);

        if(ref $data eq 'HASH') {
                my %werte = %$data;
                my $summe;
                foreach (keys %werte) {
                        $summe+=$werte{$_};
                }
                $werte{$ref_name} = $ref_value - $summe;
                return \%werte;
        }
}

#-------------------------------------------------
sub clear {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
	$self->{data} = undef;
	$self->{look} = undef;
	$self->{colors} = undef;
	$self->redraw;
}

#-------------------------------------------------
sub variable {
#-------------------------------------------------
        my ($graph, $vref) = @_;

        $graph->{watch}->Unwatch
                if(defined $graph->{watch}); # Stoppen, falls ein Watch exisitiert

        my $store = [sub {
             my($self, $key, $new_val) = @_;
             $self->Store($key, $new_val);   # Stopft den neuen Wert ins Watch
             my $args = $self->Args(-store); # Nimmt warn Argumente
             $args->[0]->set($args->[1]);    # Ruft warn interne Routine auf
         }, $graph, $vref];

        $graph->{watch} = Tie::Watch->new(
                -variable => $vref,
                -store => $store );

        $graph->set($vref);

        $graph->OnDestroy( [sub {$_[0]->{watch}->Unwatch}, $graph] );
} # end variable

#-------------------------------------------------
sub ReadConfig {
#-------------------------------------------------
        # Liest warn Daten und oder berechnet den Confighash
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || return error("No Data!");
        my $conf;

        # Config
        $self->config($data);

        # Typ der Daten
        $conf->{typ} = ref $data;

        # Display Typ
        $conf->{type} = uc($self->cget(-type));

        # Font
        $conf->{font}   = $self->cget(-font);

	# Standartcolor
	$conf->{fg} 	= $self->cget(-foreground);

	# Headroom
	$conf->{headroom} = ($self->cget(-headroom) / 100) + 1;

	# Light in 3D
	my $light = $self->cget(-light);
	$conf->{light_top}	= $light->[0];
	$conf->{light_side}	= $light->[1];
	$conf->{light_front}	= $light->[2];

        # Windowsize
        ($conf->{width}, $conf->{height}) = $self->window_size();
	return unless($conf->{width} or $conf->{height});

        $self->{conf}->{width}  = $conf->{width};
        $self->{conf}->{height} = $conf->{height};

        # Padding
        my $padding = $self->cget(-padding);
        $conf->{xpad}           = $padding->[3];
        $conf->{xpad_right}     = $padding->[1];
        $conf->{ypad}           = $padding->[2];
        $conf->{ypad_top}       = $padding->[0];

        $conf->{width}          -= $conf->{xpad_right};
        $conf->{height}         -= $conf->{ypad_top};

        # Title
        $conf->{title}  = $self->cget(-title);
        $conf->{titlecolor} = $self->cget(-titlecolor);

        # Coordinates
        $conf->{y_null} = $conf->{height} - $conf->{ypad};      # 0 Koordinate y-Achse
        $conf->{x_null} = $conf->{xpad};                        # 0 Koordinate x-Achse

        # Werte zaehlen
	$conf->{count} = 0;
        if($conf->{typ} eq 'ARRAY') {
                $conf->{count} = $#$data + 1;
        } elsif($conf->{typ} eq 'HASH' && $self->cget(-look) && $conf->{type} eq 'LINE') {
                $conf->{count} = $self->cget(-look);
        } elsif($conf->{typ} eq 'HASH' && $conf->{type} eq 'LINE') {
		# Durchzaehlen der Werte
                foreach ( keys %$data ) {
                        $conf->{count} = $#{$data->{$_}}
                        	if(ref $data->{$_} eq 'ARRAY' && $#{$data->{$_}} > $conf->{count});
                }

        } else {
                foreach ( keys %$data ) {
                        next if(ref $data->{$_});
                        $conf->{count}++;
                }
        }

	$self->{cfg} = $conf;
        return $conf;
}

#-------------------------------------------------
sub axis {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $conf = shift || return error("No Config");
        my $werte = shift || return error("No Data");


        goto NOAXIS
                if($conf->{type} eq 'CIRCLE');

	# Labels
	$self->labels();

	# Threed
	my $td = $self->cget(-threed) || 0;


        # X - K O O R D I N A T E ------------------------------
        $self->createLine(
                $conf->{x_null}, $conf->{y_null},
                $conf->{width}, $conf->{y_null},
                -width => 1,
                -fill => $conf->{fg},
                );


        # X-Ticks
        if($conf->{type} eq 'HBARS' || $conf->{type} eq 'LINE') {
                for(my $i = 0; $i <= $self->cget(-xtick); $i++) {
                        my $x = $conf->{x_null} + (round( ($conf->{width} - $conf->{x_null})/$self->cget(-xtick)) * $i);

                        $self->createLine(
                                $x, ( $conf->{height} - ($conf->{ypad} + 5) ),
                                $x, $conf->{y_null},
                                -width => 1,
                		-fill => $conf->{fg},
                                );
                        $self->createText(
                                $x, $conf->{y_null},
                                -text => sprintf(' '.$self->cget(-xformat), ( ($conf->{type} eq 'HBARS' ? $conf->{max_value} : $conf->{count}) / $self->cget(-xtick)) * $i),
                                -anchor => 'n',
                                -font => $conf->{font},
                		-fill => $conf->{fg},
                                ) if($i);
                }
        } else {
                my $i = -1;
                foreach my $name ( sort { $self->sorter } keys %$werte) {
                        next if(ref $werte->{$name});
                        $i++;
                        my $text = sprintf($self->cget(-xformat), $name);
                        my $x = $self->calc_x($i+1);

                        $self->createLine(
                                $x, ($conf->{height}-($conf->{ypad}+5)),
                                $x, $conf->{y_null},
                                -width => 1,
                		-fill => $conf->{fg},
                                );
                        $self->createText($x, $conf->{y_null},
                                -text => $text,
                                -anchor => 'n',
                                -font => $conf->{font},
                		-fill => $conf->{fg},
				);
                }
        }
        # X - K O O R D I N A T E ---------BOTTOM----------------


        # Y - K O O R D I N A T E -------------------------------
        $self->createLine(
                $conf->{x_null}, $conf->{y_null},
                $conf->{x_null}, $conf->{ypad_top},
                -width => 1,
                -fill => $conf->{fg},
                );

        $self->createLine(
                $conf->{x_null}+$td, $conf->{y_null}-$td,
                $conf->{x_null}+$td, $conf->{ypad_top}-$td,
                -width => 1,
                -fill => $self->cget(-wire),
                ) if($td);


        if($conf->{type} eq 'HBARS') {
                my $i = 0.5;
                foreach my $name ( sort { $self->sorter } keys %$werte) {

                        my $y = ($conf->{y_null}) - (int(($conf->{y_null} - $conf->{ypad_top}) / $conf->{count} + 0.99) * $i++);

                        $self->createLine(
                                $conf->{x_null},   $y,
                                $conf->{x_null}-5, $y,
                                -width => 1,
                		-fill => $conf->{fg},
                        );

                        $self->createText($conf->{x_null}-8, $y,
                                -text => $name,
                                -anchor => 'e',
                                -font => $conf->{font},
                		-fill => $conf->{fg},
                        );
                }
        } else {
                for (my $i = 0; $i <= $self->cget(-ytick); $i++) {
                        next unless($i);

                        my $y = ($conf->{y_null}) - (round( ( $conf->{y_null} - $conf->{ypad_top} )/$self->cget(-ytick)) * $i);
                        $self->createLine(
                                $conf->{x_null},   $y,
                                $conf->{x_null}-5, $y,
                                -width => 1,
                		-fill => $conf->{fg},
			);

                        $self->createText($conf->{x_null}-8, $y,
                                -text => sprintf($self->cget(-yformat), (($conf->{max_value}/$self->cget(-ytick)) * $i)),                                -anchor => 'e',
                                -font => $conf->{font},
                		-fill => $conf->{fg},
			);
                }
        }
        # Y - K O O R D I N A T E ---------BOTTOM----------------

        NOAXIS:

        # Titel
        $self->createText(
                ($conf->{width} / 2), $self->cget(-lineheight),
                -text => $conf->{title},
                -justify => 'center',
                -fill => $conf->{titlecolor},
                ) if($conf->{title});
}

#-------------------------------------------------
sub maxmin {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $conf = shift || return error("No Config");
        my $werte = shift || return error("No Data");
        my $MAX;

        if($conf->{typ} eq 'HASH' && $conf->{type} eq 'LINE')
        {
                $MAX->{$conf->{title}}->{min} = 10000   unless $MAX->{$conf->{title}}->{min};
                $MAX->{$conf->{title}}->{max} = 0       unless $MAX->{$conf->{title}}->{max};
		my $data = ($self->cget(-look) ? $self->{look} : $werte);
                foreach my $name (keys %{$data}) {
                        foreach my $value (@{$data->{$name}}) {
                                $MAX->{$conf->{title}}->{max} = $value if( $MAX->{$conf->{title}}->{max} <= $value );
                                $MAX->{$conf->{title}}->{min} = $value if( $MAX->{$conf->{title}}->{min} >= $value );
                                $MAX->{$conf->{title}}->{avg} =
                                        ( $MAX->{$conf->{title}}->{max} - $MAX->{$conf->{title}}->{min} ) / 2 +
                                                $MAX->{$conf->{title}}->{min};
                        }
                }
                $conf->{max_value} = $self->cget(-max)
                        ? $self->cget(-max)
                        : $MAX->{$conf->{title}}->{max} * $conf->{headroom};
        }
        elsif($conf->{typ} eq 'ARRAY')
        {
                $MAX->{$conf->{title}}->{min} = 10000   unless $MAX->{$conf->{title}}->{min};
                $MAX->{$conf->{title}}->{max} = 0       unless $MAX->{$conf->{title}}->{max};
                foreach my $value (@{$werte}) {
                        $MAX->{$conf->{title}}->{max} = $value if( $MAX->{$conf->{title}}->{max} <= $value );
                        $MAX->{$conf->{title}}->{min} = $value if( $MAX->{$conf->{title}}->{min} >= $value );
                        $MAX->{$conf->{title}}->{avg} =
                                ( $MAX->{$conf->{title}}->{max} - $MAX->{$conf->{title}}->{min} ) / 2 +
                                        $MAX->{$conf->{title}}->{min};
                }
                $conf->{max_value} = $self->cget(-max)
                        ? $self->cget(-max)
                        : $MAX->{$conf->{title}}->{max} * $conf->{headroom};
        }
        elsif ($conf->{typ} eq 'HASH')
        {
                $MAX->{$conf->{title}}->{min} = 10000   unless $MAX->{$conf->{title}}->{min};
                $MAX->{$conf->{title}}->{max} = 0       unless $MAX->{$conf->{title}}->{max};

                foreach my $name (keys %{$werte}) {
                        next if ref $werte->{$name};
                        my $value = $werte->{$name} || 0;
                        $MAX->{$conf->{title}}->{max} = $value if( $MAX->{$conf->{title}}->{max} <= $value );
                        $MAX->{$conf->{title}}->{min} = $value if( $MAX->{$conf->{title}}->{min} >= $value );                        $MAX->{$conf->{title}}->{avg} =
                        $MAX->{$conf->{title}}->{avg} =
                                ( $MAX->{$conf->{title}}->{max} - $MAX->{$conf->{title}}->{min} ) / 2 +
                                        $MAX->{$conf->{title}}->{min};
                }
                $conf->{max_value} = $self->cget(-max)
                        ? $self->cget(-max)
                        : $MAX->{$conf->{title}}->{max} * $conf->{headroom};
        }

	$conf->{max_value} = 1 unless($conf->{max_value});

        # MAX-MIN Linien
        if($self->cget(-maxmin) && $conf->{max_value} && ! $conf->{type} eq 'CIRCLE') {
                my $xa = $conf->{x_null};
                my $xe = $conf->{width}+10;
                my $y = $conf->{y_null} - int((($conf->{y_null})/$conf->{max_value}) * $MAX->{$conf->{title}}->{min});

                if($conf->{type} !~ /BARS/) {
                        $self->createLine($xa, $y, $xe, $y,
                                -width => 1,
                                -fill  => 'gray65');    # MIN-Linie

                        $self->createText($xe-20, $y,
                                -text => sprintf($self->cget(-printvalue) || '%g', $MAX->{$conf->{title}}->{min}),
                                -anchor => 'se',
                                -font => $conf->{font},
                                -fill => 'gray65');


                        $y = $conf->{y_null} - int((($conf->{y_null})/$conf->{max_value}) * $MAX->{$conf->{title}}->{avg});
                        $self->createLine($xa, $y, $xe, $y,
                                -width => 1,
                                -fill  => 'gray65');    # AVG-Linie

                        $self->createText($xe-20, $y,
                                -text => sprintf($self->cget(-printvalue) || '%g', $MAX->{$conf->{title}}->{avg}),
                                -anchor => 'se',
                                -font => $conf->{font},
                                -fill => 'gray65');



                        $y = $conf->{y_null} - int((($conf->{y_null})/$conf->{max_value}) * $MAX->{$conf->{title}}->{max}),
                        $self->createLine($xa, $y, $xe, $y,
                                -width => 1,
                                -fill  => 'gray65');    # AVG-Linie

                        $self->createText($xe-20, $y,
                                -text => sprintf($self->cget(-printvalue) || '%g', $MAX->{$conf->{title}}->{max}),
                                -anchor => 'se',
                                -font => $conf->{font},
                                -fill => 'gray65');
                }
        }
        # --

}


#-------------------------------------------------
sub draw_circle {
#-------------------------------------------------
        # Plot LineStats
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || return;

	# Check
	return warn("Your data is incorrect, i need a Hashreference!")
		unless(ref $data eq 'HASH');


        my $werte = $self->reference($data);
        my $conf = $self->ReadConfig($werte) || return;

        $self->delete('all');

        # MaxMin Werte ermitteln und ggf Linien zeichnen
        $self->maxmin($conf, $werte);

        # Axis (Titel ... usw
        $self->axis($conf, $werte);

        # Sizes
        my $width = ($self->cget(-legend) ? $conf->{height} : $conf->{width});
        my $height = $conf->{y_null};

        # Shadow
        $self->createOval(
                        ($conf->{x_null} + $self->cget(-shadowdepth) ), ($conf->{ypad_top} + $self->cget(-shadowdepth)),
                        ($width + $self->cget(-shadowdepth)), ($height + $self->cget(-shadowdepth)),
                -fill => $self->cget(-shadow),
                -outline => $self->cget(-shadow),
                -width => 0,
                ) if($self->cget(-shadowdepth));         # Schatten

        # Segments
        my ($summe, $start, $count, $grad, $x, $y);
        foreach ( keys %$werte ) { $summe+=$werte->{$_} };
        $start = 0;
        $count = 0;

        foreach my $name (sort { $self->sorter } keys %$werte ) {
                my $col = $self->{colors}->{$name};
                next unless $werte->{$name};
                $grad = (360/$summe) * $werte->{$name};
                $grad = 359.99 if($grad == 360);

                $self->{elements}->{$name} = $self->createArc(
                                $conf->{x_null}, $conf->{ypad_top},
                                $width, $height,
                        -width => $self->cget(-linewidth),
                        -fill => $col,
                        -start => $start,
                        -extent => $grad,
                        );

                $start+=$grad;
        }

        # balloon
        $self->balloon($self->{elements}, $werte);

	# Legend
	$self->legend($werte);
}

#-------------------------------------------------
sub labels {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
	my $conf = $self->{cfg};

	# X-Achse --------------------------------
	if($self->cget(-xlabel)) {
		$self->createLine(
			$conf->{width} - ($conf->{width} / 10), 	$conf->{y_null} - 10,
			$conf->{width} - 5, 				$conf->{y_null} - 10,
			-arrow	=> 'last',
			-fill	=> $conf->{fg},
		);

	        $self->createText(
	        	$conf->{width} - ($conf->{width} / 10) - 5, $conf->{y_null} - 10,
		                -text => $self->cget(-xlabel),
				-font => $conf->{font},
				-fill	=> $conf->{fg},
		                -anchor => 'e',
	                );
	}
	# ---------------------------------------

	# Y-Achse --------------------------------
	if($self->cget(-ylabel)) {
		$self->createLine(
			$conf->{x_null} + 10, $conf->{ypad_top} - 5,
			$conf->{x_null} + 10, $conf->{ypad_top} + ($conf->{height} / 10),
			-arrow	=> 'first',
			-fill	=> $conf->{fg},
		);

	        $self->createText(
			$conf->{x_null} + 15, $conf->{ypad_top} + ($conf->{height} / 10),
		                -text => $self->cget(-ylabel),
				-font => $conf->{font},
		                -anchor => 'w',
				-fill	=> $conf->{fg},
	                );
	}
	# ---------------------------------------

}


#-------------------------------------------------
sub legend {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
	my $data = shift || return error("No Data!");
	my $conf = $self->{cfg};
	return unless($self->cget(-legend));

        my $c = 0;
	my $fw = $self->cget(-lineheight) || 15;

	foreach my $name (sort { $self->sorter } keys %$data) {
	        my $x = $conf->{width};
	        my $y = $fw + ( $fw * $c );     # XXX

	        my $thick = $self->cget(-dots) || 5;

	        $self->createRectangle($x, $y,
	                $x-$thick, $y-$thick,
	                -fill => $self->{colors}->{$name},
	                -width => $self->cget(-linewidth),
	                );

	        $self->createText($x - ($thick*2), $y,
	                -text => sprintf( $self->cget(-printvalue) || '%s: %s', $name, (ref $data->{$name} ? '' : $data->{$name}) ),
			-font	=> $conf->{font},
	                -anchor => 'e',
			-fill	=> $conf->{fg},
	                );
		$c++
	}
}


#-------------------------------------------------
sub readData {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $c = $self->configure;
        my $config;
        foreach my $n ($c) {
                $config->{$n->[0]} = $n->[3];
        }
}


#-------------------------------------------------
sub wire {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $conf = shift || warn "No Conf";
        my $data = shift;

	return unless( $self->cget(-wire) );

	# 3D
	my $td = $self->cget(-threed) || 0;
# XXX More as one linegraphs in deep
#	$td *= scalar keys %$data;

        # Y-Achse
        my $ytick = ($conf->{type} eq 'HBARS' ? $conf->{count} : $self->cget(-ytick));
   	   $ytick = 1 unless $ytick;

        for (my $i = 0; $i <= $ytick; $i++) {
                my $y = ($conf->{y_null}) - (round( ( $conf->{y_null} - $conf->{ypad_top} )/$ytick) * $i);
                $self->createLine(
                    $conf->{x_null}, $y,
                    ($conf->{x_null} + $td), ($y - $td),
                    ($conf->{width} + $td), ($y - $td),
                    -width => 1,
                    -fill  => ($i >= $ytick ? $self->cget(-foreground) : $self->cget(-wire)),
                  );
        }

        # X-Achse
        my $xtick = ( $conf->{typ} eq 'HASH' && $conf->{type} ne 'HBARS' && $conf->{type} ne 'LINE' ? $conf->{count} : $self->cget(-xtick) );
	   $xtick = 1 unless $xtick;

        if($conf->{type} eq 'HBARS' || $conf->{type} eq 'LINE') {
	        for(my $i = 0; $i <= $xtick; $i++) {
	                my $x = $conf->{x_null} + (round( ($conf->{width} - $conf->{x_null})/$self->cget(-xtick)) * $i);

	                $self->createLine(
	                    $x, $conf->{y_null}, ($x + $td),
	                    ($conf->{y_null} - $td), ($x + $td),
	                    ($conf->{ypad_top} - $td),
	                    -width => 1,
	                    -fill  => ( $i >= $xtick ? $self->cget(-foreground) : $self->cget(-wire))
	                  );
	        }
	} else {
	        for(my $i = 0; $i <= $xtick; $i++) {
			my $x;
			if( $i < $xtick ) {
                                $x = $self->calc_x($i+1);
			} else {
 				$x = $conf->{width};
			}
	                $self->createLine(
	                    $x, $conf->{y_null}, ($x + $td),
	                    ($conf->{y_null} - $td), ($x + $td),
	                    ($conf->{ypad_top} - $td),
	                    -width => 1,
	                    -fill  => ( $i >= $xtick ? $self->cget(-foreground) : $self->cget(-wire))
	                  );
	        }
	}
}

#-------------------------------------------------
sub config {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || return;
        my $cols = $self->cget(-colors);
        my @colors = split(/,/, $cols);
        my $config = $self->cget(-config);
        my $c = -1;

        foreach my $name( keys %$data) {
                next if(defined $self->{colors}->{$name} && ! defined $config->{$name});
                $c++;
                $c = -1 unless($colors[$c]);

		my $name_new  = $config->{$name}->{'-title'}
			if(defined $config->{$name}->{'-title'});

                # Colors
                $self->{colors}->{($name_new || $name)} = $config->{$name}->{'-color'} || $colors[$c];

                # Ranges
		if($config->{$name}->{'-range'}) {
                	$self->{ranges}->{($name_new || $name)} = $config->{$name}->{'-range'};
		}

                # Title
                if($config->{$name}->{'-title'}) {
                        $data->{$config->{$name}->{'-title'}} = delete $data->{$name};
                        $self->{data} = $data;
                }

        }
}

#-------------------------------------------------
sub register {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || return $self->{look};

        foreach my $name (keys %$data) {
                $self->{look}->{$name} = $data->{$name};
        }
}


#-------------------------------------------------
sub look {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $data = shift || $self->{data} || return;
        return unless($self->cget(-look));

        foreach my $name (keys %$data) {
                push(@{$self->{look}->{$name}}, $data->{$name});
                splice(@{$self->{look}->{$name}}, 0, ($#{$self->{look}->{$name}} - $self->cget(-look)))
                        if($#{$self->{look}->{$name}} >= $self->cget(-look));
        }
}

#-------------------------------------------------
sub sorter {
#-------------------------------------------------
	my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $typ = shift || $self->cget(-sortnames);

	if($self->cget(-sortreverse)) {
	        if($typ eq 'num') {
	                $b <=> $a
	        } else {
	                $b cmp $a
	        }
	} else {
	        if($typ eq 'num') {
	                $a <=> $b
	        } else {
	                $a cmp $b
	        }
	}

}

#-------------------------------------------------
sub balloon{
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return; # XXX produce Memory Leaks

	return undef unless(ref $self eq __PACKAGE__);
	my $elements = shift || return;
	my $werte = shift || return error('No Values');
	my $bh;

	foreach my $name (keys %$werte) {
		my $wert = (ref $werte->{$name} eq 'ARRAY' ? $werte->{$name}->[$#{$werte->{$name}}]  : $werte->{$name});
		$bh->{$elements->{$name}} =
			sprintf(
				$self->cget(-printvalue) || ($name && $wert ? '%s: %s' : '%s'), $name, $wert)
					if($wert);
	}

        $self->{balloon}->attach(
                $self,
		-balloonposition => 'mouse',
		-msg => $bh,
        ) if(defined $self->{balloon});
}

#-------------------------------------------------
sub round {
#-------------------------------------------------
	my $wert = shift || return 0;
	my $ret = sprintf('%d', $wert);
#	my $ret = int( $wert + 0.99);
	return $ret;
}

#-------------------------------------------------
sub winkel {
#-------------------------------------------------
        my $a = shift;          # Width
        my $b = shift;          # Heigth

        my $c = sqrt($a**2+$b**2);

        my $cos_phi = ($a**2+$c**2-$b**2) / (2*$a*$c);

        return rad2deg(acos $cos_phi);
}



#-------------------------------------------------
sub error {
#-------------------------------------------------
	my ($package, $filename, $line, $subroutine, $hasargs,
    		$wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
	my $msg = shift || return undef;
	warn sprintf("ERROR in %s:%s #%d: %s",
		$package, $subroutine, $line, sprintf($msg, @_));
	return undef;
}

#-------------------------------------------------
sub debug {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
        my $msg  = shift || return;
        return unless($self->cget(-debug));
        printf($msg, @_);
        print "\n";
}

#-------------------------------------------------
sub val2name {
#-------------------------------------------------
	my $hash = shift || return;
	my $val  = shift || return;

	foreach my $name (keys %$hash) {
		if($hash->{$name} eq $val) {
			return $name
		}
	}
}

#-------------------------------------------------
sub calc_x {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
	my $fac  = shift;
	my $conf = $self->{cfg};

	my $count = ($conf->{type} eq 'BARS' ? $conf->{count} : $self->cget(-xtick) ) + 1;


	my $erg = 	$conf->{x_null} +
			(round
			(
				( $conf->{width} - $conf->{x_null}  )
				/ $count
			) * $fac);
	$self->debug("CALC_X: Width: %d, Faktor = %d, Count: %d, Ergebniss = %d", 
			$conf->{width}, $fac, $count, $erg);

	return $erg;
}

#-------------------------------------------------
sub calc_y {
#-------------------------------------------------
        my $self = shift || return error("No Objekt!");
	return undef unless(ref $self eq __PACKAGE__);
	my $fac  = shift || 0;
	my $conf = $self->{cfg};

	my $erg = 	$conf->{y_null} -
			round(
			(
				$conf->{y_null} -
				$conf->{ypad_top}
			) / $conf->{max_value}
			* $fac );

	return $erg;
}


1;

=head1 EXAMPLES

Please see for examples in 'demos' directory in this distribution.

=head1 AUTHOR

Frank Herrmann
xpix@netzwert.ag
http://www.netzwert.ag

=head1 SEE ALSO

Tk,
Tk::Trace,
Tk::Canvas,

=cut

__END__
zwert.ag

=head1 SEE ALSO

Tk,
Tk::Trace,
Tk::Canvas,

=cut

__END__
