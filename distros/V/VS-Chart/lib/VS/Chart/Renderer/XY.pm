package VS::Chart::Renderer::XY;

use strict;
use warnings;

use Scalar::Util qw(blessed);
use POSIX qw(ceil);

use VS::Chart::Color;

use base qw(VS::Chart::Renderer);

my %Defaults = (
    chart_background => 1,
    x_axis           => 1,
    y_axis           => 1,
    x_labels         => 1,
    y_labels         => 1,
    show_y_min       => 1,
    y_grid           => 1,
    x_grid           => 0,
    y_steps          => 4,
    y_label_decimals => 1,
    x_label_decimals => 0,
);

sub type { "xy"; }

sub set_defaults {
    my ($self, $chart) = @_;
    my @keys = $self->SUPER::set_defaults($chart);

    while (my ($key, $value) = each %Defaults) {
       unless ($chart->has($key)) {
           $chart->set($key => $value);
           push @keys, $key;
       }
    }
    
    return @keys;
}

sub render {
    my ($self, $chart, $surface) = @_;
    
    $self->SUPER::render($chart, $surface);
     
    my ($xl, $xr) = $self->x_offsets($chart, $surface);
    my ($yt, $yb) = $self->y_offsets($chart, $surface);

    my $width = $chart->get("width") - ($xl + $xr);
    my $height = $chart->get("height") - ($yt + $yb);

    $self->render_chart_background($chart, $surface, $xl, $yt, $width, $height);
    $self->render_axes($chart, $surface, $xl, $yt, $width, $height);    
    $self->render_baseline($chart, $surface, $xl, $yt, $width, $height);    
    $self->render_title($chart, $surface, $xl, $yt, $chart->get("width"), $chart->get("height"));    
}

# Calculate this by checking if show labels for y axis
sub x_offsets {
    my ($self, $chart, $surface) = @_;

    my $xl = 0;
    my $xr = 0;
    my $padding = $chart->get("padding") || 0;
    
    my $cx = Cairo::Context->create($surface);
    $self->set_font($cx, $chart, "labels");
    
    $xl += 10 if $chart->get("y_ticks") && $chart->rows;
    $xl += 5 if !$xl && $chart->get("y_minor_ticks") && $chart->rows;
    
    if ($chart->get("y_labels") && $chart->rows) {
        # Get max value        
        my $max = $chart->_max;    
        my $min = $chart->_min;
        
        my $decimals = abs($chart->get("y_label_decimals") || 0);
        my $label_fmt = $chart->get("y_label_fmt") ? $chart->get("y_label_fmt") : $decimals ? "%.${decimals}f" : "%.0f";

        my $extents = $cx->text_extents(sprintf($label_fmt, $max));
        my $pre_xl = $xl;
        $xl += $extents->{width} + 10;
        $extents = $cx->text_extents(sprintf($label_fmt, $min));
        if ($extents->{width} + 10 > $xl) {
            $xl = $pre_xl;
            $xl += $extents->{width} + 10;
        }
    }

    if ($chart->get("x_labels") && $chart->rows) {
        # X labels
        my $iter = $chart->_row_iterator;
        my $max = $iter->max;
        my $min = $iter->min;
        
        my $extents = $cx->text_extents("${min}");
        $xl = ceil($extents->{width} / 2) if $extents->{width} / 2 > $xl;
        
        $extents = $cx->text_extents("${max}");
        $xr = ceil($extents->{width} / 2);
    }
        
    return ($xl - 1 + $padding, $xr + 0.5 + $padding);
}

# Calculate this by checking if show labels for y axis
sub y_offsets {
    my ($self, $chart, $surface) = @_;
    
    my $yt = 0;
    my $yb = 0;
    my $padding = $chart->get("padding") || 0;

    $yb += 10 if $chart->get("x_ticks") && $chart->rows;
    $yb += 5 if !$yb && $chart->get("x_minor_ticks") && $chart->rows;

    my $cx = Cairo::Context->create($surface);
    $self->set_font($cx, $chart, "labels");

    if ($chart->has("title")) {
        $self->set_font($cx, $chart, "title");
        my $extents = $cx->text_extents($chart->get("title"));
        $yt += ceil(sprintf("%.0f", $extents->{height})) + 10;
    }

    if ($chart->get("y_labels")) {
        # Get max value        
        my $max = $chart->_max;    
        my $min = $chart->_min;
        
        my $decimals = abs($chart->get("y_label_decimals") || 0);
        my $label_fmt = $chart->get("y_label_fmt") ? $chart->get("y_label_fmt") : $decimals ? "%.${decimals}f" : "%.0f";

        my $extents = $cx->text_extents(sprintf($label_fmt, $max));
        $yt = ceil($extents->{height} / 2) if $extents->{height} / 2 > $yt;
        
        $extents = $cx->text_extents(sprintf($label_fmt, $min));
        $yb = ceil($extents->{height} / 2) if $yb == 0;
    }
    
    if ($chart->get("x_labels") && $chart->rows) {
        my $extents = $cx->text_extents("0123456789.-");
        $yb += ceil(sprintf("%.0f", $extents->{height}) + 10);
    }
        
    return ($yt - 1 + $padding, $yb + 0.5 + $padding);
}

sub render_chart_background {
    my ($self, $chart, $surface, $offset_x, $offset_y, $width, $height) = @_;
    return unless $chart->get("chart_background");
    my $cx = Cairo::Context->create($surface);
    $cx->translate($offset_x, $offset_y);
    my $color = VS::Chart::Color->get($chart->get("chart_background"), "white");
    $cx->rectangle(0, 0, $width, $height);
    $color->set($cx, $surface, $width, $height);
    $cx->fill;
}

sub render_title {
    my ($self, $chart, $surface, $offset_x, $offset_y, $width, $height) = @_;
    return unless $chart->has("title");
    my $cx = Cairo::Context->create($surface);
    $self->set_font($cx, $chart, "title");
    
    my $color = VS::Chart::Color->get($chart->get("title_color"), "black");
    
    my $e = $cx->text_extents($chart->get("title"));
    $cx->move_to(int(($width / 2) - ($e->{width} / 2)) + 0.5, 10 + $e->{height} + 0.5);
    $cx->show_text($chart->get("title"));
    $cx->stroke;
    
}

sub render_baseline {
    my ($self, $chart, $surface, $offset_x, $offset_y, $width, $height) = @_;
    
    return unless $chart->has("baseline");
        
    my $baseline_value = $chart->get("baseline") || 0;
    return if $baseline_value < $chart->_min || $baseline_value > $chart->_max;

    my $cx = Cairo::Context->create($surface);
    $cx->translate($offset_x, $offset_y);

    $cx->rectangle(1, 1, $width - 1.5, $height - 1.5);
    $cx->clip();

    $cx->set_line_width($chart->get("baseline_width") || 1);
    
    if ($chart->get("baseline_dash")) {
        $cx->set_dash(0, $chart->get("baseline_dash"));
    }
    
    VS::Chart::Color->get($chart->get("baseline_color"), "black")->set($cx, $surface, $width, $height);
    
    my $y_pos = int($height * (1 - $chart->_offset($baseline_value))) + 0.5;
    $cx->move_to(0.5, $y_pos);
    $cx->line_to(int($width) + 0.5, $y_pos);
    $cx->stroke;
}

sub render_axes {
    my ($self, $chart, $surface, $offset_x, $offset_y, $width, $height) = @_;
    
    my $cx = Cairo::Context->create($surface);
    $self->set_font($cx, $chart, "labels");

    $cx->translate($offset_x, $offset_y);
    
    $cx->set_line_width(1);
    
    # Render y labels, y ticks, grid
    if ($chart->rows) {
        my $y_span = $chart->_span;
        my $y_steps = abs($chart->get("y_steps") || 1);
        my $y_step_offset = $y_span / $y_steps;
        my $v = $chart->_max;
        my $y_decimals = abs($chart->get("y_label_decimals") || 0);
        my $y_label_fmt = $chart->get("y_label_fmt") ? $chart->get("y_label_fmt") : $y_decimals ? "%.${y_decimals}f" : "%.0f";

        my $pre_y_pos;
        for (0..$y_steps) {
            $v = $chart->_min if $_ == $y_steps;

            my $y_pos = (1 - $chart->_offset($v)) * $height;

            # Major ticks
            my $label_offset = 10;

            if (($chart->get("y_minor_ticks") || $chart->get("y_minor_grid")) && defined $pre_y_pos) {
                my $y_minor_ticks_count = abs($chart->get("y_minor_ticks_count") || 1);
                my $yto = ($y_pos - $pre_y_pos)  / ($y_minor_ticks_count + 1);
                if ($chart->get("y_minor_ticks")) {
                    VS::Chart::Color->get($chart->get("y_minor_ticks"), "minor_tick")->set($cx, $surface, $width, $height);
                    for (1..$y_minor_ticks_count) {
                        my $y_minor_pos = int($y_pos - ($yto * $_)) + 0.5;
                        $cx->move_to(0.5, $y_minor_pos);
                        $cx->line_to(-4.5, $y_minor_pos);
                    }
                    $cx->stroke;
                }

                if ($chart->get("y_minor_grid")) {
                    my $color = VS::Chart::Color->get($chart->get("y_minor_grid"), "minor_tick");
                    $color->set($cx, $surface, $width, $height);
                    for (1..$y_minor_ticks_count) {
                        my $y_minor_pos = int($y_pos - ($yto * $_)) + 0.5;
                        $cx->move_to(0.5, $y_minor_pos);
                        $cx->line_to(int($width) + 0.5, $y_minor_pos);
                    }
                    $cx->stroke;
                }
            }

            if ($chart->get("y_ticks")) {
                VS::Chart::Color->get($chart->get("y_ticks"), "major_tick")->set($cx, $surface, $width, $height);
                $cx->move_to(0.5, int($y_pos) + 0.5);
                $cx->line_to(-9.5, int($y_pos) + 0.5);
                $label_offset += 10;
                $cx->stroke;
            }

            # Labels
            if ($chart->get("y_labels") && ($chart->get("show_y_min") || $_ < $y_steps)) {
                VS::Chart::Color->get($chart->get("y_labels"), "text")->set($cx, $surface, $width, $height);
                my $t = sprintf($y_label_fmt, $v);
                my $e = $cx->text_extents("${t}");
                # Render Y Labels never outside graph
                $cx->move_to(int(-($label_offset + $e->{width})) + 0.5, int($y_pos + $e->{height} / 2) + 0.5);
                $cx->show_text("${t}");
                $cx->stroke;
            }

            $v -= $y_step_offset;
            $pre_y_pos = $y_pos;
        }

        my $x_decimals = $chart->get("x_label_decimals") || 0;
        my $x_label_fmt = $chart->get("x_label_fmt") ? $chart->get("x_label_fmt") : $x_decimals ? "%.${x_decimals}f" : "%.0f";
    
        my $x_iter = $chart->_row_iterator;
        my $x_min = $x_iter->min;
        my $x_max = $x_iter->max;
        my $x_span = $x_max - $x_min;

        $x_max = sprintf($x_label_fmt, $x_max) unless blessed $x_max;
        $x_min = sprintf($x_label_fmt, $x_min) unless blessed $x_min;
        
        my $x_label_width = $cx->text_extents("${x_min}")->{width};
        my $x_label_extents = $cx->text_extents("${x_max}");
        $x_label_width = $x_label_extents->{width} if $x_label_extents->{width} > $x_label_width;
        $x_label_width *= 2;
    
        my $x_steps = sprintf("%.0f", $width / $x_label_width);

        my $pre_x_pos;
        for (0..$x_steps) {
            my $x_pos = int($width * ($_ / $x_steps)) + 0.5;

            if (($chart->get("x_minor_ticks") || $chart->get("x_minor_grid")) && defined $pre_x_pos) {
                my $x_minor_ticks_count = abs($chart->get("x_minor_ticks_count") || 1);
                my $xto = ($x_pos - $pre_x_pos)  / ($x_minor_ticks_count + 1);
                
                if ($chart->get("x_minor_ticks")) {
                    VS::Chart::Color->get($chart->get("x_minor_ticks"), "minor_tick")->set($cx, $surface, $width, $height);
                    for (1..$x_minor_ticks_count) {
                        $cx->move_to(int($x_pos - ($xto * $_)) + 0.5, $height + 0.5);
                        $cx->line_to(int($x_pos - ($xto * $_)) + 0.5, $height + 5.5);
                    }
                    $cx->stroke;
                }
                
                if ($chart->get("x_minor_grid")) {
                    my $color = VS::Chart::Color->get($chart->get("x_minor_grid"), "minor_tick");
                    $color->set($cx, $surface, $width, $height);
                    for (1..$x_minor_ticks_count) {
                        $cx->move_to(int($x_pos - ($xto * $_)) + 0.5, 0.5);
                        $cx->line_to(int($x_pos - ($xto * $_)) + 0.5, $height + 0.5);
                    }
                    $cx->stroke;
                }
            }

            if ($chart->get("x_ticks")) {
                VS::Chart::Color->get($chart->get("x_ticks"), "major_tick")->set($cx, $surface, $width, $height);
                $cx->move_to($x_pos, int($height) + 0.5);
                $cx->line_to($x_pos, int($height + 10) + 0.5);
                $cx->stroke;
            }

            if ($chart->get("x_grid")) {
                VS::Chart::Color->get($chart->get("x_grid"), "grid")->set($cx, $surface, $width, $height);
                $cx->move_to($x_pos, 0.5);
                $cx->line_to($x_pos, int($height) + 0.5);
                $cx->stroke;
            }
            
            if ($chart->get("x_labels")) {
                VS::Chart::Color->get($chart->get("x_labels"), "text")->set($cx, $surface, $width, $height);
                my $v_offset = $x_span * ($_ / $x_steps);
                $v_offset = int($v_offset) if blessed $x_min;
                my $value = $x_min  + $v_offset;
                $value = sprintf($x_label_fmt, $value) unless blessed $value;
                my $extents = $cx->text_extents("${value}");
                $cx->move_to($x_pos - int($extents->{width} / 2), int($height + 20 + $extents->{height}) + 0.5);
                $cx->show_text("${value}");
                $cx->stroke();
            }
            
            $pre_x_pos = $x_pos;
        }    
    
        if ($chart->get("y_grid")) {
            VS::Chart::Color->get($chart->get("y_grid"), "grid")->set($cx, $surface, $width, $height);
            my $v = $chart->_max;
            for (0..$y_steps) {
                $v = $chart->_min if $_ == $y_steps;        
                my $y_pos = (1 - $chart->_offset($v)) * $height;    
                $cx->move_to(0.5, int($y_pos) + 0.5);
                $cx->line_to(int($width) + 0.5, int($y_pos) + 0.5);
                $v -= $y_step_offset;
            }
            $cx->stroke;
        }
    }
    
    if ($chart->get("borders")) {
        VS::Chart::Color->get($chart->get("borders"), "borders")->set($cx, $surface, $width, $height);
        $cx->rectangle(0, 0, $width, $height);
        $cx->stroke;
    }
    else {
        if ($chart->get("y_axis")) {
            VS::Chart::Color->get($chart->get("y_axis"), "axis")->set($cx, $surface, $width, $height);
            $cx->move_to(0.5, 0.5);
            $cx->line_to(0.5, int($height) + 0.5);
            $cx->stroke;
        }
        if ($chart->get("x_axis")) {
            VS::Chart::Color->get($chart->get("x_axis"), "axis")->set($cx, $surface, $width, $height);
            $cx->move_to(0.5, int($height) + 0.5);
            $cx->line_to(int($width) + 0.5, int($height) + 0.5);
            $cx->stroke;
        }
    }
}

1;
__END__

=head1 NAME

VS::Chart::Renderer::XY - Base class for grafs that uses a XY planar coordinate system

=head1 DESCRIPTION

This class performs common rendering of stuff like chart background, grids and labels for XY planar 
coordinate charts.

=head1 ATTRIBUTES 

=head2 BACKGROUND

=over 4

=item chart_background ( 0 | 1 | COLOR )

Controls if a chart_background should be drawn or not. Defaults to 1. Standard color is B<white>.

=back

=head2 BASELINE

A baseline is a line rendered at a specific value from left to right in the chart to 
indicate a comparision value, for example 100%.

=over 4

=item baseline ( VALUE )

The value at where to draw the baseline. Baseline will only be drawn if this option is set.

=item baseline_color (COLOR)

Controls the color that the baseline should be drawn with. Standard color is B<black>.

=item baseline_dash ( DASH )

Controls if the baseline should be dashed. Standard is a solid line.

=back

=head2 BORDERS & PADDING

=over 4

=item borders ( 0 | 1 | COLOR )

Controls if a 1 point border around the chart should be drawn or not. Defaults to 0. Standard color is B<black>.

=item padding ( SIZE )

Controls if there should be a padding around what's rendered. Defaults to 0

=back

=head2 COMMON ATTRIBUTES FOR BOTH AXES

=over 4

=item labels_font_face 

Sets the font-face for the labels. Values understood are normally B<serif>, B<sans-serif> and B<monospace> but others might work.

=item labels_font_size

The size of the text to render in points.

=item labels_font_slant

If the font is in italics or not. Valid values are B<normal>, B<italic>, B<oblique>. Defaults to B<normal> which means no italic.

=item labels_font_weight

If the font is in bold or not. Valid values are B<normal>, B<bold>. Defaults to B<normal> which means not bold.

=back

=head2 X AXIS

=over 4

=item x_axis ( 0 | 1 | COLOR )

Controls if the X axis should be drawn. Defaults to 1. Standard color is B<axis>.

=item x_grid ( 0 | 1 | COLOR ). 

Controls if a vertical grid should be drawn. Defaults to 1. Standard color is B<grid>.

=item x_label_fmt ( FORMAT )

Controls how X axis labels will be formated using printf syntax. Default is C<%.${x_label_decimals}f> for 
numeric values and ISO 8601 for dates.

=item x_label_decimals ( NUM )

Controls how many decimals should be shown for X labels. Defaults to 0. If the labels isn't 
numeric this has no effect.

=item x_labels ( 0 | 1 | COLOR )

Controls if labels on the X axis should be drawn. Defaults to 1. Standard color is B<text>.

=item x_minor_grid ( 0 | 1 | COLOR )

Controls if minor vertical grid should be drawn. Defaults to 0. Standard color is B<minor_tick>.

=item x_minor_ticks (0 | 1 | COLOR )

Controls if minor ticks (between lables / major ticks ) should be drawn. Defaults to 0. 
Standard color is B<minor_tick>.

=item x_minor_ticks_count ( NUM )

Controls the number of minor ticks (and minor grid lines) to show between major ticks.

=item x_ticks ( 0 | 1 | COLOR )

Controls if major ticks (at labels) should be drawn. Defaults to 0. Standard color is B<major_tick>.

=back

=head2 Y AXIS

=over 4

=item show_y_min ( 0 | 1)

Controls if the minimum value for Y should be shown or not.

=item y_grid ( 0 | 1 | COLOR )

Controls if a horizontal grid should be drawn. Defaults to 1. Standard color is B<grid>.

=item y_minor_grid ( 0 | 1 | COLOR )

Controls if a horizontal minor grid should be drawn. Defaults to 0. Standard color is B<minor_tick>.

=item y_steps ( NUM )

Controls how many steps on the Y axis should be shown.

=item y_axis ( 0 | 1 | COLOR )
    
Controls if the Y axis should be drawn. Defaults to 1. Standard color is B<axis>.

=item y_labels ( 0 | 1 | COLOR )

Controls if labels on the X axis should be drawn. Defaults to 1. Standard color is B<text>.

=item y_label_fmt ( FORMAT )

Controls how Y axis labels will be formated using printf syntax. Default is C<%.${y_label_decimals}f> for 
numeric values.

=item y_label_decimals ( NUM )

Controls how many decimals should be shown for Y labels. Defaults to 1.

=item y_major_ticks ( 0 | 1 | COLOR )

Controls if major ticks (at labels) should be drawn. Defaults to 0. Standard color is B<major_tick>.

=item y_minor_ticks (0 | 1 | COLOR )

Controls if minor ticks (between lables / major ticks ) should be drawn. Defaults to 0. Standard color is B<minor_tick>.

=item y_minor_ticks_count ( NUM )

Controls the number of minor ticks to show between major ticks/grid lines. 

=back

=head2 TITLE

=over 4

=item title

Sets the title that will be displayed centered above the chart.

=item title_font_face 

Sets the font-face for the title. Values understood are normally B<serif>, B<sans-serif> and B<monospace> but others might work.

=item title_font_size

The size of the text to render in points.

=item title_font_slant

If the font is in italics or not. Valid values are B<normal>, B<italic>, B<oblique>. Defaults to B<normal> which means no italic.

=item title_font_weight

If the font is in bold or not. Valid values are B<normal>, B<bold>. Defaults to B<normal> which means not bold.

=back

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item set_defaults ( CHART )

Sets defaults attribute for the chart and returns a list of keys it's added. If an attribute already exists it's 
unaffected.
 
=item render ( CHART, SURFACE )

Render I<CHART> to I<SURFACE>

=item render_chart_background ( CHART, SURFACE, LEFT, TOP, WIDTH, HEIGHT )

Renders the charts background. This is the area on which the actually data will be drawn, and not 
the axes, labels or ticks. The I<WIDTH> and I<HEIGHT> are calculated by taking their respetive values 
minus any offsets.

=item render_axes ( CHART, SURFACE, LEFT, TOP, WIDTH, HEIGHT )

Renders the axes, labels and ticks.

=item render_baseline ( CHART, SURFACE, LEFT, TOP, WIDTH, HEIGHT )

Renders the baseline.

=item render_title ( CHART, SURFACE, LEFT, TOP, WIDTH, HEIGHT )

Renders the title.

=item x_offsets ( CHART, SURFACE )

Returns left and right offsets for the chart.

=item y_offsets ( CHART, SURFACE )

Returns the top and bottom offsets for the chart.

=item type

Returns the type of chart that will be used by C<VS::Chart/render> to determine what renderer to use,

=back

=head1 SEE MORE

L<VS::Chart::Color>.

=cut