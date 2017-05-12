package Tickit::Widget::Calendar::MonthView;
$Tickit::Widget::Calendar::MonthView::VERSION = '0.001';
use strict;
use warnings;

use parent qw(Tickit::Widget);

=head1 NAME

Tickit::Widget::Calendar::MonthView

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Highlight - this is the entry the cursor is currently over, we may
not have activated it (yet?) though.
Selected - this is selected but not necessarily active
Current - this is an entry marked as 'current', typically the current day
Events - this entry has events

=head1 METHODS

=cut

use POSIX qw(strftime mktime);
use Tickit::Utils qw(textwidth align distribute);

use Tickit::Style;

use constant CAN_FOCUS => 1;

BEGIN {
	style_definition 'base' =>
		month_fg    => 'white',
		weekday_fg  => 'white',
		monthday_fg => 'white',
		today_fg    => 'white',
		today_bg    => 'black',
		today_b     => 1;
}

=head2 cols

Minimum size requirement for displaying this entry.

=cut

sub cols { 3 * 7 }
sub lines { 6 }

sub day {
	my $self = shift;
	if(@_) {
		my $prev = $self->{day};
		$self->{day} = shift;
		$self->expose_day($_) for grep defined, $prev, $self->{day};
		return $self;
	}
	return $self->{day};
}

sub month {
	my $self = shift;
	if(@_) {
		$self->{month} = shift;
		$self->redraw;
		return $self;
	}
	return $self->{month};
}

sub year {
	my $self = shift;
	if(@_) {
		$self->{year} = shift;
		$self->redraw;
		return $self;
	}
	return $self->{year};
}

sub expose_day {
	my $self = shift;
	$self->redraw;
}

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window;

	{ # Month and year
		my $ts = mktime 0, 0, 0, $self->day, $self->month - 1, $self->year - 1900;
		my $txt = strftime('%B %Y', localtime $ts);
		my ($before, $actual, $after) = align(textwidth($txt), $win->cols, 0.5);
		$rb->text_at(0, 0, (' ' x $before) . $txt . (' ' x $after), $self->get_style_pen('month'));
	}

	# Days of the week
	my @weekdays = (
		map { base => 3, expand => 1, day => strftime('%a', localtime mktime 0,0,0,17 + $_,11,95) }, 1..7
	);
	distribute($win->cols, @weekdays);
	for (@weekdays) {
		my ($before, $actual, $after) = align textwidth($_->{day}), $_->{value}, 0.5;
		$rb->text_at(1, $_->{start}, (' ' x $before) . $_->{day} . (' ' x $after), $self->get_style_pen('weekday'));
	}

	{ # Days of the month
		my $rows = $win->lines - 2;
		my $days_in_month = (localtime mktime 0, 0, 0, 0, $self->month, $self->year - 1900)[3];
		my $weekday = (localtime mktime 0, 0, 0, 1, $self->month - 1, $self->year - 1900)[6] - 1;
		$weekday += 7 while $weekday < 0;
		my @rows;
		my $data = [];
		for my $day_of_month (1..$days_in_month) {
			push @$data, {
				day => $day_of_month,
				weekday => $weekday
			};
			if(++$weekday > 6) {
				$weekday = 0;
				push @rows, {
					base => 1,
					expand => 1,
					data => $data,
				};
				$data = [];
			}
		}
		push @rows, {
			base => 1,
			expand => 1,
			data => $data,
		} if @$data;
		distribute(
			$rows,
			@rows
		);
		for my $entry (@rows) {
			for my $col (@{$entry->{data}}) {
				my ($before, $actual, $after) = align textwidth($col->{day}), $weekdays[$col->{weekday}]->{value}, 0.5;
				$rb->text_at(
					2 + $entry->{start},
					$weekdays[$col->{weekday}]->{start},
					(' ' x $before) . $col->{day} . (' ' x $after),
					$self->get_style_pen(($col->{day} == $self->day) ? 'today' : 'monthday')
				);
			}
		}
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
