package VS::Chart::Renderer::Line;

use strict;
use warnings;

use base qw(VS::Chart::Renderer::XY);

# Name that this renderer registers as
sub type { "line"; }

sub render {
    my ($self, $chart, $surface) = @_;
    $self->SUPER::render($chart, $surface);
    $self->render_datasets($chart, $surface);
}

sub render_datasets {
    my ($self, $chart, $surface) = @_;
    
    my $rows = $chart->rows - 1;
    return if $rows < 1;
    
    my ($xl, $xr) = $self->x_offsets($chart, $surface);
    my ($yt, $yb) = $self->y_offsets($chart, $surface);

    my $width = $chart->get("width") - ($xr + $xl);
    my $height = $chart->get("height") - ($yt + $yb);
    
    my $cx = Cairo::Context->create($surface);

    $cx->translate($xl, $yt);

    $cx->rectangle(1, 1, $width - 1.5, $height - 1.5);
    $cx->clip();
    
    $cx->set_line_width(abs($chart->get("line_width") || 4));

    my $g_line_dash = $chart->get("line_dash") || 0;
    
    my $ds = 0;

    my $iter = $chart->_row_iterator();
    my $pv;

    my $i = 0;
    for my $dataset (@{$chart->_datasets}) {
        my $line_dash = $dataset->get("line_dash");
        if ($line_dash) {
            $cx->set_dash(0, $line_dash);
        }
        else {
            if ($g_line_dash) {
                $cx->set_dash(0, $g_line_dash);
            }
            else {
                $cx->set_dash(0);
            }
        }
        
        $ds++;
        next if $chart->get("x_column") && $chart->get("x_column") == $ds;
        my $color = $dataset->get("color");
        VS::Chart::Color->get($color, "dataset_" . ($i % 16))->set($cx, $surface, $width, $height);
        
        $iter->reset;
        while (defined(my $idx = $iter->next)) {
            my $v = $dataset->value($idx);
            if (!defined $pv && defined $v) {
                $cx->move_to($width * $iter->relative, $height * (1 - $chart->_offset($v)));                
                $pv = $v;
            }
            if (defined $v) {
                $cx->line_to($width * $iter->relative, $height * (1 - $chart->_offset($v)));
                $pv = $v;
            }
        }
        $cx->stroke();
        $i++;
    }
}

1;
__END__

=head1 NAME

VS::Chart::Renderer::Line - Renders a line chart

=head1 DESCRIPTION

This class implements a standard line chart.

=head1 ATTRIBUTES

=head2 LINES

=over 4

=item line_width

The width of the line to draw. Defaults to 4 points.

=item line_dash

Sets the dash length for the line. Defaults to 0 (no dash). Can also be set on a specific dataset.

=back

=head2 COLORS

The color a dataset is drawn with it taken from the datasets attribute B<color> if such is defined. Otherwise the color 
which is used is selected from the I<dataset_>-series in VS::Chart::Color where the index is the dataset number 
modulus 16.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item type

Returns the type of chart we render, in this case B<line>.

=item render ( CHART, SURFACE )

Render I<CHART> to I<SURFACE>. Calls render in C<VS::Chart::Renderer::XY> first.

=item render_datasets ( CHART, SURFACE, LEFT, TOP, WIDTH, HEIGHT )

Renders the charts background. This is the area on which the actually data will be drawn, and not 
the axes, labels or ticks. The I<WIDTH> and I<HEIGHT> are calculated by taking their respetive values 
minus any offsets.

=back

=cut
