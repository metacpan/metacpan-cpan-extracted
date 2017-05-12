package Tickit::Widget::Progressbar::Horizontal;
$Tickit::Widget::Progressbar::Horizontal::VERSION = '0.101';
use strict;
use warnings;
use parent qw(Tickit::Widget::Progressbar);

=head1 NAME

Tickit::Widget::Progressbar::Horizontal - simple progressbar implementation for Tickit

=head1 VERSION

Version 0.101

=head1 SYNOPSIS

 my $bar = Tickit::Widget::Progressbar::Horizontal->new(
 	completion	=> 0.00,
 );

=head1 DESCRIPTION

See L<Tickit::Widget::Progressbar>.

=cut

use POSIX qw(floor);
use List::Util qw(min);

# Undocumented feature for gradient support. Needs Tickit::Colour,
# since that's not on CPAN then there's little point in enabling this.
use constant ENABLE_GRADIENT => 0;

=head1 METHODS

=cut

sub render_to_rb {
	my $self = shift;
	return $self->render_gradient(@_) if ENABLE_GRADIENT && scalar $self->get_style_values('gradient');
	return $self->render_normal(@_);
}

sub render_gradient {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window or return;

	$rb->clear;

	my $total_width = $win->cols;
	my $chars = $self->chars;
	my $complete = $self->completion * $total_width;

	my $start = $self->get_style_pen('start');
	my $src = $self->get_style_pen;
	my $dst = Tickit::Pen->new(
		fg => $src->getattr('bg'),
		bg => $src->getattr('fg')
	)->default_from($src);
	my $fg = $src;
	my $bg = $dst;
	foreach my $line (0..$win->lines - 1) {
		$rb->goto($line, 0);
		my $w = floor($complete);
		if($self->direction) {
			$rb->erase($w, $fg);
		} else {
			for(0..$w-1) {
				$fg = $self->pen_for_position(
					pos => $_,
					total => $total_width,
					from => 'fg',
					to => 'bg',
					start => $src,
					end => $start,
				);
				$rb->erase_at($line, $_, 1, $fg);# for 0..$w-1;
			}
			# $rb->char_at($line, $_, $chars->[-1], $fg) for 0..$w-1;
		}
		if(my $partial = ($complete - $w) * @$chars) {
#			++$w;
			$fg = $self->pen_for_position(
				pos => $w,
				total => $total_width,
				from => 'fg',
				end => $start,
				start => $src
			);
			$rb->char_at($line, $w, $chars->[$partial], $self->direction ? $bg : $fg);
		}
		unless($w >= $total_width) {
			if($self->direction) {
				$rb->char_at($line, $w + $_, $chars->[-1], $fg) for 1..($total_width - $w - 1);
			} else {
				$rb->erase_at($line, $w+1, $total_width - $w, $src);
			}
		}
	}
}

sub render_normal {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window or return;

	$rb->clear;

	my $total_width = $win->cols;
	my $chars = $self->chars;
	my $complete = $self->completion * $total_width;

	# Generate a reversed version of the real pen,
	# since reverse video does not give accurate colours
	# for some terminals (gnome-terminal for example).
	my $fg = $self->get_style_pen;
	my $bg = Tickit::Pen->new(
		fg => $fg->getattr('bg'),
		bg => $fg->getattr('fg')
	)->default_from($fg);

	foreach my $line (0..$win->lines - 1) {
		$rb->goto($line, 0);
		my $w = floor($complete);
		if($self->direction) {
			$rb->erase($w, $fg);
		} else {
			$rb->erase_at($line, 0, $w, $bg);# for 0..$w-1;
			# $rb->char_at($line, $_, $chars->[-1], $fg) for 0..$w-1;
		}
		if(my $partial = ($complete - $w) * @$chars) {
#			++$w;
			$rb->char_at($line, $w, $chars->[$partial], $self->direction ? $bg : $fg);
		}
		unless($w >= $total_width) {
			if($self->direction) {
				$rb->char_at($line, $w + $_, $chars->[-1], $fg) for 1..($total_width - $w - 1);
			} else {
				$rb->erase_at($line, $w+1, $total_width - $w, $fg);
			}
		}
	}
}

=head2 chars

Returns a list of chars for the various styles we support.

Currently only handles 'ascii' and 'boxchar'.

TODO - this should probably be aligned with the naming
scheme used in other widgets?

=cut

sub chars {
	my $self = shift;
	return {
		ascii	=> [qw(| X)],
		boxchar	=> [
			0x258F,
			0x258E,
			0x258D,
			0x258C,
			0x258B,
			0x258A,
			0x2589,
			0x2588,
		],
	}->{$self->style};
}

sub position_for {
	my $self = shift;
	# return $self->window->cols - floor(shift() * $self->window->cols);
	return floor(shift() * $self->window->cols);
}

sub expose_between_values {
	my $self = shift;
	return $self unless $self->window;

	my ($prev, $next) = map $self->position_for($_), @_;
	$self->window->expose(
		Tickit::Rect->new(
			left  => min($prev, $next) - 1,
			top => 0,
			lines => $self->window->lines,
			cols => abs($next - $prev) + 2,
		)
	);
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Tickit::Widget::SparkLine>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2013. Licensed under the same terms as Perl itself.
