package Tickit::Widget::Progressbar;
# ABSTRACT: horizontal/vertical progress bars for Tickit
use strict;
use warnings;
use parent qw(Tickit::Widget);

our $VERSION = '0.101';

=head1 NAME

Tickit::Widget::Progressbar - simple progressbar implementation for Tickit

=head1 VERSION

Version 0.101

=head1 SYNOPSIS

 use Tickit::Widget::Progressbar::Horizontal;
 my $bar = Tickit::Widget::Progressbar::Horizontal->new(
 	completion	=> 0.00,
 );
 $bar->completion($_ / 100.0) for 0..100;

=head1 DESCRIPTION

Provides support for a 'progress bar' widget. Use the L<Tickit::Widget::Progressbar::Horizontal>
or L<Tickit::Widget::Progressbar::Vertical> subclasses depending on whether you want the progress
bar to go from left to right or bottom to top.

=cut

use Tickit::Style;

use constant CLEAR_BEFORE_RENDER => 0;
use constant WIDGET_PEN_FROM_STYLE => 0;
use constant CAN_FOCUS => 0;

BEGIN {
	style_definition base =>
		fg => 255,
		bg => 'black',
		gradient => 0,
		start_fg => 232;
}

=head1 METHODS

=cut

sub lines { 1 }
sub cols { 1 }

=head2 new

Instantiate a new L<Tickit::Widget::Progressbar> object. Takes the following named parameters:

=over 4

=item * completion - a value from 0.0 to 1.0 indicating progress

=item * orientation - 'vertical' or 'horizontal'

=item * direction - whether progress goes forwards (left to right, bottom to top) or backwards
(right to left, top to bottom).

=back

Note that this is a base class, and the appropriate L<Tickit::Widget::Progressbar::Horizontal>
or L<Tickit::Widget::Progressbar::Vertical> subclass should be used when instantiating a real
widget.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $completion = delete $args{completion};
	my $orientation = delete $args{orientation};
	my $direction = delete $args{direction};
	my $self = $class->SUPER::new(%args);
	$self->{completion} = $completion || 0.0;
	$self->{orientation} = $orientation || 'horizontal';
	$self->{direction} = $direction || 0;
	return $self;
}

sub orientation { 'horizontal' }
sub style { 'boxchar' }
sub direction { shift->{direction} }

=head2 completion

Accessor for the current progress bar completion state - call this with a float value from 0.00..1.00
to set completion and re-render.

=cut

sub completion {
	my $self = shift;
	if(@_) {
		my $previous = $self->{completion};
		$self->{completion} = shift;
		if(defined $previous) {
			# Not entirely sure this part is working reliably enough yet
#			$self->expose_between_values($previous, $self->{completion});
			$self->redraw;
		} else {
			$self->redraw;
		}
		return $self;
	}
	return $self->{completion};
}

sub pen_for_position {
	my $self = shift;
	my %args = @_;
	$self->{gradient_pen} ||= {};
	$self->{gradient_pen}{join ',', map { $_ => $args{$_} } sort keys %args} ||= do {
		my @start = Tickit::Colour->colour_to_rgb($args{start}->getattr($args{from}));
		my @end = Tickit::Colour->colour_to_rgb($args{end}->getattr($args{from}));
		my $col = Tickit::Colour->rgb_to_colour(map {
				($start[$_] * $args{pos} + $end[$_] * ($args{total} - $args{pos})) / $args{total}
			} 0..2);
		my %extra = map {; /^extra_(.*)$/ ? ($1 => $args{$_}) : () } keys %args;

		Tickit::Pen::Immutable->new(
			($args{to} || $args{from}) => $col,
			%extra,
		);
	};
}

1;

__END__

=head1 SEE ALSO

L<Tickit>

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2013. Licensed under the same terms as Perl itself.
