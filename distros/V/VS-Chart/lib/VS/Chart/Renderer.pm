package VS::Chart::Renderer;

use strict;
use warnings;

use Scalar::Util qw(blessed);

my %Defaults = (
    background  => 1,
);

sub set_defaults {
    my ($self, $chart) = @_;

    my @keys;
    while (my ($key, $value) = each %Defaults) {
       unless ($chart->has($key)) {
           $chart->set($key => $value);
           push @keys, $key;
       }
    }
    
    return @keys;
}

sub new {
    my ($pkg) = @_;
    my $self = bless \do { my $v; }, $pkg;
    return $self;
}

sub render {
    my ($self, $chart, $surface) = @_;
    $self->render_background($chart, $surface);
}

sub render_background {
    my ($self, $chart, $surface) = @_;
    return unless $chart->get("background");
    my $cx = Cairo::Context->create($surface);
    my $color = VS::Chart::Color->get($chart->get("background"), "white");
    $color->set($cx, $surface, $chart->get("width"), $chart->get("height"));
    $cx->paint;
}

sub set_font {
    my ($self, $cx, $chart, $section) = @_;
    
    my $face = $chart->get("${section}_font_face");
    if ($face) {
        my $slant = $chart->get("${section}_font_slant") || "normal";
        my $weight = $chart->get("${section}_font_weight") || "normal";
        $cx->select_font_face($face, $slant, $weight);
    }
    
    my $size = $chart->get("${section}_font_size");
    if ($size) {
        $cx->set_font_size($size);
    }
}

1;
__END__

=head1 NAME

VS::Chart::Renderer - Base class for renderers

=head1 ATTRIBUTES

=head2 BACKGROUND

=over 4

=item background = ( 0 | 1 | COLOR )

Controls whether a background should be drawn for all of the resulting picture. Defaults to 1. Standard color is B<white>.

=back

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new 

Creates a new renderer instance.

=item set_defaults ( CHART )

Sets defaults attribute for the chart and returns a list of keys it's added. If an attribute already exists it's 
unaffected.

=item render ( CHART, SURFACE )

Renders the chart to the Cairo surface.

=item render_background ( CHART, SURFACE )

Renders the chart background if one is declared.

=item set_font ( CHART, SURFACE, SECTION)

Sets the current font face and size to what is defined by the settings for I<SECTION>. For example, B<labels_font_face>, 
B<labels_font_size>, B<labels_font_slant> and B<labels_font_weight>.

=back

=cut
