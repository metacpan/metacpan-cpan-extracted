package Tickit::Widget::SparkLine;
# ABSTRACT: Simple 'sparkline' widget implementation
use strict;
use warnings;
use parent qw(Tickit::Widget);

our $VERSION = '0.106';

=head1 NAME

Tickit::Widget::SparkLine - minimal graph implementation for L<Tickit>

=head1 VERSION

version 0.106

=head1 SYNOPSIS

 my $vbox = Tickit::Widget::VBox->new;
 my $widget = Tickit::Widget::SparkLine->new(
    data   => [ 0, 3, 2, 5, 1, 6, 0, 7 ]
 );
 $vbox->add($widget, expand => 1);

=head1 DESCRIPTION

Generates a mini ("sparkline") graph.

=begin HTML

<p><img src="http://tickit.perlsite.co.uk/cpan-screenshot/tickit-widget-sparkline1.gif" alt="Sparkline widget in action" width="350" height="192"></p>

=end HTML

=head1 STYLE

Set the base style background/foreground to determine the graph colours.
Note that reverse video and bold don't work very well on some terminals,
since the background+foreground colours won't match.

=cut

use POSIX qw(floor);
use Scalar::Util qw(reftype);
use List::Util qw(max sum min);
use Tickit::Utils qw(textwidth);
use Tickit::Style;
use constant WIDGET_PEN_FROM_STYLE => 1;

BEGIN {
	style_definition base =>
		fg => 'white';
}

=head1 METHODS

=cut

sub lines { 1 }

sub cols {
	my $self = shift;
	scalar @{$self->{data}}
}

=head2 new

Instantiate the widget. Takes the following named parameters:

=over 4

=item * data - graph data

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $data = delete $args{data};
	my $self = $class->SUPER::new(%args);
	$self->{data} = $data || [];
	$self->resized if $data;
	return $self;
}

=head2 data

Accessor for stored data.

With no parameters, returns the stored data as a list.

Pass either an array or an arrayref to set the data values and request display refresh.

=cut

sub data {
	my $self = shift;
	if(@_) {
		$self->{data} = [ (ref($_[0]) && reftype($_[0]) eq 'ARRAY') ? @{$_[0]} : @_ ];
		delete $self->{max_value};
		$self->resized;
	}
	return @{ $self->{data} };
}

=head2 data_chars

Returns the set of characters corresponding to the current data values. Each value
is assigned a single character, so the string length is equal to the number of data
items and represents the minimal string capable of representing all current data
items.

=cut

sub data_chars {
	my $self = shift;
	return join '', map { $self->char_for_value($_) } $self->data;
}

=head2 push

Helper method to add one or more items to the end of the list.

 $widget->push(3,4,2);

=cut

sub push : method {
	my $self = shift;
	push @{$self->{data}}, @_;
	delete $self->{max_value};
	$self->resized;
}

=head2 pop

Helper method to remove one item from the end of the list, returns the item.

 my $item = $widget->pop;

=cut

sub pop : method {
	my $self = shift;
	my $item = pop @{$self->{data}};
	delete $self->{max_value};
	$self->resized;
	return $item;
}

=head2 shift

Helper method to remove one item from the start of the list, returns the item.

 my $item = $widget->shift;

=cut

sub shift : method {
	my $self = shift;
	my $item = shift @{$self->{data}};
	delete $self->{max_value};
	$self->resized;
	return $item;
}

=head2 unshift

Helper method to add items to the start of the list. Takes a list.

 $widget->unshift(0, 1, 3);

=cut

sub unshift : method {
	my $self = shift;
	unshift @{$self->{data}}, @_;
	delete $self->{max_value};
	$self->resized;
}

=head2 splice

Equivalent to the standard Perl L<splice> function.

 # Insert 3,4,5 at position 2
 $widget->splice(2, 0, 3, 4, 5);

=cut

sub splice : method {
	my $self = shift;
	my ($offset, $length, @values) = @_;

# Specify parameters directly since splice applies a @$$@-ish prototype here
	my @items = splice @{$self->{data}}, $offset, $length, @values;
	delete $self->{max_value};
	$self->resized;
	return @items;
}

=head2 graph_steps

Returns an arrayref of characters in order of magnitude.

For example:

 [ ' ', qw(_ x X) ]

would yield a granularity of 4 steps.

Override this in subclasses to provide different visualisations - there's no limit to the number of
characters you provide in this arrayref.

=cut

sub graph_steps { [
	ord " ",
	0x2581,
	0x2582,
	0x2583,
	0x2584,
	0x2585,
	0x2586,
	0x2587,
	0x2588
] }

=head2 resample

Given a width $w, resamples the data (remaining list of
parameters) to fit, using the current L</resample_method>.

Used internally.

=cut

sub resample {
	my $self = shift;
	my ($total_width, @data) = @_;
	my $xdelta = $total_width / @data;
	my $x = 0;
	my @v;
	my @out;
	my $mode = {
		average => sub { sum(@_) / @_ },
		mean => sub { sum(@_) / @_ },
		median => sub {
			my @sorted = sort { $a <=> $b } @_;
			(@sorted % 2) ? $sorted[@_ / 2] : (sum(@sorted[@_ / 2, 1 + @_ / 2]) / 2) },
		peak => sub { max @_ },
		min => sub { min @_ },
		max => sub { max @_ },
	}->{$self->resample_mode} or die 'bad resample mode: ' . $self->resample_mode;

	for (@data) {
		my $last_x = $x;
		$x += $xdelta;
		push @v, $_;
		if(floor($x) - floor($last_x)) {
			push @out, $mode->(@v);
			@v = ();
		}
	}
	@out;
}

=head2 render_to_rb

Rendering implementation. Uses L</graph_steps> as the base character set.

=cut

sub render_to_rb {
	my ($self, $rb) = @_;
	my $win = $self->window or return;
	$rb->clear;

	my @data = @{$self->{data}};
	my $total_width = $win->cols;
	my $w = $total_width / (@data || 1);
	my $floored_w = floor $w;

	# Apply minimum per-cell width of 1 char, and resample data to fit
	unless($floored_w) {
		$w = 1;
		$floored_w = 1;
		@data = $self->resample($total_width => @data);
	}

	my $win_height = $win->lines;
	my $x = 0;
	my $range = $#{$self->graph_steps};
	my $fg_pen = $self->get_style_pen;
	my $bg_pen = Tickit::Pen->new(
		bg => $fg_pen->getattr('fg'),
		map {; $_ => $fg_pen->getattr($_) } qw(rv b)
	);
	foreach my $item (@data) {
		my $v = $item * $win_height / $self->max_value;
		my $top = $win_height - floor( $v);
		my $left = floor(0.5 + $x);
		my $bar_width = (floor(0.5 + $x + $w) - $left);
		for my $y ($top .. $win_height) {
			$rb->erase_at($y, $left, $bar_width, $bg_pen);
		}
		my $ch = $self->graph_steps->[floor(0.5 + $range * ($v - floor($v)))];
		$rb->char_at($top - 1, $left + $_, $ch, $fg_pen) for 0..$bar_width-1;
		$x += $w;
	}
}

=head2 char_for_value

Returns the character code corresponding to the given data value.

=cut

sub char_for_value {
	my $self = shift;
	my $item = shift;
	my $range = $#{$self->graph_steps};
	return $self->graph_steps->[$item * $range / $self->max_value];
}

=head2 max_value

Returns the maximum value seen so far, used for autoscaling.

=cut

sub max_value {
	my $self = shift;
	return $self->{max_value} if exists $self->{max_value};
	return $self->{max_value} = max($self->data);
}

=head2 resample_mode

Change method for resampling when we have more data than will fit on the graph.

Current values include:

=over 4

=item * average - takes the average of combined values for this bucket

=item * min - lowest value for this bucket

=item * median - highest value for this bucket

=item * max - largest value for this bucket

=item * peak - alias for 'max'

=back

The default is 'average'.

Returns $self if setting a value, or the current value.

=cut

sub resample_mode {
	my $self = shift;
	if(@_) {
		$self->{resample_mode} = shift;
		return $self;
	}
	return $self->{resample_mode} // 'average';
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
