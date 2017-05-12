use 5.008001;
use strict;
use warnings;

package Text::BoxPlot;
# ABSTRACT: Render ASCII box and whisker charts
our $VERSION = '0.001'; # VERSION

use Moo;
use MooX::Types::MooseLike::Base qw/Bool/;
use MooX::Types::MooseLike::Numeric qw/PositiveNum/;
use List::AllUtils qw/min max/;

use constant {
    NAME => 0,
    MIN  => 1,
    Q1   => 2,
    MED  => 3,
    Q3   => 4,
    MAX  => 5,
};



has width => (
    is      => 'ro',
    isa     => PositiveNum,
    default => sub { 72 },
);


has label_width => (
    is      => 'ro',
    isa     => PositiveNum,
    default => sub { 10 },
);


has box_weight => (
    is      => 'ro',
    isa     => PositiveNum,
    default => sub { 1 },
);


has with_scale => (
    is  => 'ro',
    isa => Bool,
);


sub render {
    my ( $self, @datasets ) = @_;
    my $gamma = 2 * max( 0, $self->box_weight || 1 );
    my $adj_width = $self->width - $self->label_width - 2;

    my $smallest_min = min( map { $_->[MIN] } @datasets );
    my $smallest_q1  = min( map { $_->[Q1] } @datasets );
    my $biggest_q3   = max( map { $_->[Q3] } @datasets );
    my $biggest_max  = max( map { $_->[MAX] } @datasets );

    my $span = ( $biggest_q3 - $smallest_q1 ) || 1;
    my $factor = $adj_width * $gamma / ( 2 + $gamma ) / $span;

    my $origin = int( $factor * ( $smallest_q1 - $span / $gamma ) );
    my $edge   = int( $factor * ( $biggest_q3 + $span / $gamma ) );
##    warn "SPAN: $span; FACTOR: $factor;  ORIGIN: $origin; EDGE: $edge; AW: $adj_width (" . ($edge - $origin) . ")\n";

    my @str;
    if ( $self->with_scale ) {
        push @str,
          ( " " x ($self->label_width) )
          . sprintf( " |%-*g%*g|",
            $adj_width / 2,
            $origin / $factor,
            $adj_width / 2,
            $edge / $factor );
    }

    for my $d (@datasets) {
        my ( $name, @copy ) = @$d;
##        warn "PRECOPY: @copy\n";
        my @scaled = ( $name, map { int( $factor * $_ ) } @copy );
##        warn "POSTCOPY: @scaled\n";
        push @str, _render_one( \@scaled, $origin, $edge, $adj_width, $self->label_width );
    }

    return wantarray ? @str : $str[0];
}

sub _render_one {
    my ( $data, $origin, $edge, $frame_size, $label_width ) = @_;
##    warn "DATA: @$data\n";
    my $str = '';
    $str .= q{ } x ( max( $data->[MIN] - $origin, 0 ) );
    $str .= q{-} x ( $data->[Q1] - max( $data->[MIN], $origin ) );
    $str .= q{=} x ( $data->[MED] - $data->[Q1] );
    $str .= "O";
    $str .= q{=} x ( $data->[Q3] - $data->[MED] );
    $str .= q{-} x ( min( $data->[MAX], $edge ) - $data->[Q3] );
    $str .= q{ } x ( max( $edge - $data->[MAX], 0 ) );
##    warn "STR: " . length($str) . "\n";
    $str = substr( $str, 0, $frame_size );
##    $str =~ s{^(.{0,$frame_size})}{$1};
##    warn "STR: " . length($str) . "\n";

    if ( substr( $str, 0, 1 ) eq '-' ) {
        substr( $str, 0, 1, "<" );
    }

    if ( substr( $str, -1, 1 ) eq '-' ) {
        substr( $str, -1, 1, "->" );
    }

    $str =~ s{\s+$}{};
    my $name = substr($data->[NAME],0, $label_width);
    return sprintf( "%*s %s", $label_width, $name, $str );
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=head1 NAME

Text::BoxPlot - Render ASCII box and whisker charts

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Text::BoxPlot;

    my $tbp = Text::BoxPlot->new( with_scale => 1 );

    say for $tbp->render(
        ["series A", -2.5, -1, 0, 1, 2.5],
        ["series B", -1, 0, 1, 2, 3.5],
        ["series C", 0, 1.5, 2, 2.5, 5.5],
    );

    # produces this output:

            |-2.70968                                               4.17742|
    series A   --------------========O========--------------
    series B                 --------========O=========--------------
    series C                         -------------====O=====--------------->

=head1 DESCRIPTION

This module generates ASCII box-and-whisker charts.

=head1 ATTRIBUTES

=head2 width

Defines the maximum total width of a rendered box-plot, including the series label.
Defaults to 72.

=head2 label_width

Defines the width of the space reserved for the series names.  Defaults to 10.

=head2 box_weight

Defines the output scale in terms of how much of the chart width should be
used for inter-quartile range boxes (the smallest 1st quartile to the
largest 3rd quartile).  The default is 1, which means half the width
is allocated to boxes and the other half allocated to whiskers outside
the box range (split between the left and right sides).

Must be a positive number.  As it gets bigger, more whiskers may get
cut off.  As it gets smaller, there is more room for extremely large
whiskers, but the box proportions may be obscured.

=head2 with_scale

If true, the first line returned by C<render> will be show
the minimum and maximum values displayed on the chart.

Defaults to false.

=head1 CONSTRUCTORS

=head2 new

    $tbp = Text::BoxPlot->new( %attributes );
    $tbp = Text::BoxPlot->new( \%attributes );

Constructs a new object.  Attributes may be passed as key-value pairs or
as a hash reference;

=head1 METHODS

=head2 render

    @lines = $tbp->render( @dataset );

Given a list of datasets, generates lines of output to render a box-and-whisker chart
in ASCII.

Each dataset must be an array reference with the following fields:

=over 4

=item *

name of the dataset

=item *

minimum value

=item *

1st quartile value

=item *

2nd quartile (median) value

=item *

3rd quartile value

=item *

maximum value

=back

For example, this code:

    my $tbp = Text::BoxPlot->new( with_scale => 1 );
    say for $tbp->render( [ 'test data', -2.5, -1, 0, 1, 2.5 ] );

Produces this output:

              |-2                                                         2|
    test data <--------------===============O===============-------------->

The greater-than and less-than signs at the edge indicate that the whisker
has been cut off at this scale.

If the C<box_weight> were set to 0.5, C<render> would produce this output:

              |-3                                                         3|
    test data      ---------------==========O==========---------------

=for Pod::Coverage method_names_here

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/text-boxplot/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/text-boxplot>

  git clone git://github.com/dagolden/text-boxplot.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
