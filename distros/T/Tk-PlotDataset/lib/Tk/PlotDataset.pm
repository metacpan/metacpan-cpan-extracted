package Tk::PlotDataset;

=head1 NAME

Tk::PlotDataset - An extended version of the canvas widget for plotting 2D line
graphs. Plots have a legend, zooming capabilities and the option to display
error bars.

=head1 SYNOPSIS

 use Tk;
 use Tk::PlotDataset;
 use Tk::LineGraphDataset;

 my $main_window = MainWindow -> new;

 my @data1 = (0..25);
 my @errors1 = map { rand(2) } ( 0..25 );
 my $dataset1 = LineGraphDataset -> new
 (
   -name => 'Data Set One',
   -yData => \@data1,
   -yError => \@errors1,
   -yAxis => 'Y',
   -color => 'purple'
 );

 my @data2x = (0..25);
 my @data2y = ();
 foreach my $xValue (@data2x)
 {
   push (@data2y, $xValue ** 2);
 }
 my $dataset2 = LineGraphDataset -> new
 (
   -name => 'Data Set Two',
   -xData => \@data2x,
   -yData => \@data2y,
   -yAxis => 'Y1',
   -color => 'blue'
 );

 my $graph = $main_window -> PlotDataset
 (
   -width => 500,
   -height => 500,
   -background => 'snow'
 ) -> pack(-fill => 'both', -expand => 1);

 $graph -> addDatasets($dataset1, $dataset2);

 $graph -> plot;

 MainLoop;

=head1 STANDARD OPTIONS

 -background  -highlightthickness  -takefocus        -selectborderwidth
 -borderwidth -insertbackground    -relief           -tile
 -cursor      -insertborderwidth   -selectbackground -xscrollcommand
 -insertwidth -highlightbackground -insertofftime    -yscrollcommand
 -state       -highlightcolor      -insertontime     -selectforeground

=head1 WIDGET-SPECIFIC OPTIONS

In addition to all the Canvas options, the following option/value pairs are
supported. All of these options can be set with the new() method when the
PlotDataset object is created or by using configure():

=over 4

=item -colors

An array of colours to use for the display of the datasets. If there are more
datasets than colours in the array then the colours will cycle. This option
will be overwritten if the LineGraphDataset object already has a colour
assigned to it.

This option only has an effect when datasets are plotted and therefore changing
the array will not change the colour of the plots already on the graph. To
change existing plots the colour must be set in the LineGraphDataset object or
the dataset re-added to the graph.

=item -pointShapes

An array of point shapes to use for the display of the datasets. If there are
more datasets than shapes in the array then the shapes will cycle. These shapes
will be overwritten if the LineGraphDataset object already has a point shape
assigned to it. Valid shapes are none, circle, square, triangle and diamond.

Like the -colors, this option only has an effect when datasets are plotted and
therefore changing the array will not change the point shapes of the plots
already on the graph.

=item -border

An array of four numbers which are the width of the border between the plot area
and the canvas. The order is North (top), East (right), South (bottom) and West
(left). By default, the borders are 25, 50, 100 and 50 respectively.

=item -zoomButton

Selects the mouse button used for zooming in and out. The value must be a
number from 1 to 5 corresponding to the five potential mouse buttons, any other
value will disable zooming on the graph. Typically the left mouse button is 1
(default) and the right is 3.

=item -scale

A nine element array of the minimum, maximum and step values of scales on each
of the three axes - x, y, and y1. The order of the nine values is xMin, xMax,
xStep, yMin, yMax, yStep, y1Min, y1Max and y1Step. The default values for all
the axis are 0 to 100 with a step size of 10. This option will only affect axes
where the auto-scale option has been turned off.

An axis can be reversed by swapping its minimum and maximum values around.

=item -plotTitle

A two element array. The first element is the plot title, the second element is
the vertical offset of the title above the top of the graph. The title is centered
in the x direction.

=item -xlabel

The text label for the x-axis. The text is centered on the X-axis.

=item -ylabel

The text label for the y-axis. The text is centered on the Y-axis.

=item -y1label

The text label for the y1-axis, which is the optional axis to the right of the
plot. The text is centered on the y1-axis. The label will only be displayed if
there are datasets using the y1-axis.

=item -xlabelPos

The vertical position of the x-axis label, relative to the bottom of the plot
area. The default for this value is 40.

=item -ylabelPos

The vertical position of the y-axis label, relative to the left of the plot
area. The default for this value is 40.

=item -y1labelPos

The vertical position of the y1-axis label, relative to the right of the plot
area. The default for this value is 40.

=item -xTickFormat

This option can be used to override the default format strings, as used by
sprintf, to generate the tick labels on the x-axis. In linear mode the default
is '%.3g', in log mode '1e%3.2d' will be used for values less than zero and
'1e+%2.2d' will be used for values of zero or more. If you override this
format, it will apply to all values in all modes of the x-axis.

=item -yTickFormat

This option can be used to override the default format strings, as used by
sprintf, to generate the tick labels on the y-axis. In linear mode the default
is '%.3g', in log mode '1e%3.2d' will be used for values less than zero and
'1e+%2.2d' will be used for values of zero or more. If you override this
format, it will apply to all values in all modes of the y-axis.

=item -y1TickFormat

This option can be used to override the default format strings, as used by
sprintf, to generate the tick labels on the y1-axis. In linear mode the default
is '%.3g', in log mode '1e%3.2d' will be used for values less than zero and
'1e+%2.2d' will be used for values of zero or more. If you override this
format, it will apply to all values in all modes of the y1-axis. The y1-axis
ticks will only be displayed if there are datasets using the y1-axis.

=item -balloons

Should be set to a true value (eg. 1) in order to enable coordinate balloons,
or a false value (eg. 0) to disable them. Coordinate balloons are enabled by
default.

=item -legendPos

A two element array which specifies the position of the legend. The first
element specifies where the legend should be, either 'bottom' for below the
chart, and 'side' for the right side of the chart. The second element is the
distance from the edge of the chart to the legend. By default, the legend is 80
pixels below the chart.

=item -xType

The scale type of the x-axis. Can be linear or log. The default type is
linear.

=item -yType

The scale type of the y-axis. Can be linear or log. The default type is
linear.

=item -y1Type

The scale type of the y1 axis. Can be linear or log. The default type is
linear.

=item -showError

Should be set to a true value (eg. 1) to show the error bars or a false value
(eg. 0) to hide them. By default, error bars will be automatically shown for
datasets with error data.

=item -maxPoints

Sets the threshold at which the points on the plot will be marked. If the
number of points on the plot is greater than this value then individual points
will not be shown. Points for datasets with no line will always be shown. If
points are shown on a plot then so will any associated error bars.

=item -logMin

Applies to all logarithmic axes. A replacement value for zero or negative
values that cannot be plotted on a logarithmic axis. The default value is 1e-3.

=item -fonts

A four element array with the font names for the various labels in the plot.
The first element is the font of the numbers at the axes ticks, the second is
the font for the axes labels (all of them), the third is the plot title font
and fourth is the font for the legend.

 $graph -> configure
 (
   -fonts =>
   [
     'Times 8 bold',
     'Courier 8 italic',
     'Arial 12 bold',
     'Arial 10'
   ]
 );

The format for each font string is; the name of the font, followed by its size
and then whether it should be in bold, italic or underlined.

=item -autoScaleX

When set to "On" the x-axis will be scaled to the values to be plotted. Default
is "On". "Off" is the other possible value.

=item -autoScaleY

When set to "On" the y-axis will be scaled to the values to be plotted. Default
is "On". "Off" is the other possible value.

=item -autoScaleY1

When set to "On" the y1-axis will be scaled to the values to be plotted.
Default is "On". "Off" is the other possible value.

=item -redraw

A subroutine that is called when the graph is redrawn. It can be used to redraw
widgets, such as buttons, that have been added to the graph's canvas. Without
the subroutine anything on the graph would be overwritten.

 $graph -> configure
 (
   -redraw => sub
   {
     my $button = $graph -> Button(-text => 'Button');
     $graph -> createWindow
     (
       $graph -> cget(-width) - 8, $graph -> cget(-height) - 8,
       -anchor => 'se', -height => 18, -width => 100,
       -window => $button
     );
   }
 );

=back

=head2 Tk::LineGraphDataset Options

In addition to the standard options of the LineGraphDataset module, it is also
possible to use additional options for use with PlotDataset. Please note that
these options will only have an effect on PlotDataset and no other module and
hence are not documented in LineGraphDataset.

=over 4

=item -yError

Array of numeric values used to indicate the error, or uncertainty in the y-data.
This is an optional array, but if it is specified it must be the same length as the
-yData array. By default, Tk::PlotDataset will display error bars for any dataset
with error data. Error values are assumed to be symmetrical i.e. positive error
margin is the same as the negative error margin. Only the magnitude of the error
data is used, so the sign of negative values will always be ignored.

=item -pointSize

Sets the size of the points in the dataset's plot. The value can be any
positive integer. The default for this value is 3.

=item -pointStyle

A string which sets the shape of the point for the dataset's plot. Setting this
option will override Tk::PlotDataset's -pointShapes option for the dataset.
Like the -pointShapes option, valid shapes are none, circle, square, triangle
and diamond.

=item -lineStyle

A string which sets the pattern of the line for the dataset's plot. Valid
patterns are normal (solid line), dot, dash, dotdash and none. By default, all
lines will be solid.

=item -fillPoint

A boolean value which determines the appearance of the dataset's points. If the
value is true (eg. 1), the point is a solid colour, otherwise (eg. 0) only an
outline of the point is shown. By default, all points will be filled.

=back

=head1 DESCRIPTION

PlotDataset is a quick and easy way to build an interactive plot widget into a
Perl application. The module is written entirely in Perl/Tk.

The widget is an extension of the Canvas widget that will plot LineGraphDataset
objects as lines onto a 2D graph. The axes can be automatically scaled or set by
the code. The axes can have linear or logarithmic scales and there is also an
option of an additional y-axis (y1).

By default, plots for datasets which contain error data will include error bars.

=head2 Behaviour

When the mouse cursor passes over a plotted line or its entry in the legend,
the line and its entry will turn red to help identify it. Holding the cursor
over a point on the graph will display the point's coordinates in a help
balloon (unless disabled). Individual points are not shown when the number of
points in the plot is greater than the value set by the -maxPoints option. The
default number of points is 20.

By default, the left button (button-1) is used to zoom a graph. Move the cursor
to one of the corners of the box into which you want the graph to zoom. Hold
down the mouse button and move to the opposite corner. Release the mouse button
and the graph will zoom into the box. To undo one level of zoom click the mouse
button without moving the cursor.

=head1 WIDGET METHODS

The PlotDataset (or new) method creates a widget object. This object supports
the configure and cget methods described in the Tk::options manpage, which can
be used to enquire and modify the options described above (except -colors and
-pointShapes). The widget also inherits all the methods provided by the
Tk::Canvas class.

In addition, the module provides its own methods, described below:

=over 4

=item $plot_dataset -> addDatasets ( dataset1 , dataset2 , ... )

Adds one or more dataset objects to the plot. Call the plot() method afterwards
to see the newly added datasets.

=item $plot_dataset -> clearDatasets

Removes all the datasets from the plot. Call the plot() method afterwards to
clear the graph.

=item $plot_dataset -> plot ( rescale )

Updates the graph to include changes to the graph's configuration or datasets.
The parameter rescale can be one of three options:

=over 4

=item Z<>

'always' to always rescale plot. This is the default.

'never' to never rescale plot.

'not_zoomed' to only rescale when the plot is not zoomed in.

=back

B<Note:> Changes to the graph's configuration or datasets will also be applied
when the graph is rescaled when zooming in or out.

=back

=head1 HISTORY

This Tk widget is based on the Tk::LineGraph module by Tom Clifford. Due to
trouble with overriding methods that call methods using SUPER:: LineGraph could
not be used as a base class.

The main difference between this module and the original is that the graph is
created as a widget and not in a separate window. It therefore does not have
the drop down menus used to configure the graph in the original.

Other additions/alterations are:

=over 4

=item Z<>

- Used Tk::Balloon to add optional coordinate pop-ups to data points.

- Running the cursor over a line name in the legend will highlight the curve on
the graph.

- Added a clearDatasets method for removing all datasets from a plot.

- Added support for a -noLegend option for datasets, allowing them to be
excluded from the legend.

- Added support for the -pointSize, -pointStyle, -lineStyle and -fillPoint
LineGraphDataset options.

- Added -redraw option to allow a callback to be added to draw additional items
onto the canvas when it is redrawn.

- Option for a logarithmic scale on the x-axis (previously this was only
available on the y-axis).

- Changed the legend so that it displays an example line and point. This legend
can be either at the bottom or side of the chart.

- Added -xTickFormat, -yTickFormat and -y1TickFormat options to configure the
format of the number labels on each axis.

- Removed all bindings to the mouse buttons except for zooming. The mouse
button used for zooming can be configured.

- Support for plotting y-error bars added by Thomas Pissulla.

=back

A number of bugs in the original code have also been found and fixed:

=over 4

=item Z<>

- Plots could be dragged using button 3 - this is not useful.

- If less than ten colours were provided, then the colour usage failed to cycle
and caused an error.

- If the user zooms beyond a range of approximately 1e-15, then it hangs.

- Scale values of 0 were frequently displayed as very small numbers
(approximately 1e-17).

- Small grey boxes were sometimes left behind when zooming out.

- In places, -tags was passed a string instead of an array reference, which
caused problems especially in the legends method.

- Corrected an issue with the positioning of the y1 axis label.

- Corrected a divide by zero error occurring when a vertical data line passes
through a zoomed plot.

- Fixed a memory leak that occurred when the value passed to the configure
method was an array reference.

=back

=head1 BUGS

Currently there are no known bugs, but there are a couple of the limitations to
the module:

=over 4

=item Z<>

- If no data on the graph is plotted on the y-axis, i.e. the y1-axis is used
instead, then it is not possible to zoom the graph. It will also not be
possible to zoom the graph if y1-axis has a log scale but no data.

- In the case where the number of points in the x and y axes are different the
points with missing values are not plotted.

- Currently, if zero or negative numbers are plotted on a logarithmic scale
their values are set to the value of -logMin. This can produce strange looking
graphs when using mixed type axes. A future improvement would be to provide an
option to omit non-valid points from the graph.

- The widget does not work with the Tk::Scrolled module.

=back

=head1 COPYRIGHT

Copyright 2016 I.T. Dev Ltd.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Any code from the original Tk::LineGraph module is the copyright of Tom
Clifford.

=head1 AUTHOR

Andy Culmer, Tim Culmer and Stephen Spain.
Contact via website - http://www.itdev.co.uk

Original code for the Tk::LineGraph module by Tom Clifford.

=head1 CONTRIBUTORS

Y-Error Bars by Thomas Pissulla.
Contact via website - http://www.ikp.uni-koeln.de/~pissulla

=head1 SEE ALSO

Tk::LineGraph Tk::LineGraphDataset

=head1 KEYWORDS

Plot 2D Axis

=cut

# Internal Revision History
#
# Filename : PlotDataset.pm
# Authors  : ac - Andy Culmer, I.T. Dev Limited
#            tc - Tim Culmer, I.T. Dev Limited
#            ss - Stephen Spain, I.T. Dev Limited
#
#            pi - Thomas Pissulla, Institute for Nuclear Physics, University of Cologne
#
# Version 1 by ac on 19/12/2006
# Initial Version, modified from Tk::LineGraph.
#
# Version 2 by ac on 05/01/2007
# Changed the resize behaviour to allow the graph to be used with other widgets
# in the same window. This makes this widget more consistent with other Tk
# widgets.
#
# Version 3 by ac on 10/01/2007
# Added clearDatasets method to remove all datasets from a plot.
# Added support for a -noLine option for datasets, allowing them to be plotted
# points only.
# Added support for a noLegend option for datasets, allowing them to be excluded
# from the legend.
#
# Version 4 by ac on 23/01/2007
# Added -redraw option to allow a callback to be added to draw additional items
# onto the canvas when it is redrawn. Also corrected an issue with the
# positioning of the Y1 axis label.
#
# Version 5 by ac on 06/03/2007
# Corrected a divide by zero error occurring when a vertical data line passes
# through a zoomed plot.
#
# Version 6 by tc on 04/04/2007
# Prepared the module for submitting to CPAN.
#  * Removed unused code.
#  * Renamed the variables that use the reserved $a and $b variable names.
#  * Attempted to make the original TK::LineGraph source code conform to the
#    I.T. Dev coding standard.
#  * Added an option for a logarithmic scale on the x-axis.
#  * Added to original POD documentation.
#
# Version 7 by tc on 14/05/2007
# Fixed a couple of issues that occur when using log axes:
#  * When using autoscale a log axis will always include an extra set of ticks
#    than is needed.
#  * If the y or y1 axis is longer than the x axis then the axis ticks are
#    labelled with the font information.
#  * The y1 axis has no log ticks.
#
# Version 8 by ss on 16/05/2007
# Added some extra functionality
#  * Added -lineStyle dataset option to set the style of a line.
#  * Added -pointStyle dataset option to set the style of a point.
#  * Added -pointSize dataset option to set the size of a point
#  * Added -fillPoint dataset option to set whether a point should be filled.
#  * Added -xlabelPos, -ylabelPos, and -y1labelPos plot options to specify
#    the distance these labels should be from the plot area.
#  * Added extra information to the legend, to show the line style and point
#     style for each line.
#  * Added -legendPos plot option to allow the legend to be placed either at
#    the side or bottom of the plot area, and specify the distance between the
#    legend and the plot area.
# Fixed some issues:
#  * When no x data was specified _data_sets_min_max() assumed there was one
#    extra data point on the x axis, so scaled wrongly.
#  * Graphs with '-noLine' set, but less than 20 points on the screen are not
#    visible until the user zooms.
#  * Fixed a problem with the alignment of the x-axis label.
#  * Fixed a problem with the alignment of the title.
#
# Version 9 by ss on 23/05/2007
# Fixed a problem with legend where a line was shown when -lineStyle was set to
# none.
#
# Version 10 by tc on 01/06/2007
# Modified code to meet I.T. Dev Perl Coding Standard and to comply more with
# the perlstyle documentation. Functionality not changed.
#
# Version 11 by ac on 06/11/2007
# New features:
#  * Added -xTickFormat, -yTickFormat and -y1TickFormat options to configure
#    the format of the number labels on each axis.
#  * Added -balloons option to enable/disable the coordinates balloons.
# Bug fixes:
#  * Fixed a memory leak that occurred when the value passed to the configure
#    method was an array reference.
#
# Version 12 by tc on 09/11/2007
# Documented the additional LineGraphDataset options supported by the module.
# Removed support for the -noLine option in LineGraphDataset - its
# functionality is now incorporated in the -lineStyle option.
#
# Version 13 by tc on 02/01/2008
# Wraps legend when it is displayed at the bottom of the graph. Added the
# -zoomButton option.
#
# Version 14 by tc on 02/11/2012
# Added support for reversing an axis by swapping its minimum and maximum
# scale values around.
#
# Version 15 by pi on 11/04/2013
# Added support for y-error bars.
#
# Version 16 by sd on 15/08/2016
# Fixed double usage of my in declaration of variable.

use strict;
use warnings;

use 5.005_03;

use Carp;
use POSIX;
use base qw/Tk::Derived Tk::Canvas/;
use Tk::Balloon;
use vars qw($VERSION);

$VERSION = '2.05';

Construct Tk::Widget 'PlotDataset';

sub ClassInit  ## no critic (NamingConventions::ProhibitMixedCaseSubs)
{
  my ($class, $mw ) = @_;
  $class -> SUPER::ClassInit($mw);

  return (1);
}

# Class data to track mega-item items. Not used as yet.
my $id = 0;
my %ids = ();

sub Populate  ## no critic (NamingConventions::ProhibitMixedCaseSubs)
{
  my ($self, $args) = @_;

  my @def_colors =
  qw/
    gray SlateBlue1 blue1 DodgerBlue4 DeepSkyBlue2 SeaGreen3
    green4 khaki4 gold3 gold1 firebrick1 brown4 magenta1 purple1 HotPink1
    chocolate1 black
  /;
  my @def_point_shapes = qw/circle square triangle diamond/;
  $self -> ConfigSpecs
  (
    -colors       => ['PASSIVE', 'colors',       'Colors',       \@def_colors],
    -pointShapes  => ['PASSIVE', 'pointShapes',  'PointShapes',  \@def_point_shapes],
    -border       => ['PASSIVE', 'border',       'Border',       [25, 50, 100, 50]],
    -scale        => ['PASSIVE', 'scale',        'Scale',        [0, 100, 10, 0, 100, 10, 0, 100, 10]],
    -zoom         => ['PASSIVE', 'zoom',         'Zoom',         [0, 0, 0, 0, 0]],
    -plotTitle    => ['PASSIVE', 'plottitle',    'PlotTitle',    ['Default Plot Title', 25 ]],
    -xlabel       => ['PASSIVE', 'xlabel',       'Xlabel',       'X Axis Default Label'],
    -ylabel       => ['PASSIVE', 'ylabel',       'Ylabel',       'Y Axis Default Label'],
    -y1label      => ['PASSIVE', 'Y1label',      'Y1label',      'Y1 Axis Default Label'],
    -xlabelPos    => ['PASSIVE', 'xlabelPos',    'XlabelPos',    40],
    -ylabelPos    => ['PASSIVE', 'ylabelPos',    'YlabelPos',    40],
    -y1labelPos   => ['PASSIVE', 'Y1labelPos',   'Y1labelPos',   40],
    -xTickLabel   => ['PASSIVE', 'xticklabel',   'Xticklabel',   undef],
    -yTickLabel   => ['PASSIVE', 'yticklabel',   'Yticklabel',   undef],
    -y1TickLabel  => ['PASSIVE', 'y1ticklabel',  'Y1ticklabel',  undef],
    -xTickFormat  => ['PASSIVE', 'xtickformat',  'Xtickformat',  undef],
    -yTickFormat  => ['PASSIVE', 'ytickformat',  'Ytickformat',  undef],
    -y1TickFormat => ['PASSIVE', 'y1tickformat', 'Y1tickformat', undef],
    -balloons     => ['PASSIVE', 'balloons',     'Balloons',     1],
    -legendPos    => ['PASSIVE', 'legendPos',    'LegendPos',    ['bottom', 80]],
    -xType        => ['PASSIVE', 'xtype',        'Xtype',        'linear'],  # could be log
    -yType        => ['PASSIVE', 'ytype',        'Ytype',        'linear'],  # could be log
    -y1Type       => ['PASSIVE', 'y1type',       'Y1type',       'linear'],  # could be log
    -fonts        => ['PASSIVE', 'fonts',        'Fonts',        ['Arial 8', 'Arial 8', 'Arial 10 bold', 'Arial 10']],
    -autoScaleY   => ['PASSIVE', 'autoscaley',   'AutoScaleY',   'On'],
    -autoScaleX   => ['PASSIVE', 'autoscalex',   'AutoScaleX',   'On'],
    -autoScaleY1  => ['PASSIVE', 'autoscaley1',  'AutoScaleY1',  'On'],
    -showError    => ['PASSIVE', 'showError',    'ShowError',    1],
    -maxPoints    => ['PASSIVE', 'maxPoints',    'MaxPoints',    20],
    -logMin       => ['PASSIVE', 'logMin',       'LogMin',       0.001],
    -redraw       => ['PASSIVE', 'redraw',       'Redraw',       undef],
    -zoomButton   => ['PASSIVE', 'zoomButton',   'ZoomButton',   1]
  );

  $self -> SUPER::Populate($args);

  #helvetica Bookman Schumacher
  # The four fonts are axis ticks[0], axis lables[1], plot title[2], and legend[3]
  $self -> {-logCheck} = 0; # false, don't need to check on range of log data
  # OK, setup the dataSets list
  $self -> {-datasets}  = []; # empty array, will be added to
  $self -> {-zoomStack} = []; # empty array which will get the zoom stack

  # Some bindings here
  # Add ballon help for the data points...
  my $parent = $self -> parent; # ANDY
  $self -> {Balloon} = $parent -> Balloon;
  $self -> {BalloonPoints} = {};
  $self -> {Balloon}
    -> attach($self, -balloonposition => 'mouse', -msg => $self -> {BalloonPoints});

  # Must use Tk:: here to avoid calling the canvas::bind method
  $self -> Tk::bind('<Configure>' => [\&_resize]);

  return (1);
} # end Populate

# When using the inherited configure method, array items cause
# memory leaks, so these will be handled by this method instead.
sub configure ## no critic (RequireFinalReturn) - Does not recognise return statement at end of method
{
  my ($self, %args) = @_;

  foreach my $array_item (qw/-scale -xTickLabel -yTickLabel -y1TickLabel
    -border -zoom -plotTitle -fonts -colors -legendPos/)
  {
    if (my $value = delete $args{$array_item})
    {
      $self -> {'Configure'}{$array_item} = $value;
    }
  }

  if (my $value = delete $args{-zoomButton})
  {
    $self -> _set_zoom_button($value);
  }

  if (my @args = %args)
  {
    return ($self -> SUPER::configure(@args));
  }

  return (1);
}

sub _resize  # called when the window changes size (configured)
{
  my ($self) = @_;  # This is the canvas (Plot)

  my $w = $self -> width;     # Get the current size
  my $h = $self -> height;
  # print "_resize: mw size is ($h, $w)\n";
  $self -> _rescale;

  return (1);
}

sub _rescale  # all, active, not
{
  # _rescale the plot and redraw. Scale to  all or just active as per argument
  my ($self, $how, %args)  = @_;
  $self -> delete('all');  # empty the canvas, erase
  $self -> _scale_plot($how) if (defined($how) and $how ne 'not');  # Get max and min for scalling
  $self -> _draw_axis;       # both x and y for now
  $self -> _titles;
  $self -> _draw_datasets(%args);
  $self -> _legends(%args);
  $self -> _call_redraw_callback;

  return (1);
}

sub _call_redraw_callback
{
  my ($self) = @_;
  if (my $callback = $self -> cget(-redraw))
  {
    $callback = [$callback] if (ref($callback) eq 'CODE');
    die "You must pass a list reference when using -redraw.\n"
      unless ref($callback) eq 'ARRAY';
    my ($sub, @args) = @$callback;
    die "The array passed with the -redraw option must have a code reference as it's first element.\n"
      unless ref($sub) eq 'CODE';
    &$sub($self, @args);
  }
  return (1);
}

sub _set_zoom_button
{
  my ($self, $new_button) = @_;

  my $current_button = $self -> cget(-zoomButton);

  # Remove current bindings if any exist
  if (defined($current_button) and $current_button =~ m/^[1-5]$/)
  {
    $self -> Tk::bind('<Button-' . $current_button . '>',        undef);
    $self -> Tk::bind('<ButtonRelease-' . $current_button . '>', undef);
    $self -> Tk::bind('<B' . $current_button . '-Motion>',       undef);
  }

  # Apply new bindings if value is a valid mouse button
  if ($new_button =~ m/^[1-5]$/)
  {
    $self -> Tk::bind('<Button-' . $new_button . '>',        [\&_zoom, 0]);
    $self -> Tk::bind('<ButtonRelease-' . $new_button . '>', [\&_zoom, 1]);
    $self -> Tk::bind('<B' . $new_button . '-Motion>',       [\&_zoom, 2]);
  }

  # Set -zoomButton option in object
  $self -> {'Configure'}{-zoomButton} = $new_button;

  return (1);
}

sub _zoom
{
  # start to do the zoom
  my ($self, $which) = @_;
  my $z;
  # print "_zoom: which is <$which> self <$self> \n"if ($which == 1  or $which == 3);
  if ($which == 0)  # button 1 down
  {
    my $e = $self -> XEvent;
    $z = $self -> cget('-zoom');
    $z -> [0] = $e -> x; $z -> [1] = $e -> y;
    $self -> configure('-zoom' => $z);
  }
  elsif ($which == 1)  # button 1 release, that is do zoom
  {
    my $e = $self -> XEvent;
    $z = $self -> cget('-zoom');
    $z -> [2] = $e -> x; $z -> [3] = $e -> y;
    $self -> configure('-zoom' => $z);
    # OK, we can now do the zoom
    # print "_zoom: $z -> [0], $z -> [1] $z -> [2], $z -> [3] \n";

    # If the box is small we undo one level of zoom
    if ((abs($z -> [0]-$z -> [2]) < 3) and (abs($z -> [1]-$z -> [3]) < 3))
    {
      # try to undo one level of zoom
      if (@{$self -> {'-zoomStack'}} == 0)  # no zooms to undo
      {
        $z = $self -> cget('-zoom');
        $self -> delete($z -> [4])if ($z -> [4] != 0);
        return;
      }

      my $s = pop(@{$self -> {'-zoomStack'}});
      # print "_zoom: off stack $s -> [3], $s -> [4] \n";
      $self -> configure(-scale => $s);
      if ($self -> cget('-xType') eq 'log')
      {
        my ($aa, $bb) = (10**$s -> [0], 10**$s -> [1]);
        # print "_zoom: a $aa b $bb \n";
        my ($x_min_p, $x_max_p, $x_intervals, $tick_labels) = $self -> _log_range
        (
          $aa, $bb,
          -tickFormat => $self -> cget('-xTickFormat')
        );
        # print "_zoom: $tick_labels \n";
        $self -> configure(-xTickLabel => $tick_labels);
      }
      if ($self -> cget('-yType') eq 'log')
      {
        my ($aa, $bb) = (10**$s -> [3], 10**$s -> [4]);
        # print "_zoom: a $aa b $bb \n";
        my ($y_min_p, $y_max_p, $y_intervals, $tick_labels) = $self -> _log_range
        (
          $aa, $bb,
          -tickFormat => $self -> cget('-yTickFormat')
        );
        # print "_zoom: $tick_labels \n";
        $self -> configure(-yTickLabel => $tick_labels);
      }
      if ($self -> cget('-y1Type') eq 'log')
      {
        my ($aa, $bb) = (10**$s -> [6], 10**$s -> [7]);
        # print "_zoom: for y1 log  $aa b $bb \n";
        my ($y_min_p, $y_max_p, $y_intervals, $tick_labels) = $self -> _log_range
        (
          $aa, $bb,
          -tickFormat => $self -> cget('-y1TickFormat')
        );
        # print "_zoom: y1 $tick_labels \n";
        $self -> configure(-y1TickLabel => $tick_labels);
      }
    }
    else  # box not small, time to zoom
    {
      my ($x1w, $y1w, $y11w) = $self -> _to_world_points($z -> [0], $z -> [1]);
      my ($x2w, $y2w, $y12w) = $self -> _to_world_points($z -> [2], $z -> [3]);
      my $z; #holdem
      if ($x1w > $x2w)
      {
        $z = $x1w;
        $x1w = $x2w;
        $x2w = $z;
      }
      if ($y1w > $y2w)
      {
        $z = $y1w;
        $y1w = $y2w;
        $y2w = $z;
      }
      if ($y11w > $y12w)
      {
        $z = $y11w;
        $y11w = $y12w;
        $y12w = $z;
      }

      # We've had trouble with extreme zooms, so trap that here...
      if (($x2w - $x1w < 1e-12) or ($y2w - $y1w < 1e-12) or ($y12w - $y11w < 1e-12))
      {
        $z = $self -> cget('-zoom');
        $self -> delete($z -> [4]) if ($z -> [4] != 0);
        return;
      }

      # push the old scale values on the zoom stack
      push(@{$self -> {'-zoomStack'}}, $self -> cget(-scale));
      # now _rescale
      # print "_zoom: Rescale ($y1w, $y2w)  ($x1w, $x2w)  \n";
      my ($y_min_p, $y_max_p, $y_intervals) = _nice_range($y1w, $y2w);
      my ($y1min_p, $y1max_p, $y1intervals) = _nice_range($y11w, $y12w);
      my ($x_min_p, $x_max_p, $x_intervals) = _nice_range($x1w, $x2w);
      my ($x_tick_labels, $y_tick_labels, $y1_tick_labels);
      if ($self -> cget('-xType') eq 'log')
      {
        ($x_min_p, $x_max_p, $x_intervals, $x_tick_labels) = $self -> _log_range
        (
          $x1w, $x2w,
          -tickFormat => $self -> cget('-xTickFormat')
        );
      }
      if ($self -> cget('-yType') eq 'log')
      {
        ($y_min_p, $y_max_p, $y_intervals, $y_tick_labels) = $self -> _log_range
        (
          $y1w, $y2w,
          -tickFormat => $self -> cget('-yTickFormat')
        );
      }
      if ($self -> cget('-y1Type') eq 'log')
      {
        ($y1min_p, $y1max_p, $y1intervals, $y1_tick_labels) = $self -> _log_range
        (
          $y11w, $y12w,
          -tickFormat => $self -> cget('-y1TickFormat')
        );
      }

      # Swap minimum and maximum values if their axis has been reversed
      my $curr_scale = $self -> cget(-scale);
      ($x_min_p, $x_max_p) = ($x_max_p, $x_min_p) if ($$curr_scale[0] > $$curr_scale[1]);
      ($y_min_p, $y_max_p) = ($y_max_p, $y_min_p) if ($$curr_scale[3] > $$curr_scale[4]);
      ($y1min_p, $y1max_p) = ($y1max_p, $y1min_p) if ($$curr_scale[6] > $$curr_scale[7]);

      # print "_zoom: ($x_min_p, $x_max_p, $x_intervals)  xTickLabels <$x_tick_labels> \n";
      $self -> configure(-xTickLabel => $x_tick_labels);
      $self -> configure(-yTickLabel => $y_tick_labels);
      # print "($x_min_p, $x_max_p, $x_intervals), ($y_min_p, $y_max_p, $y_intervals), ($y1min_p, $y1max_p, $y1intervals)\n";
      $self -> configure
      (
        -scale =>
        [
          $x_min_p, $x_max_p, $x_intervals,
          $y_min_p, $y_max_p, $y_intervals,
          $y1min_p, $y1max_p, $y1intervals
        ]
      );
    }

    $self -> delete('all');
    # draw again
    $self -> _draw_axis;     # both x and y for now
    $self -> _titles;
    $self -> _draw_datasets;
    $self -> _legends;
    $self -> _call_redraw_callback;
  }
  elsif ($which == 2)  # motion, draw box
  {
    my $e = $self -> XEvent;
    $z = $self -> cget('-zoom');
    $self -> delete($z -> [4])if ($z -> [4] != 0);
    $z -> [4] = $self
      -> createRectangle($z -> [0], $z -> [1], $e -> x, $e -> y, '-outline' => 'gray');
    $self -> configure('-zoom' => $z);
  }
  return (1);
}

sub _create_plot_axis  # start and end point of the axis, other args a => b
{
  # Optional args  -tick
  # Optional args  -label
  #   An array containing colour, font and a list of text to display next to
  #   each tick.
  # Optional args  -tickFormat
  #   The sprintf format to use if -label is not provided.
  #
  # end points are in Canvas pixels
  my ($self, $x1, $y1, $x2, $y2, %args) = @_;
  my $y_axis = 0;
  if ($x1 == $x2)
  {
    $y_axis = 1;
  }
  elsif ($y1 != $y2)
  {
    die 'Cannot determine if X or Y axis desired.'
  }

  my $tick = delete $args{-tick};
  my $label = delete $args{-label};
  my $tick_format = delete $args{-tickFormat};
  $tick_format = '%.3g' unless $tick_format;
  my ($do_tick, $do_label) = map {ref $_ eq 'ARRAY'} ($tick, $label);

  $self -> createLine($x1, $y1, $x2, $y2, %args);

  if ($do_tick)
  {
    my ($tcolor, $tfont, $side, $start, $stop, $incr, $delta, $type) = @$tick;
    # start, stop are in the world system
    # $incr is space between ticks in world coordinates   $delta is the number of pixels between ticks
    # If type is log then a log axis maybe not
    my ($lcolor, $lfont, @labels);
    ($lcolor, $lfont, @labels) = @$label if $do_label;
    # print "t font <$tfont> l font <$lfont> \n";
    my $l;
    my $z = 0;  # will get $delta added to it, not x direction!
    my $tl;
    my $an;
    if ($y_axis)
    {
      $tl = $side eq 'w' ? 5 : -6; # tick length
      $an = $side eq 'w' ? 'e' : 'w' if $y_axis;  #anchor
    }
    else
    {
      $tl = $side eq 's' ? 5 : -6; # tick length
      $an = $side eq 's' ? 'n' : 's' if not $y_axis;
    }
    # do the ticks
    $incr = 1 if (abs($stop - $start) < 1e-15); # AC: Rounding errors can cause an infinite loop when range is zero!
    # This line above fixes this by detecting this case and fixing the increment to 1. (Of course, range should not be zero anyway!)
    #   print "ticks for loop $l = $start; $l <= $stop; $l += $incr\n"; # DEBUG
    for
    (
      my $l = $start;
      ($start <= $stop) ? ($l <= $stop) : ($l >= $stop);
      ($start <= $stop) ? ($l += $incr) : ($l -= $incr)
    )
    {
      if ($y_axis)
      {
        $self -> createLine
        (
          $x1 - $tl, $y2 - $z, $x1, $y2 - $z,
          %args, -fill => $tcolor,
        );
      }
      else
      {
        $self -> createLine
        (
          $z + $x1, $y1 + $tl, $z + $x1, $y2,
          %args, -fill => $tcolor,
        );
      }
      if ($do_label)
      {
        my $lbl = shift(@labels);
        if ($y_axis)
        {
          $self -> createText
          (
            $x1 - $tl, $y2 - $z, -text => $lbl,
            %args, -fill => $lcolor,
            -font => $lfont, -anchor => $an,
          ) if $lbl;
        }
        else
        {
          $self -> createText
          (
            $z + $x1, $y1 + $tl, -text => $lbl,
            %args, -fill => $lcolor,
            -font => $lfont, -anchor => $an,
          ) if $lbl;
        }
      }
      else  # default label uses tfont
      {
        $l = 0 if (($l < 1e-15) and ($l > -1e-15)); # Fix rounding errors at zero.
        if ($y_axis)
        {
          $self -> createText
          (
            $x1 - $tl, $y2 - $z, -text => sprintf($tick_format, $l),
            %args, -fill => $tcolor,
            -font => $tfont, -anchor => $an,
          );
        }
        else
        {
          $self -> createText
          (
            $z + $x1, $y1 + $tl, -text => sprintf($tick_format, $l),
            %args, -fill => $tcolor,
            -font => $tfont, -anchor => $an,
          );
        }
      }
      ($start <= $stop) ? ($z += $delta) : ($z -= $delta); # only use of delta
    }
  } # ifend label this axis

  return (1);
} # end _create_plot_axis

sub _titles
{
  # put axis titles and plot title on the plot
  # x, y, y1, plot all at once for now
  my ($self) = @_;
  my $borders = $self -> cget(-border);
  my $fonts = $self -> cget('-fonts');
  my $w = $self -> width;
  my $h = $self -> height;
  # y axis
  my $y_label = $self -> cget('-ylabel');
  my $y_label_pos = $self -> cget('-ylabelPos');
  my $y_start = $self -> _center_text_v($borders -> [0], $h - $borders -> [2], $fonts -> [1], $y_label);
  $self -> _create_text_v
  (
    $self -> _to_canvas_pixels('canvas', $borders -> [3] - $y_label_pos, $h - $y_start),
    -text => $y_label, -anchor => 's', -font => $fonts -> [1], -tag => 'aaaaa',
  );

  # Is y1 axis used for active datasets?

  # y1 axis
  my $y1label = $self -> cget('-y1label');
  my $y1label_pos = $self -> cget('-y1labelPos');
  my $y1start = $self -> _center_text_v($borders -> [0], $h - $borders -> [2], $fonts -> [1], $y1label);
  $self -> _create_text_v
  (
    $self -> _to_canvas_pixels('canvas', $w - $borders -> [1] + $y1label_pos, $h - $y1start),
    -text => $y1label, -anchor => 'sw', -font => $fonts -> [1], -tag => 'y1y1y1y1'
  ) if ($self -> _count_y1);

  #   x axis
  my $x_label = $self -> cget('-xlabel');
  my $x_label_pos = $self -> cget('-xlabelPos');
  my $x_start = $self -> _center_text($borders -> [3], $w - $borders -> [1], $fonts -> [1], $x_label);
  $self -> createText
  (
    $self -> _to_canvas_pixels('canvas', $x_start, $borders -> [2] - $x_label_pos),
    -text => $x_label, -anchor => 'sw', -font => $fonts -> [1]
  );

  # add a plot title
  my $title = $self -> cget('-plotTitle');
  $x_start = $self -> _center_text($borders -> [3], $w - $borders -> [1], $fonts -> [2], $title -> [0]);
  $self -> createText
  (
    $self -> _to_canvas_pixels('canvas', $x_start, $h - $borders -> [0] + $title -> [1]),
    text => $title -> [0], -anchor => 'nw', -font => $fonts -> [2], -tags => ['title']
  );
  return (1);
}

sub _create_text_v  # canvas widget, x, y, then all the text arguments plus -scale => number
{
  # Writes text from top to bottom.
  # For now argument -anchor is removed
  # scale is set to 0.75.  It the fraction of the previous letter's height that the
  # current letter is lowered.
  my ($self, $x, $y, %args) = @_;
  my $text = delete($args{-text});
  my $anchor = delete($args{-anchor});
  my $tag = delete($args{-tag});
  my @letters = split(//, $text);
  # print "args",  %args, "\n";;
  # OK we know that we have some short and some long letters
  # a, c, e, g, m, m, o, p, r, s, t, u, v, w, x, y, z are all short.  They could be moved up a tad
  # also g, j, q, and y hang down, the next letter has to be lower
  my $th = 0;
  my $lc = 0;

  my ($font_width) = $self -> fontMeasure($args{-font}, 'M'); # Measure a wide character to determine the x offset
  $x -= $font_width if $anchor =~ /w/; # AC: Implement missing functionality!

  # sorry to say, the height of all the letters as returned by bbox is the same for a given font.
  # same is true for the text widget.  Nov 2005!
  my $letter = shift(@letters);
  $self -> createText($x, $y + $th, -text => $letter, -tags => [$tag], %args, -anchor => 'c');  # first letter
  my ($min_x, $min_y, $max_x, $max_y) = $self -> bbox($tag);
  my $h = $max_y - $min_y;
  my $w = $max_x - $min_x;
  my $step = 0.80;
  $th = $step * $h + $th;
  foreach my $letter (@letters)
  {
    # print "_create_text_v: letter <$letter>\n";
    # If the letter is short, move it up a bit.
    $th = $th - 0.10 * $h if ($letter =~ /[acegmnoprstuvwxyz.;, :]/);  # move up a little
    $th = $th - 0.40 * $h if ($letter =~ /[ ]/);                       # move up a lot
    # now write the letter
    $self -> createText($x, $y + $th, -text => $letter, -tags => [$tag], %args, -anchor => 'c');
    # space for the next letter
    $th = $step * $h + $th;
    $th = $th + 0.10 * $h if ($letter =~ /[gjpqy.]/);  # move down a bit if the letter hangs down
    $lc++;
  }
  return (1);
}

sub _legends
{
  # For all the (active) plots, put a legend
  my ($self, %args) = @_;
  my $count = 0;
  # count the (active) data sets
  foreach my $ds (@{$self -> {-datasets}})
  {
    unless ($ds -> get(-noLegend))
    {
      $count++ if ($ds -> get('-active') == 1);
    }
  }
  # print "_legends have $count legends to do\n";
  my $fonts = $self -> cget('-fonts');

  # Calculate the starting point
  my $x_start = 0;
  my $y_start = 0;
  my $legend_info = $self -> cget('-legendPos');
  my $borders = $self -> cget('-border');
  if (not defined($legend_info) or $legend_info -> [0] eq 'bottom')
  {
    $x_start = $borders -> [3];
    $y_start = $borders -> [2] - $legend_info -> [1];
  }
  elsif ($legend_info -> [0] eq 'side')
  {
    # Find out how big text is
    my $test_tag = 'dfjcnjdbnc';
    $self -> createText
    (
      0, 10_000, -text => 'test', -anchor => 'sw', -fill => 'black',
      -font => $fonts -> [3], -tags => [$test_tag]
    );
    my ($text_min_x, $text_min_y, $text_max_x, $text_max_y) = $self -> bbox($test_tag);
    my $text_height = $text_max_y - $text_min_y;
    $self -> delete($test_tag);

    $x_start = $self -> width - $borders -> [1] + $legend_info -> [1];
    $y_start = $self -> height - $borders -> [0] - $text_height;
  }
  else
  {
    warn 'Legend position ' . $legend_info -> [0] . "is not valid\n";
  }

  my $x_pos = $x_start;
  my $y_pos = $y_start;
  foreach my $ds (@{$self -> {-datasets}})
  {
    unless ($ds -> get(-noLegend))
    {
      if ($ds -> get('-active') != 99)  # do them all, not just active
      {
        my ($x, $y) = $self -> _to_canvas_pixels('canvas', $x_pos, $y_pos);
        my $line_tag = $ds -> get('-name');
        my $point_tag = $line_tag.'point';
        my $tag = $line_tag . 'legend';

        my $fill = $ds -> get('-color');
        my $fill_point = $ds -> get('-fillPoint');
        my $point_style = $ds -> get('-pointStyle');
        my $point_size = $ds -> get('-pointSize');
        my $dash = $ds -> get('-dash');
        my $text = $ds -> get('-name');

        my $no_line = 0;
        if (defined $ds -> get('-lineStyle'))
        {
          if ($ds -> get('-lineStyle') eq 'none')
          {
            $no_line = 1;
          }
        }

        $text = ($ds -> get('-yAxis') eq 'Y1') ? $text . '(Y1) ' : $text . ' ';

        my ($textX, $textY) = $self -> _to_canvas_pixels('canvas', $x_pos + 50, $y_pos);
        $self -> createText
        (
          $textX, $textY,
          -text => $text, -anchor => 'sw', -fill => $ds->get('-color'),
          -font => $fonts -> [3], -tags => [$tag]
        );

        # Find out how big text is
        my ($text_min_x, $text_min_y, $text_max_x, $text_max_y) = $self -> bbox($tag);
        my $text_height = $text_max_y - $text_min_y;

        # Print line if necessery
        if (!$no_line)
        {
          $self -> createLine
          (
            $x, $y - $text_height / 2, $x + 40, $y - $text_height / 2, -fill => $fill,
            -dash => $dash, -tags => [$tag]
          );
        }
        $self -> _draw_point
        (
          $x + 20, $y - $text_height / 2, 0, 0,
          -fill => $fill, -pointStyle => $point_style, -pointSize => $point_size,
          -fillPoint => $fill_point, -tags => [$tag, $point_tag]
        );

        # If multiple curves, turn the line and the plot name red when we enter it with the cursor in the legend
        if (scalar(@{$self -> {-datasets}}) > 1)
        {
          $self -> bind
          (
            $tag, '<Enter>' => sub
            {
              # print "Highlighting <$line_tag> and <$tag>.\n";
              $self -> itemconfigure($point_tag, -fill => 'red');
              $self -> itemconfigure($line_tag, -fill => 'red');
              $self -> itemconfigure($tag, -fill => 'red');
            }
          );
          $self -> bind
          (
            $tag, '<Leave>' => sub
            {
              $self -> itemconfigure($line_tag, -fill => $fill);
              $self -> itemconfigure($tag, -fill => $fill);
              if ($fill_point)
              {
                $self -> itemconfigure($point_tag, -fill => $fill);
              }
              else
              {
                $self -> itemconfigure($point_tag, -fill => '');
              }
            }
          );
        }
        my ($x1, $y1, $x2, $y2) = $self -> bbox($tag);
        if (not defined($legend_info) or $legend_info -> [0] eq 'bottom')
        {
          if ($x2)
          {
            $x_pos = $x2 + 10;
            if ($y2)
            {
              # Wrap legend items if they are too wide to fit on the current line
              if ($x_pos + ($x2 - $x1) >= $self -> width)
              {
                $x_pos = $x_start;
                $y_pos = $y_pos - ($y2 - $y1);
              }
            }
          }
          else
          {
            $x_pos += 100;
          }
        }
        else
        {
          if ($y2)
          {
            $y_pos -= ($y2 - $y1) + 10;
          }
          else
          {
            $y_pos -= 100;
          }
        }
        # print "_legends location of last character p1($x1, $y1), p2($x2, $y2)\n";
      }
    }
  }
  return (1);
}

sub addDatasets  ## no critic (NamingConventions::ProhibitMixedCaseSubs)
{
  # add data sets to the plot object
  my ($self, @datasets) = @_;
  foreach my $dataset (@datasets)
  {
    unless (ref($dataset) eq 'LineGraphDataset')
    {
      warn 'addDatasets: Dataset must be a Tk::LineGraphDataset object'
    }
    else
    {
      push @{$self -> {-datasets}}, $dataset;
    }
  }
  return (1);
}

sub clearDatasets  ## no critic (NamingConventions::ProhibitMixedCaseSubs)
{
  # removes all data sets from the plot object
  my ($self) = @_;
  @{$self -> {-datasets}} = ();
  return (1);
}

sub _count_y1
{
  # count how many datasets are using y1
  my ($self) = @_;
  my $count = 0;
  foreach my $ds (@{$self -> {-datasets}})
  {
    $count++ if ($ds -> get('-yAxis') eq 'Y1');
  }
  # print "_count_y1 <$count>\n";
  return ($count);
}

sub _data_sets_min_max  # one argument, all or active
{
  # Get the min and max of the datasets
  # could be done for all datasets or just the active datasets
  # return xmin, xmax, ymin, ymax, y1min, y1max
  my ($self, $rescale) = @_;
  my $all = 0;
  $all = 1 if ($rescale and $rescale eq 'all');
  my ($first, $first1) = (0, 0);
  my ($y_max, $y_min, $x_max, $x_min, $y_max1, $y_min1) = (0, 0, 0, 0, 0, 0);
  my ($x_data, $y_data, $y_error);
  # Do x then y and y1
  foreach my $ds (@{$self -> {-datasets}})
  {
    if ($all or ($ds -> get('-active') == 1))
    {
      $y_data = $ds -> get('-yData');
      $x_data = $ds -> get('-xData');
      $x_data = [0..scalar(@$y_data) - 1]  unless (defined($x_data));
      if ($first == 0)
      {
        $x_max = $x_min = $x_data -> [0];
        $first = 1;
      }
      foreach my $e (@{$x_data})
      {
        $x_max = $e if ($e > $x_max );
        $x_min = $e if ($e < $x_min );
      }
    }
  }
  $first = $first1 = 0;
  foreach my $ds (@{$self -> {-datasets}})
  {
    if ($all or ($ds -> get('-active') == 1))
    {
      my $a = 0;

      $y_data = $ds -> get('-yData');
      $y_error = $ds -> get('-yError');

      if ($ds -> get('-yAxis') eq 'Y1')
      {
        if ($first1 == 0)
        {
          $y_max1 = $y_min1 = $y_data -> [0];
          $first1 = 1;
        }

        foreach my $e (@{$y_data})
        {
          $y_max1 = $e if ($e > $y_max1);
          $y_min1 = $e if ($e < $y_min1);

          if ($y_error)
          {
            # Make all error values positive
            $y_max1 = $e + abs($y_error -> [$a]) if ($e + abs($y_error -> [$a]) > $y_max1);
            $y_min1 = $e - abs($y_error -> [$a]) if ($e - abs($y_error -> [$a]) < $y_min1);
            $a++;
          }
        }
      }
      else
      {  # for y axis
        if ($first == 0)
        {
          $y_max = $y_min = $y_data -> [0];
          $first = 1;
        }

        foreach my $e (@{$y_data})
        {
          $y_max = $e if ($e > $y_max);
          $y_min = $e if ($e < $y_min);

          if ($y_error)
          {
            # Make all error values positive
            $y_max = $e+abs($y_error->[$a]) if ($e+abs($y_error->[$a]) > $y_max);
            $y_min = $e-abs($y_error->[$a]) if ($e-abs($y_error->[$a]) < $y_min);
            $a++;
          }
        }
      }
    }
  }
  # print "_data_sets_min_max: X($x_min, $x_max), Y($y_min, $y_max), Y1($y_min1, $y_max1)\n";
  return ($x_min, $x_max, $y_min, $y_max, $y_min1, $y_max1);
}

sub _scale_plot  # 'all'  or 'active'
{
  # scale either all the data sets or just the active ones
  my ($self, $how) = @_;
  my ($x_min, $x_max, $y_min, $y_max, $y1min, $y1max) = $self -> _data_sets_min_max($how);
  # print "_scale_plot:  min and max  ($x_min, $x_max), ($y_min, $y_max),  ($y1min, $y1max)\n";
  my ($x_tick_labels, $y_tick_labels, $y1_tick_labels);
  my ($y_min_p,  $y_max_p,  $y_intervals);
  my $scale = $self -> cget(-scale);
  if ($self -> cget(-autoScaleY) eq 'On')
  {
    ($y_min_p, $y_max_p, $y_intervals) = _nice_range($y_min, $y_max);
    if ($self -> cget('-yType') eq 'log')
    {
      ($y_min_p, $y_max_p, $y_intervals, $y_tick_labels) = $self -> _log_range
      (
        $y_min, $y_max,
        -tickFormat => $self -> cget('-yTickFormat')
      );
    }
  }
  else
  {
    ($y_min_p, $y_max_p, $y_intervals) = ($scale -> [3], $scale -> [4], $scale -> [5]);
  }
  my ($y1min_p, $y1max_p, $y1intervals);
  if ($self -> cget(-autoScaleY1) eq 'On')
  {
    ($y1min_p, $y1max_p, $y1intervals) = _nice_range($y1min, $y1max);
    if ($self -> cget('-y1Type') eq 'log')
    {
      ($y1min_p, $y1max_p, $y1intervals, $y1_tick_labels) = $self -> _log_range
      (
        $y1min, $y1max,
        -tickFormat => $self -> cget('-y1TickFormat')
      );
    }
  }
  else
  {
    ($y1min_p, $y1max_p, $y1intervals) = ($scale -> [6], $scale -> [7], $scale -> [8]);
  }
  my ($x_min_p,  $x_max_p,  $x_intervals);
  if ($self -> cget(-autoScaleX) eq 'On')
  {
    ($x_min_p, $x_max_p, $x_intervals) = _nice_range($x_min, $x_max);
    if ($self -> cget('-xType') eq 'log')
    {
      ($x_min_p, $x_max_p, $x_intervals, $x_tick_labels) = $self -> _log_range
      (
        $x_min, $x_max,
        -tickFormat => $self -> cget('-xTickFormat')
      );
    }
  }
  else
  {
    ($x_min_p, $x_max_p, $x_intervals) = ($scale -> [0], $scale -> [1], $scale -> [2]);
  }
  # print "_scale_plot: $y_min_p,  $y_max_p,  $y_intervals, @$y_tick_labels\n";
  # print "($x_min_p, $x_max_p, $x_intervals)  tickLabels <$x_tick_labels> \n";
  $self -> configure(-xTickLabel => $x_tick_labels);
  $self -> configure(-yTickLabel => $y_tick_labels);
  $self -> configure(-y1TickLabel => $y1_tick_labels);
  # print "_scale_plot: Y $y_min_p, $y_max_p, $y_intervals  X  $x_min_p, $x_max_p, $x_intervals \n";
  # put these scale values into the plot widget
  $self -> configure
  (
    -scale =>
    [
      $x_min_p, $x_max_p, $x_intervals,
      $y_min_p, $y_max_p, $y_intervals,
      $y1min_p, $y1max_p, $y1intervals
    ]
  );
  # print "in scale $y_min_p, $y_max_p, $y_intervals \n";
  # reset the zoom stack!
  $self -> {-zoomStack} = [];
  return (1);
}

sub plot
{
  # plot all the active data sets
  # 'always' (Default), 'never' or 'not_zoomed'
  my ($self, $rescale) = @_;
  $rescale = 'always' unless defined($rescale); # Default to Always

  if ($rescale eq 'always')   # Always Rescale
  {
    $self -> _rescale('all');
  }
  elsif ($rescale eq 'never') # Never Rescale
  {
    $self -> _rescale('not');
  }
  elsif ($rescale eq 'not_zoomed') # Only Rescale if not Zoomed in
  {
    if (@{$self -> {-zoomStack}} == 0)
    {
      $self -> _rescale('all');
    }
    else
    {
      $self -> _rescale('not');
    }
  }

  return (1);
}

sub _draw_axis
{
  # do both of the axis
  my ($self) = @_;
  my $s = $self -> cget(-scale);  # get the scale factors
  my ($nb, $eb, $sb, $wb) = @{$self -> cget(-border)};
  # for now, figure this will fit
  my $h = $self -> height;
  my $w = $self -> width;
  my $x_tick_label = $self -> cget('-xTickLabel');
  my $fonts = $self -> cget('-fonts');
  # print "_draw_axis: xTickLabel <$x_tick_label>\n";
  my $lab = [];
  if ($x_tick_label)
  {
    # print "draw axis: making tick labels\n";
    push (@{$lab}, 'black', $fonts -> [0]);
    foreach my $tl (@{$x_tick_label})
    {
      push @{$lab}, $tl;
      # print "_draw_axis: @{$lab} \n";
    }
  }
  else
  {
    $lab = undef;
  }

  # xAxis first
  # tick stuff
  my ($t_start, $t_stop, $interval) = ($s -> [0], $s -> [1], abs($s -> [2]));
  my $ticks = ($t_stop - $t_start) / $interval;
  my $a_length = $w - $wb - $eb;
  my $d = $a_length / $ticks;
  my ($x_start, $y_start, $x_end, $y_end) = ($wb, $h - $sb, $w - $eb, $h - $sb);
  my $result = $self -> _create_plot_axis
  (
    $x_start, $y_start, $x_end, $y_end,
    -fill => 'black',
    # $tcolor, $tfont,  $side, $start, $stop, $incr, $delta)
    # incr step size - used in lable in PIXELS, delta is the PIXELS  between ticks
    # have to start at the start of the "axis".  Not good!
    -tick => ['black', $fonts -> [0], 's', $t_start, $t_stop, $interval, $d],
    -tickFormat => $self -> cget('-xTickFormat'),
    -label => $lab,
  );

  # box x axis
  ($x_start, $y_start, $x_end, $y_end) = ($wb, $nb, $w - $eb, $nb);
  $result = $self -> _create_plot_axis
  (
    $x_start, $y_start, $x_end, $y_end,
    -fill => 'black'
  );

  # setup the tick labels if they have been set
  my $y_tick_label = $self -> cget('-yTickLabel');
  $lab = [];
  if ($y_tick_label)
  {
    # print "_draw_axis: making tick labels for y\n";
    push @{$lab}, 'black', $fonts -> [0] ;
    foreach my $tl (@{$y_tick_label})
    {
      push @{$lab}, $tl;
      # print "_draw_axis: @{$lab} \n";
    }
  }
  else
  {
    $lab = undef;
  }
  # print "y axis label <$lab> \n";
  #YAxis now
  ($x_start, $y_start, $x_end, $y_end) = ($wb, $nb, $wb, $h-$sb);
  ($t_start, $t_stop, $interval) = ($s -> [3], $s -> [4], abs($s -> [5]));
  $interval = 10 if ($interval <= 0);
  $ticks = ($t_stop - $t_start) / $interval;
  $a_length = $h - $nb - $sb;
  $d = $a_length / $ticks;
  $result = $self -> _create_plot_axis
  (
    $x_start, $y_start, $x_end, $y_end,
    -fill => 'black',
    # $tcolor, $tfont,  $side, $start, $stop, $incr, $delta)
    # incr step size - used in lable in PIXELS, delta is the PIXELS  between ticks
    # have to start at the start of the "axis".  Not good!
    -tickFormat => $self -> cget('-yTickFormat'),
    -tick => ['black', $fonts -> [0], 'w', $t_start, $t_stop, $interval, $d],
    -label => $lab,
  );

  #Y1Axis now if needed
  if ($self -> _count_y1)
  {
    # setup the tick labels if they have been set
    my $y1_tick_label  = $self -> cget('-y1TickLabel');
    $lab = [];
    if ($y1_tick_label)
    {
      # print "_draw_axis: making tick labels for y\n";
      push (@{$lab}, 'black', $fonts -> [0]);
      foreach my $tl (@{$y1_tick_label})
      {
        push (@{$lab}, $tl);
        # print "_draw_axis: @{$lab} \n";
      }
    }
    else
    {
      $lab = undef;
    }
    ($x_start, $y_start, $x_end, $y_end) = ($w-$eb, $nb, $w-$eb, $h-$sb);
    ($t_start, $t_stop, $interval) = ($s -> [6], $s -> [7], abs($s -> [8]));
    $interval = 10 if ($interval <= 0);
    $ticks = ($t_stop - $t_start) / $interval;
    $a_length = $h - $nb - $sb;
    $d = ($ticks != 0) ? $a_length / $ticks : 1;
    $result = $self -> _create_plot_axis
    (
      $x_start, $y_start, $x_end, $y_end,
      -fill => 'black',
      # $tcolor, $tfont,  $side, $start, $stop, $incr, $delta)
      # incr step size - used in lable in PIXELS, delta is the PIXELS  between ticks
      # have to start at the start of the "axis".  Not good!
      -tick => ['black', $fonts -> [0], 'e', $t_start, $t_stop, $interval, $d],
      -tickFormat => $self -> cget('-y1TickFormat'),
      -label => $lab,
    );
  }
  # box    y axis
  ($x_start, $y_start, $x_end, $y_end) = ($w-$eb, $nb, $w-$eb, $h-$sb);
  $result = $self -> _create_plot_axis
  (
    $x_start, $y_start, $x_end, $y_end,
    -fill => 'black',
  );
  $self -> _log_ticks;
  return (1);
}

sub _log_ticks
{
  # put the 2, 3, 4, ..., 9 ticks on a log axis
  my ($self) = @_;
  my $s = $self -> cget('-scale');
  my ($h, $w) = ($self -> height, $self -> width);
  my $borders = $self -> cget('-border');
  # do x axis
  if ($self -> cget('-xType') eq 'log')
  {
    my ($min_p, $max_p, $delta_p) = ($s -> [0], $s -> [1], $s -> [2]);
    my $dec = ($max_p - $min_p);
    unless ($dec > 5)  # only if there are less than four decades
    {
      my $axis_length = $w - $borders -> [1] - $borders -> [3];
      my $d_length = $axis_length / ($max_p - $min_p);
      my $delta;
      my $y = $h - $borders -> [2];
      foreach my $ii (1..$dec)
      {
        foreach my $i (2..9)
        {
          my $delta = (log10 $i) * $d_length;
          my $x = ($borders -> [3]) + $delta + $d_length * ($ii - 1);
          # print "_log_ticks: $ii $i delta $delta  y $y \n";
          $self -> createLine($x, $y, $x, $y + 6, -fill => 'black');
        }
      } # end each decade
    }
  }
  # do y axis
  if ($self -> cget('-yType') eq 'log')
  {
    my ($min_p, $max_p, $delta_p) = ($s -> [3], $s -> [4], $s -> [5]);
    my $dec = ($max_p - $min_p);
    unless ($dec > 5)  # only if there are less than four decades
    {
      my $axis_length = $h - $borders -> [0] - $borders -> [2];
      my $d_length = $axis_length / ($max_p - $min_p);
      my $delta;
      foreach my $ii (1..$dec)
      {
        foreach my $i (2..9)
        {
          my $delta = (log10 $i) * $d_length;
          my $y = $h - ($borders -> [2]) - $delta - $d_length * ($ii - 1);;
          # print "_log_ticks: $ii $i delta $delta  y $y \n";
          $self -> createLine($borders -> [3], $y, $borders -> [3] + 6, $y, -fill => 'black');
        }
      } # end each decade
    }
  }
  # do y1 axis
  if ($self -> cget('-y1Type') eq 'log')
  {
    my ($min_p, $max_p, $delta_p) = ($s -> [6], $s -> [7], $s -> [8]);
    my $dec = ($max_p - $min_p);
    unless ($dec > 5)  # only if there are less than four decades
    {
      my $axis_length = $h - $borders -> [0] - $borders -> [2];
      my $d_length = $axis_length / ($max_p - $min_p);
      my $delta;
      foreach my $ii (1..$dec)
      {
        foreach my $i (2..9)
        {
          my $delta = (log10 $i) * $d_length;
          my $x = $self -> width - $borders -> [1];
          my $y = $h - ($borders -> [2]) - $delta - $d_length * ($ii - 1);
          # print "_log_ticks: $ii $i delta $delta  y $y \n";
          $self -> createLine($x, $y, $x - 6, $y, -fill => 'black');
        }
      } # end each decade
    }
  }
  return (1);
}

sub _draw_datasets
{
  # draw the line(s) for all active datasets
  my ($self, @args) = @_;
  %{$self -> {BalloonPoints}} = (); # Clear the balloon help hash before drawing.
  foreach my $ds (@{$self -> {-datasets}})
  {
    if ($ds -> get('-active') == 1)
    {
      $self -> _draw_one_dataset($ds);
    }
  }
  return (1);
}

sub _draw_one_dataset  # index of the dataset to draw, widget args
{
  # draw even if not active ?
  my ($self, $ds, %args) = @_;
  # %args seems not to be used here.
  my ($nb, $eb, $sb, $wb) = @{$self -> cget(-border)};
  my $tag = $ds -> get('-name');
  my $fill;
  my $index  = $ds -> get('-index');
  if ($ds -> get('-color') eq 'none')
  {
    my $colors = $self -> cget(-colors);
    $fill = $self -> cget('-colors') -> [$index % @$colors];
    $ds -> set('-color' => $fill);
  }
  else
  {
    $fill = $ds -> get('-color');
  }

  my $line_style = $ds -> get('-lineStyle'); #SS - added option to set line style
  my $no_line = 0;
  my $dash = '';
  if ($line_style)
  {
    if ($line_style eq 'none')
    {
      $no_line = 1;
    }
    elsif ($line_style eq 'normal')
    {
      $dash = '';
    }
    elsif ($line_style eq 'dot')
    {
      $dash = '.';
    }
    elsif ($line_style eq 'dash')
    {
      $dash = '-';
    }
    elsif ($line_style eq 'dotdash')
    {
      $dash = '.-';
    }
    else
    {
      warn "Invalid -lineStyle setting ($line_style) on line $tag, defaulting to normal\n";
      $ds -> set('-lineStyle' => 'normal');
    }
    $ds -> set('-dash' => $dash);
  }
  else
  {
    $dash = '';
    $ds -> set('-dash' => $dash);
    $ds -> set('-lineStyle' => 'normal');
  }

  my $point_style; #SS - added option to set point style
  if (!$ds -> get('-pointStyle'))
  {
    my $point_styles = $self -> cget('-pointShapes');
    $point_style = $point_styles -> [$index % @$point_styles];
    $ds -> set('-pointStyle' => $point_style);
  }
  else
  {
    $point_style = $ds -> get('-pointStyle');
  }

  my $point_size = $ds -> get('-pointSize'); #SS - added option to set point style
  if (!$point_size)
  {
    $point_size = 3;
    $ds -> set('-pointSize' => $point_size);
  }

  my $fill_point = $ds -> get('-fillPoint'); #SS - added option to set whether point should be filled
  if (! defined $fill_point)
  {
    $fill_point = 1;
    $ds -> set('-fillPoint' => $fill_point);
  }

  my $yax  = $ds -> get('-yAxis');  # does this dataset use y or y1 axis
  # print "_draw_one_dataset: index <$index> color  <$fill> y axis <$yax>\n";
  my $y_data = $ds -> get('-yData');
  my $x_data = $ds -> get('-xData');
  $x_data = [0..(scalar(@$y_data)-1)]  unless (defined($x_data));
  my $y_error = $ds -> get('-yError');

  my $log_min = $self -> cget(-logMin);
  my $x = [];
  # if x-axis uses a log scale convert x data
  if ($self -> cget('-xType') eq 'log')
  {
    foreach my $e (@{$x_data})
    {
      $e = $log_min if ($e <= 0);
      push @{$x}, log10($e);
    } # end foreach
  }
  else  # not log at all
  {
    $x = $x_data;
  }
  my $y = [];
  # just maybe we have a log plot to do.  In that case must take the log of each point
  if
  (
    (($yax eq 'Y1') and ($self -> cget('-y1Type') eq 'log'))
    or (($yax eq 'Y') and ($self -> cget('-yType') eq 'log'))
  )
  {
    foreach my $e (@{$y_data})
    {
      $e = $log_min if ($e <= 0);
      push @{$y}, log10($e);
    } # end foreach
  }
  else  # not log at all
  {
    $y = $y_data;
  }

  my $dy = [];
  if ($y_error)
  {
    my $a = 0;

    # in case we have a log plot to do we have to log the errors as well
    if
    (
      (($yax eq 'Y1') and ($self -> cget('-y1Type') eq 'log'))
      or (($yax eq 'Y') and ($self -> cget('-yType') eq 'log'))
    )
    {
      foreach my $e (@{$y_error})
      {
        # error values on log scale are larger below the point than above, i.e. we implement the concept of
        # plus and minus error already here by building absolute values (y+dy; y-dy) and going on with them;
        # just use positive errors

        $dy -> [0] -> [$a] = log10($y_data -> [$a] + abs($e)); # pluserror

        # if minuserror is below 0 trim to log_min
        my $tmp;
        if ($y_data -> [$a] - abs($e) <= 0)
        {
          $tmp = $log_min;
        }
        else
        {
          $tmp = $y_data -> [$a] - abs($e);
        }

        $dy -> [1] -> [$a] = log10($tmp); # minuserror
        $a++;
      }
    }
    else  # not log at all
    {
      foreach my $e (@{$y_error})
      {
        $dy -> [0] -> [$a] = $y_data -> [$a] + abs($e);
        $dy -> [1] -> [$a] = $y_data -> [$a] - abs($e);
        $a++;
      }
    }
  }

  # need to make one array out of two
  my @xy_points;

  my @all_data;
  my $dyp = [];
  my $dym = [];

  # right here we need to go from data set coordinates to plot PIXEL coordinates
  my ($xReady, $yReady, $dyplusReady, $dyminusReady) = $self -> _ds_to_plot_pixels($x, $y, $dy, $yax);
  (@all_data) = $self -> _arrays_to_canvas_pixels('axis', $xReady, $yReady, $dyplusReady, $dyminusReady);

  # all data contains xy_points and plus and minus errors
  for (my $a = 0; $a < (@all_data/4); $a++)
  {
    $xy_points[$a * 2]     = $all_data[$a * 4];
    $xy_points[$a * 2 + 1] = $all_data[$a * 4 + 1];
    $dyp -> [$a]           = $all_data[$a * 4 + 2];
    $dym -> [$a]           = $all_data[$a * 4 + 3];
  }

  # got to take care of the case where the data set is empty or just one point.
  return if (@xy_points == 0);
  if (@xy_points == 2)
  {
    # print "one point, draw a dot!\n";
    my ($xa, $ya) = ($xy_points[0], $xy_points[1]);

    $self -> _draw_point
    (
      $xa, $ya, $dyp -> [0], $dym -> [0], -pointStyle => $point_style, -pointSize => $point_size,
      -fillPoint => $fill_point, -fill => $fill, -tags => [$tag, $tag . 'point']
    );
  }
  else
  {
    $self -> _draw_one_dataset_b
    (
      -data => \@xy_points,
      -fill => $fill,
      -dash => $dash,
      -tags => [$tag],
      -xData => $x_data,
      -yData => $y_data,
      -yError => [$dyp, $dym],
      -noLine => $no_line,
      -pointStyle => $point_style,
      -pointSize => $point_size,
      -fillPoint => $fill_point
    );
  }

  # If multiple curves, turn the plot name in the legend and the line red when we enter the line with the cursor
  if (scalar(@{$self -> {-datasets}}) > 1)
  {
    $self -> bind
    (
      $tag, '<Enter>' => sub
      {
        $self -> itemconfigure($tag, -fill => 'red');
        $self -> itemconfigure($tag . 'legend', -fill => 'red');
        $self -> itemconfigure($tag . 'point', -fill => 'red');
      }
    );
    $self -> bind
    (
      $tag, '<Leave>' => sub
      {
        $self -> itemconfigure($tag, -fill => $fill);
        $self -> itemconfigure($tag . 'legend', -fill => $fill);
        if ($fill_point)
        {
          $self -> itemconfigure($tag . 'point', -fill => $fill);
        }
        else
        {
          $self -> itemconfigure($tag . 'point', -fill => '');
        }
      }
    );
  }
  return (1);
}

sub _center_text_v  # given y1, y2, a font and a string
{
  # return a y value for the start of the text
  # The system is in canvas, that is 0, 0 is top right.
  # return -1 if the text will just not fit
  my ($self, $y1, $y2, $f, $s) = @_;
  return (-1) if ($y1 > $y2);
  my $g = 'gowawyVVV';
  $self -> _create_text_v
  (
    0, 10_000,  -text => $s, -anchor => 'sw',
    -font => $f, -tag => $g
  );
  my ($min_x, $min_y, $max_x, $max_y) = $self -> bbox($g);
  # print "_center_text_v: ($min_x, $min_y, $max_x, $max_y)\n";
  $self -> delete($g);
  my $space = $y2 - $y1;
  my $str_length = $max_y - $min_y;
  return (-1) if ($str_length > $space);
  # print "_center_text_v: $y1, $y2, space $space, strLen $str_length\n";
  return (($y1 + $y2 - $str_length) / 2);
}

sub _center_text  # x1, x2 a font and a string
{
  # return the x value fo where to start the text to center it
  # forget about leading and trailing blanks!!!!
  # Return -1 if the text will not fit
  my ($self, $x1, $x2, $f, $s) = @_;
  return (-1) if ($x1 > $x2);
  my $g = 'gowawy';
  $self -> createText
  (
    0, 10_000,  -text => $s, -anchor => 'sw',
    -font => $f, -tags => [$g]
  );
  my ($min_x, $min_y, $max_x, $max_y) = $self -> bbox($g);
  $self -> delete($g);
  my $space = $x2-$x1;
  my $str_length = $max_x - $min_x;
  return (-1) if ($str_length > $space);
  return (($x1 + $x2 - $str_length) / 2);
}

sub _draw_one_dataset_b  # takes same arguments as createLinePlot confused
{
  # do clipping if needed
  # do plot with dots if needed
  my ($self, %args) = @_;
  my $xy_points = delete($args{'-data'});
  my $x_data = delete($args{'-xData'});           # Take the original data for use
  my $y_data = delete($args{'-yData'});           # in the balloon popups
  my $y_error = delete($args{'-yError'});         # and y errors if given
  my $no_line = delete($args{'-noLine'});          # Add a switch to allow points-only plots
  my $point_style = delete($args{'-pointStyle'});  # Add a switch to set point style
  my $point_size = delete($args{'-pointSize'});    # Add a switch to set point size
  my $fill_point = delete($args{'-fillPoint'});    # Add a switch to specify points as not filled
  # $self -> createLinePlot(-data => $xy_points, %args);
  $self -> _clip_plot(-data => $xy_points, %args) unless $no_line;
  my $h = $self -> height;
  my $w = $self -> width;
  my $borders = $self -> cget(-border);
  # Data points are only shown if the dataset has no line or the number of
  # points on the plot is less then or equal to the -maxPoints option
  my $points = @{$xy_points} / 2;
  my $inPoints = $self -> _count_in_points($xy_points);
  if (($inPoints <= $self -> cget(-maxPoints)) or $no_line)
  {
    my $tags = $args{'-tags'};
    my $mainTag = $$tags[0];
    for (my $i = 0; $i < $points; $i++)
    {
      my $specificPointTag = $mainTag . "($i)";
      my $generalPointTag = $mainTag . 'point';
      my @pointTags = (@$tags, $specificPointTag, $generalPointTag);
      my ($x, $y, $dyp, $dym) = (0, 0, 0, 0);
      ($x, $y, $dyp, $dym) =
      (
        $xy_points -> [$i * 2], $xy_points -> [$i * 2 + 1],
        $y_error -> [0] -> [$i], $y_error -> [1] -> [$i]
      );

      if ($self -> cget('-balloons'))
      {
        $self -> {BalloonPoints} -> {$specificPointTag}
          = sprintf('%.3g, %.3g', $$x_data[$i], $$y_data[$i]);
      }
      if
      (
        ($x >= $borders -> [3])
        and ($x <= ($w - $borders -> [1]))
        and ($y >= $borders -> [0])
        and ($y <= ($h - $borders -> [2]))
      )
      {
        $self -> _draw_point
        (
          $x, $y, $dyp, $dym, %args, -pointStyle => $point_style, -pointSize => $point_size,
          -fillPoint => $fill_point, -tags => \@pointTags
        )
      }
    }
  }
  return (1);
}

sub _draw_point
{
  # Draws a point (includes drawing and clipping of error bars).
  my ($self, $x, $y, $dyp, $dym, %args) = @_;

  my $point_style = delete($args{-pointStyle});
  my $point_size = delete($args{-pointSize});
  my $fill_point = delete($args{-fillPoint});
  my $fill = $args{-fill};

  my $h = $self -> height;
  my $w = $self -> width;
  my $borders = $self -> cget(-border);
  my $pluserror = -1;
  my $minuserror = -1;
  if
  (
    ($x >= $borders -> [3])
    and ($x <= ($w - $borders -> [1]))
    and ($y >= $borders -> [0])
    and ($y <= ($h - $borders -> [2]))
  )
  {
    if (($dym) >=  ($h - $borders->[2]))
    {
      # The error bar exceeds the lower border -> trim it;
      $minuserror = ($h - $borders->[2]);
    }
    if (($dyp) <= $borders -> [0])
    {
      # The error bar exceeds the upper border -> trim it;
      $pluserror = $borders->[0];
    }
  }

  # widths of error bar ends (coupled to point size)
  my $pluswidth = 0;
  my $minuswidth = 0;

  my $default_width = 3 + $point_size - 1.5;
  my $default_thickness = (1 + $point_size - 1.5) * 0.5;

  if ($minuserror == -1)
  {
    $minuserror = $dym; # keep default error bar
    $minuswidth = $default_width unless ($dym == $y); # if error=0 de facto no error bar
  }

  if ($pluserror == -1)
  {
    $pluserror = $dyp;
    $pluswidth = $default_width unless ($dyp == $y);
  }

  # draw error bars if not globally switched off
  if (($self -> cget('-showError')) && ($dyp != 0) && ($dym != 0))
  {
    $self -> createLine
    (
      $x, $minuserror, $x, $pluserror, -width => $default_thickness, %args
    );
    $self -> createLine
    (
      $x-$pluswidth, $pluserror, $x+$pluswidth, $pluserror, -width => $default_thickness, %args
    );
    $self -> createLine
    (
      $x-$minuswidth, $minuserror, $x+$minuswidth, $minuserror, -width => $default_thickness, %args
    );
  }

  unless ($point_style)
  {
    $point_style = '';
  }

  unless ($point_size)
  {
    warn "_draw_point: No point size specified for $args{-tags} -> [0]\n";
    $point_size = 3;
  }

  $args{-outline} = $args{-fill};
  unless ($fill_point)
  {
    $args{-fill} = '';
  }

  if ($point_style eq 'none')
  {
  }
  elsif ($point_style eq 'circle' or $point_style eq '')
  {
    $self -> createOval
    (
      $x - $point_size, $y - $point_size,
      $x + $point_size, $y + $point_size, %args
    );
  }
  elsif ($point_style eq 'square')
  {
    $self -> createRectangle
    (
      $x - $point_size, $y - $point_size,
      $x + $point_size, $y + $point_size, %args
    );
  }
  elsif ($point_style eq 'triangle')
  {
    $self -> createPolygon
    (
      $x - $point_size, $y - $point_size,
      $x + $point_size, $y - $point_size,
      $x, $y + $point_size, %args
    );
  }
  elsif ($point_style eq 'diamond')
  {
    $self -> createPolygon
    (
      $x - $point_size, $y,
      $x, $y + $point_size,
      $x + $point_size, $y,
      $x, $y - $point_size, %args
    );
  }
  else
  {
    warn "_draw_point: Point style $point_style is invalid, line = $args{-tags} -> [0]\n";
    $self -> createOval
    (
      $x - $point_size, $y - $point_size,
      $x + $point_size, $y + $point_size, %args
    );
  }
  return (1);
}

sub _count_in_points  # array of x, y points
{
  # count the points inside the plot box.
  my ($self, $xy_points) = @_;
  my $points = @{$xy_points} / 2;
  my $count = 0;
  my $h = $self -> height;
  my $w = $self -> width;
  my $borders = $self -> cget(-border);

  for (my $i = 0; $i < $points; $i++)
  {
    my ($x, $y) = ($xy_points -> [$i * 2], $xy_points -> [$i * 2 + 1]);
    if
    (
      ($x >= $borders -> [3])
      and ($x <= ($w - $borders -> [1]))
      and ($y >= $borders -> [0])
      and ($y <= ($h - $borders -> [2]))
    )
    {
      $count++;
    }
  }
  return ($count);
}

sub _clip_plot  # -data => array ref which contains x, y points in Canvas pixels
{
  # draw a multi point line but cliped at the borders
  my ($self, %args) = @_;
  my $xy_points = delete($args{'-data'});
  my $point_count = (@{$xy_points})/2;
  my $h = $self -> height;
  my $w = $self -> width;
  my $last_point = 1; # last pointed plotted is flaged as being out of the plot box
  my $borders = $self -> cget(-border);
  my @p;  # a new array with points for line segment to be plotted
  my ($x, $y);
  my ($xp, $yp) = ($xy_points -> [0], $xy_points -> [1]); # get the first point
  if
  (
    ($xp >= $borders -> [3])
    and ($xp <= ($w - $borders -> [1]))
    and ($yp >= $borders -> [0])
    and ($yp <= ($h - $borders -> [2]))
  )
  {
    # first point is in, put points in the new array
    push @p, ($xp, $yp);  # push the x, y pair
    $last_point = 0; # flag the last point as in
  }
  for (my $i = 1; $i < $point_count; $i++)
  {
    ($x, $y) = ($xy_points -> [$i * 2], $xy_points -> [$i * 2 + 1]);
    # print "_clip_plot: $i ($x $borders -> [3]) and ($x $w $borders -> [1]) ($y $borders -> [0]) ($y ($h - $borders -> [2])) lastPoint  $last_point\n";
    if
    (
      ($x >= $borders -> [3])
      and ($x <= ($w - $borders -> [1]))
      and ($y >= $borders -> [0])
      and ($y <= ($h - $borders -> [2]))
    )
    {
      # OK, this point is in, if the last one was out then we have work to do
      if ($last_point == 1)  # out
      {
        $last_point = 0;   # in
        my ($xn, $yn) = $self -> _clip_line_in_out
        (
          $x, $y, $xp, $yp,
          $borders -> [3], $borders -> [0],
          $w - $borders -> [1], $h - $borders -> [2]
        );
        push (@p, ($xn, $yn));
        push (@p, ($x, $y));
        ($xp, $yp) = ($x, $y);
      }
      else  # last point was in, this  in  so we just add a point to the line and carry on
      {
        push (@p, ($x, $y));
        ($xp, $yp) =  ($x, $y);
      } # end else
    }
    else  # this point out
    {
      my @args = %args;
      if ($last_point == 0)  # in
      {
        # this point is out, last one was in, need to draw a line
        my ($x_edge, $y_edge) = $self -> _clip_line_in_out
        (
          $xp, $yp, $x, $y,
          $borders -> [3], $borders -> [0],
          $w - $borders -> [1], $h - $borders -> [2]
        );
        push @p, $x_edge, $y_edge;
        $self -> createLine(\@p, %args);
        splice(@p, 0);  # empty the array?
        $last_point = 1;   # out
        ($xp, $yp) =  ($x, $y );
      }
      else  # two points in a row out but maybe the lies goes thru the active area
      {
        # print "clip two points in a row out of box.\n";
        my $p = $self -> _clip_line_out_out
        (
          $xp, $yp, $x, $y,
          $borders -> [3], $borders -> [0],
          $w - $borders -> [1], $h - $borders -> [2]
        );
        $self -> createLine($p, %args)if (@$p >= 4);
        $last_point = 1; # out!
        ($xp, $yp) = ($x, $y );
      } # end else
    }
  } # end loop
  # now when we get out of the loop if there are any points in the @p array, make a line
  $self -> createLine(\@p, %args) if (@p >= 4);
  return (1);
}

sub _clip_line_out_out ## no critic (Subroutines::ProhibitManyArgs)
{ # x, y  ,  x, y  and x, y corners of the box

  # see if the line goes thru the box
  # If so, draw the line
  # else do nothing
  my ($self, $x1, $y1, $x2, $y2, $xb1, $yb1, $xb2, $yb2) = @_;
  my (@p, $x, $y);
  # print "_clip_line_out_out: ($x1, $y1) , ($x2, $y2), ($xb1, $yb1) , ($xb2, $yb2)\n";
  return (\@p) if (($x1 < $xb1) and ($x2 < $xb1));  # line not in the box
  return (\@p) if (($x1 > $xb2) and ($x2 > $xb2));
  return (\@p) if (($y1 > $yb2) and ($y2 > $yb2));
  return (\@p) if (($y1 < $yb1) and ($y2 < $yb1));
  # get here the line might pass thru the plot box
  # print "_clip_line_out_out: p1($x1, $y1), p2($x2, $y2), box1($xb1, $yb1), box2($xb2, $yb2)\n";
  if ($x1 != $x2)
  {
    my $m = ($y1 - $y2) / ($x1 - $x2);    # as in y = mx + c
    my $c = $y1 - $m * $x1;
    # print "_clip_line_out_out: line m $m c $c\n";
    $x = ($m != 0) ? ($yb1 - $c) / $m : $x1; #   print "$x $yb1\n";
    push @p, ($x, $yb1) if (($x >= $xb1) and ($x <= $xb2));
    $x = ($m != 0) ? ($yb2 - $c) / $m : $x1;
    push @p, ($x, $yb2) if (($x >= $xb1) and ($x <= $xb2));
    $y = $m * $xb1 + $c;
    push @p, ($xb1, $y) if (($y >= $yb1) and ($y <= $yb2));
    $y = $m * $xb2 + $c;
    push @p, ($xb2, $y) if (($y >= $yb1) and ($y <= $yb2));
  }
  else  # Handle vertical lines...
  {
    $x = $x1; # This is also $x2 of course!
    push @p, ($x, $yb1) if (($x >= $xb1) and ($x <= $xb2));
    $x = $x1;
    push @p, ($x, $yb2) if (($x >= $xb1) and ($x <= $xb2));
  }
  # print "_clip_line_out_out: @p", "\n";
  return (\@p)
}

sub _clip_line_in_out ## no critic (Subroutines::ProhibitManyArgs)
{ # x, y (1 in), x, y (2 out)   and x, y corners of the box

  # We have two points, one in the box, one outside of the box
  # Find where the line between the two points intersects the edges of the box
  # returns that point
  # Notebook page 106
  my ($self, $x1, $y1, $x2, $y2, $xb1, $yb1, $xb2, $yb2) = @_; ## no critic (Subroutines::ProhibitManyArgs)
  # print "_clip_line_in_out: ($x1, $y1) , ($x2, $y2), ($xb1, $yb1) , ($xb2, $yb2)\n";
  my ($xi, $yi);
  if ($x1 == $x2)  # line par to y axis
  {
    # print "_clip_line_in_out: Line parallel to y axis\n";
    $xi = $x1;
    $yi = ($y2 < $yb1) ? $yb1  : $yb2;
    return ($xi, $yi);
  }
  if ($y1 == $y2)  # line par to x axis
  {
    # print "_clip_line_in_out: Line parallel to y axis\n";
    $yi = $y1;
    $xi = ($x2 < $xb1) ? $xb1 : $xb2;
    return ($xi, $yi);
  }
  # y = mx + b; m = dy / dx   b = y1 - m * x1  x = (y - b) / m
  if (($x1 - $x2) != 0)
  {
    my $m = ($y1 - $y2) / ($x1 - $x2);
    my $c = $y1 - $m * $x1;
    if ($y2 <= $y1)  # north border
    {
      $xi = ($yb1 - $c) / $m;
      return ($xi, $yb1) if (($xi >= $xb1) and ($xi <= $xb2));
    }
    else  # south border
    {
      $xi = ($yb2-$c) / $m;
      return ($xi, $yb2) if (($xi >= $xb1) and ($xi <= $xb2));
    }
    if ($x2 <= $x1)  # west border
    {
      $yi = $m * $xb1 + $c;
      return ($xb1, $yi) if (($yi >= $yb1) and ($yi <= $yb2));
    }
    # only one remaining is east border
    $yi = $m * $xb2 + $c;
    return ($xb2, $yi) if (($yi >= $yb1) and ($yi <= $yb2));
  }
  else  # dx == 0, vertical line, north or south border
  {
    return ($x1, $yb1) if ($y2 <= $yb1);
    return ($x1, $yb2) if ($y2 >= $yb2);
  }
  warn '_clip_line_in_out() reach this point in the code';
  return (0, 0);
}

# There are three coordinate systems in use.
# 1. World  - Units are the physical system being plotted. Amps, DJ Average, dollars, etc
# 2. Plot   - Units are pixels. The (0, 0) point is the lower left corner of the canvas
# 3. Canvas - Units are pixels. The (0, 0) point is the upper left corner of the canvas.

sub _to_world_points  # x, y in the Canvas system
{
  # convert to World points
  # get points on canvas from system in pixels, need to change them into units in the plot
  my ($self, $xp, $yp)  = @_;
  my $borders = $self -> cget(-border);   # north, east, south, west
  my $s = $self -> cget(-scale);     # min X, max X, interval, min y, max y,
  my $h = $self -> height;
  my $w = $self -> width;
  my $x = ($xp - $borders -> [3]) * ($s -> [1] - $s -> [0])
    / ($w - $borders -> [1] - $borders -> [3]) + $s -> [0];
  my $y = (($h-$yp) - $borders -> [2]) * ($s -> [4] - $s -> [3])
    / ($h - $borders -> [0] - $borders -> [2]) + $s -> [3];
  # but if the axes are log some more work to do.
  my $y1 = (($h - $yp) - $borders -> [2]) * ($s -> [7] - $s -> [6])
    / ($h - $borders -> [0] - $borders -> [2]) + $s -> [6];
  $x = 10 ** $x   if ($self -> cget('-xType')  eq 'log');
  $y = 10 ** $y   if ($self -> cget('-yType')  eq 'log');
  $y1 = 10 ** $y1 if ($self -> cget('-y1Type') eq 'log');
  # print "_to_world_points: ($xp, $yp) to ($x, $y, $y1)\n";
  return ($x, $y, $y1);
}

sub _to_canvas_pixels  # which, x, y
{
  # given an x, y value in axis or canvas system return x, y in Canvas pixels.
  # axis => x, y are pixels relative to where the border is
  # canvas => x, y are pixels in the canvas system.
  # more to follow ?
  my ($self, $which, $x, $y) = @_;
  my ($x_out, $y_out);
  if ($which eq 'axis')
  {
    my $borders = $self -> cget(-border);
    return ($x + $borders -> [3], $self -> height - ($y + $borders -> [2]));
  }
  if ($which eq 'canvas')
  {
    return ($x, $self -> height - $y);
  }
} # end _to_canvas_pixels

sub _arrays_to_canvas_pixels  # which, x array ref, y array ref also errors
{
  # given x array ref and y aray ref generate the one array, xy in canvas pixels
  my ($self, $which, $xa, $ya, $dyap, $dyam) = @_;
  my (@xy_out, @dyp_out, @dym_out);
  my $h = $self -> height;
  my $borders = $self -> cget(-border);
  if ($which eq 'axis')
  {
    for (my $i = 0; $i < @$ya; $i++)
    {
      $xy_out[$i * 4]   = $xa -> [$i] + $borders -> [3];
      $xy_out[$i * 4 + 1] = $h - ($ya -> [$i] + $borders -> [2]);
      $xy_out[$i * 4 + 2] = $h - ($dyap -> [$i] + $borders -> [2]);
      $xy_out[$i * 4 + 3] = $h - ($dyam -> [$i] + $borders -> [2]);
    }
    return (@xy_out);
  }
}

sub _ds_to_plot_pixels  # ref to xArray and yArray with ds values, which y axis
{
  # ds is dataSet.  They are in world system
  # convert to Plot pixels, return ref to converted x array and y array
  # if y-errors are given, also convert these and return two more arrays
  # - ypluserror, yminuserror
  # if no y-errors are given, set them virtually to zero and return the arrays as well

  my ($self, $xa, $ya, $dya, $y_axis) = @_;
  my $s = $self -> cget(-scale);
  my ($x_min, $x_max, $y_min, $y_max);
  ($x_min, $x_max, $y_min, $y_max) = ($s -> [0], $s -> [1], $s -> [3], $s -> [4]);
  ($x_min, $x_max, $y_min, $y_max) = ($s -> [0], $s -> [1], $s -> [6], $s -> [7]) if ($y_axis eq 'Y1');
  # print "_ds_to_plot_pixels: X($x_min, $x_max), Y($y_min, $y_max)\n";
  my $borders = $self -> cget(-border);
  my ($nb, $eb, $sb, $wb) = ($borders -> [0], $borders -> [1], $borders -> [2], $borders -> [3]);
  my $h = $self -> height;
  my $w = $self -> width;
  my (@xR, @yR, @dypR, @dymR);  # converted values to be returned (including errors)
  my $sfX = ($w-$eb-$wb) / ($x_max - $x_min);
  my $sfY = ($h-$nb-$sb) / ($y_max - $y_min);
  my ($x, $y);
  for (my $i = 0; $i < @{$xa}; $i++)
  {
    push @xR, ($xa -> [$i] - $x_min) * $sfX if (defined($xa -> [$i]));
    push @yR, ($ya -> [$i] - $y_min) * $sfY if (defined($ya -> [$i]));

    # if y-Errors are given, also convert to pixels
    if ($dya -> [0])
    {
      push @dypR, ($dya -> [0] -> [$i] - $y_min) * $sfY;  # errors are absolute vals from here...
      push @dymR, ($dya -> [1] -> [$i] - $y_min) * $sfY;
    }
    else
    {
      push @dypR, ($ya -> [$i] - $y_min)  * $sfY;  # if no errors are given, set them to zero
      push @dymR, ($ya -> [$i] - $y_min)  * $sfY;
    }
  }
  return (\@xR, \@yR, \@dypR, \@dymR);
}

sub _nice_range # input is min, max,
{
  # return is a new min, max and an interval for the tick marks
  # interval is not the number of intervals but the size of the interval
  # find a good min, max and interval for the axis
  # if min > max return min 0, max 100, interval of 10.
  my ($min, $max) = @_;
  my $delta = $max - $min;
  return (0, 100, 10) if ($delta < 0);                                       # AC: Set standard scale for negative ranges
  return (int($min + 0.5) - 1, int($min + 0.5) + 1, 1) if ($delta <= 1e-15); # AC: Set special scale for zero, or v. small ranges (v. small is usually caused by rounding errors!)
  my $r = ($max != 0) ? $delta/$max : $delta;
  $r = -$delta / $min if ($max < 0);
  my $spaces = 10; # number
  # don't want a lot of ticks if the size of the space is very small compaired to values
  $spaces = 2 if ($r < 1e-2);

  while (1)  # do this until a return
  {
    # print "ratio <$r> \n";
    # $spaces = 2 if ($r < 1e-08);
    my $interval = $delta / $spaces;
    my $power = floor(log10($delta));
    # print "min, max $min, $max  delta $delta  power $power interval $interval $spaces\n";
    # find a good interval for the ticks
    $interval = $interval * (10 ** -$power) * 10;
    # print "min, max $min, $max  delta $delta  power $power interval $interval\n";
    # now round this up the next whole number but not 3 or 6, 7 or 9.
    # leaves 1, 2, 4, 5, 8
    $interval = ceil($interval);
    $interval = 8  if (($interval == 7) or ($interval == 6));
    $interval = 10 if ($interval == 9);
    $interval = 4  if ($interval == 3);
    #print "min, max $min, $max  delta $delta  power $power interval $interval\n";
    $interval = $interval * (10 ** (+$power - 1));
    #print "min, max $min, $max  delta $delta  power $power interval $interval\n";
    # find the new min
    my ($new_max, $new_min);
    my $new_delta = $interval * $spaces;
    if ($new_delta == $delta)
    {
      $new_max = $max;
      $new_min = $min;
    }
    else
    {
      my $n = $min / $interval;
      my $n_floor = floor($n);
      # print "n $n floor of n is $n_floor \n";
      $new_min = $n_floor * $interval;
      $new_max = $new_min + $new_delta;
      if ($new_max <= $max)
      {
        # Add an extra space to include data missed off by reducing the minimum value
        $new_delta += $interval;
        $spaces++;
        $new_max = $new_min + $new_delta;
      }
    }
    # print "_nice_range: min, max $min, $max  delta $delta  power $power interval $interval newMin $new_min newMax $new_max \n";

    # now see how much of the space has been used.  If there is a lot empty, increase the number of spaces (ticks)
    return ($new_min, $new_max, $interval) if ($spaces <= 3);
    return ($new_min, $new_max, $interval) if ((($new_delta / $delta) < 1.4) and ($new_max >= $max));
    $spaces++;
  }

  die '_nice_range() should not reach this point in the code';
}

sub _log_range  # min, max
{
  # for scaling a log axis
  #returns a max and min, intervals  and an array ref that contains labels for the ticks
  # Optional args  -tickFormat
  #   The sprintf format to use. If not specified, then '1e%3.2d' will be used
  #   for values less than zero and '1e+%2.2d' will be used for values of zero
  #   or more.
  my ($self, $min, $max, %args) = @_;
  my $tick_format = delete $args{-tickFormat};

  unless (defined($min) and defined($max))
  {
    $min = 0.1;
    $max = 1000;
  }

  if ($min <= 0)
  {
    my $t = $self -> cget(-logMin);
    # print "Can't log plot data that contains numbers less than or equal to zero.\n";
    # print "Data min is: <$min>.  Changed to $t\n";
    $min = $self -> cget(-logMin);
    # set a flag to indicate the log data must be checked for min!
    $self -> {-logCheck} = 1; # true
  }
  my $delta = $max - $min;
  my $first;
  my @t_label;

  my $max_p = ceil(log10($max));
  $max_p = $max_p + 1 if ($max_p < 0);
  my $min_p = floor(log10($min));
  my $f;
  # print "_log_range: max $max, min $min,  $max_p, $min_p)\n";
  foreach my $t ($min_p..$max_p)
  {
    my $n = 10.0 ** $t;
    # print "_log_range: <$n> <$t>\n";
    if ($tick_format)
    {
      $f = sprintf($tick_format, $t);
    }
    elsif ($t < 0)
    {
      $f = sprintf('1e%3.2d', $t);
    }
    else
    {
      $f = sprintf('1e+%2.2d', $t);
    }
    # print "_log_range: $f \n";
    push @t_label, $f;
  }
  return ($min_p, $max_p, 1, \@t_label);
  # look returning min Power and the max Power.  Note the power step is always 1 this might not be good
  # used  1e-10, 1e-11 and so on.  Looks good to me!
}

1;

