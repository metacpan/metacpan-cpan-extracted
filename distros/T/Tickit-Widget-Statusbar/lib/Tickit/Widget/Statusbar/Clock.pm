package Tickit::Widget::Statusbar::Clock;
$Tickit::Widget::Statusbar::Clock::VERSION = '0.004';
use strict;
use warnings;

use parent qw(Tickit::Widget);

=head1 NAME

Tickit::Widget::Statusbar::Clock - a simple clock implementation

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Integrated as part of the default status bar.

=cut

use constant CLEAR_BEFORE_RENDER => 0;
use constant WIDGET_PEN_FROM_STYLE => 1;
use constant CAN_FOCUS => 0;

use POSIX qw(strftime floor);
use Time::HiRes ();
use curry;

sub cols { 8 }

sub lines { 1 }

sub render_to_rb {
	my $self = shift;
	my $rb = shift;

	$rb->goto(0, 0);
	$rb->text(strftime $self->time_format, localtime);
}

=head2 window_gained

Starts the timer when we get a window.

Returns $self.

=cut

sub window_gained {
	my $self = shift;
	$self->SUPER::window_gained(@_);
	$self->update;
}

sub update {
	my $self = shift;
	return unless my $win = $self->window;
	my $now = Time::HiRes::time;
	$self->redraw;
	$win->tickit->timer(
		after => (1.001 - ($now - floor($now))),
		$self->curry::update
	);
}

=head2 time_format

Our format for displaying current time.

=cut

sub time_format { '%H:%M:%S' }

1;
