package Tickit::Widget::Breadcrumb;
# ABSTRACT: breadcrumb-like interface
use strict;
use warnings;

use parent qw(Tickit::Widget);

our $VERSION = '0.003';

=head1 NAME

Tickit::Widget::Breadcrumb - render a breadcrumb trail

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Breadcrumb;
 my $bc = Tickit::Widget::Breadcrumb->new;
 $bc->adapter->push([
  qw(home perl site-lib)
 ]);
 Tickit->new(root_widget => $bc)->run;

=head1 DESCRIPTION

Provides a widget for showing "breadcrumbs".

Accepts focus.

Use left/right to navigate, enter to select.

Render looks something like:

 first < second | current | next > last

=head2 ITEM TRANSFORMATIONS

See L</new>.

=cut

use curry::weak;

use Adapter::Async::OrderedList::Array;

use Tickit::Debug;
use Tickit::Style;
use Tickit::Utils qw(textwidth);
use List::Util qw(sum0);

use constant CAN_FOCUS => 1;
use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;

BEGIN {
	style_definition base =>
		powerline    => 0,
		block        => 0,
		right_fg     => 'grey',
		left_fg      => 'white',
		highlight_fg => 'hi-white',
		highlight_bg => 'green';

	style_definition ':focus' =>
		'<Left>' => 'prev',
		'<Right>' => 'next',
		'<Enter>' => 'select';
}

=head1 METHODS

=cut

=head2 new

Instantiate. The following named parameters may be of use:

=over 4

=item * item_transformations - a coderef or arrayref of transformations to
apply to items received from the adapter.

=item * skip_first - number of items to skip at the start when rendering, default 0

=back

An example of transformations:

 my $bc = Tickit::Widget::Breadcrumb->new(
  item_transformations => sub {
   my $item = shift;
   strftime '%Y-%m-%d %H:%M:%S', localtime $item
  }
 );
 $bc->push([ time ]);

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $transform = delete $args{item_transformations};
	my $skip = delete $args{skip_first};
	$transform ||= [];
	$transform  = [$transform] if ref $transform eq 'CODE';
	my $self = $class->SUPER::new(%args);
	$self->{item_transformations} = $transform;
	$self->{skip_first} = $skip // 0;
	$self
}

=head2 lines

Returns the number of lines this widget would like.

=cut

sub lines { 1 }

=head2 cols

Returns the number of columns this widget would like.

=cut

sub cols { 1 }

=head2 render_to_rb

Perform rendering.

=cut

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	unless($self->{crumbs}) {
		$rb->eraserect(
			$rect,
		);
		$rb->text_at(0,0, 'Please wait...');
		return;
	}

	$rb->eraserect(
		$rect,
		$self->get_style_pen(
			$self->highlight == $#{$self->{crumbs}}
			? 'highlight'
			: 'right'
		)
	);

	foreach my $idx (0..$#{$self->{crumbs}}) {
		$self->render_item($rb, $rect, $idx);
		last if $idx == $#{$self->{crumbs}};
		$self->render_separator($rb, $rect, $idx);
	}
}

{
my $order = [qw(left highlight right)];
sub render_item {
	my ($self, $rb, $rect, $idx) = @_;
	my $pen = $self->get_style_pen(
		$order->[1 + ($idx <=> $self->highlight)]
	);
#	warn "Item at $idx is ". $self->{crumbs}[$idx] . "\n";
	$rb->text_at(0, $self->item_col($idx), $self->{crumbs}[$idx], $pen);
}
}

=head2 render_separator

Renders the separator between two items.

Pass the index of the item on the left.

There are 3 cases:

=over 4

=item * inactive to inactive

=item * inactive to active

=item * active to inactive

=back

=cut

sub render_separator {
	my ($self, $rb, $rect, $idx) = @_;

	my $x = $self->item_col($idx) + textwidth $self->{crumbs}[$idx];
	if($self->highlight == $idx) {
		# active => inactive
		$rb->text_at(0, $x, " ", $self->get_style_pen('highlight'));
		my $pen = Tickit::Pen->new(
			fg => $self->get_style_pen('highlight')->getattr('bg'),
			bg => $self->get_style_pen('right')->getattr('bg'),
		);
		$rb->text_at(
			0,
			$x + 1,
			  $self->get_style_values('powerline')
			? "\N{U+E0B0}"
			: $self->get_style_values('block')
			? "\N{U+258C}"
			: "|",
			$pen
		);
		$rb->text_at(0, $x + 2, " ", $self->get_style_pen('right'));
	} elsif($self->highlight == $idx + 1) {
		# inactive => active
		$rb->text_at(0, $x, " ", $self->get_style_pen());
		my $pen = Tickit::Pen->new(
			bg => $self->get_style_pen('left')->getattr('bg'),
			fg => $self->get_style_pen('highlight')->getattr('bg'),
		);
		$rb->text_at(
			0,
			$x + 1,
			  $self->get_style_values('powerline')
			? "\N{U+E0B2}"
			: $self->get_style_values('block')
			? "\N{U+2590}"
			: "|",
			$pen
		);
		$rb->text_at(0, $x + 2, " ", $self->get_style_pen('highlight'));
	} elsif($self->highlight < $idx) {
		# inactive => inactive, to right of highlight
		$rb->text_at(0, $x, $self->get_style_values('powerline') ? " \N{U+E0B1} " : ' > ', $self->get_style_pen('right'));
	} else {
		# inactive => inactive, left
		$rb->text_at(0, $x, $self->get_style_values('powerline') ? " \N{U+E0B3} " : ' > ', $self->get_style_pen('left'));
	}
}

sub separator_col {
	my ($self, $idx) = @_;
	return -2 + sum0 map $self->item_width($_), 0..$idx;
}

sub item_col {
	my ($self, $idx) = @_;
	return unless my $win = $self->window;
	sum0 map $self->item_width($_), 0..$idx - 1;
}

sub highlight { shift->{highlight} }
sub crumbs { @{ shift->{crumbs} } }

sub update_crumbs {
	my ($self) = @_;
	$self->adapter->all->on_done(sub {
		my $data = shift;
		my @copy = @$data;
		splice @copy, 0, $self->skip_first if $self->skip_first;
		$self->{crumbs} = [ map $self->transform_item($_), @copy ];
		$self->window->expose if $self->window;
	});
}

sub skip_first { shift->{skip_first} }

=head2 transform_item

Applies any transformations to the given item.

Currently these are immediate transformations, i.e. no support for L<Future>s.
This may change in a newer versions, but you should be safe as long as you return
a string or L<String::Tagged> rather than a L<Future> here.

See L<ITEM TRANSFORMATIONS> for details.

=cut

sub transform_item {
	my ($self, $item) = @_;
	$item = $_->($item) for @{$self->{item_transformations}};
	$item
}


=head2 adapter

Returns the adapter responsible for dealing with the underlying data.

If called with no parameters, will return the current adapter (creating one if necessary).

If called with a parameter, will set the adapter to that value,
assigning a new default adapter if given undef. Will then return
$self to allow for method chaining.

=cut

sub adapter {
	my $self = shift;
	return $self->{adapter} if $self->{adapter} && !@_;

	my ($adapter) = @_;

	if(my $old = delete $self->{adapter}) {
		$old->bus->unsubscribe_from_event(
			splice @{$self->{adapter_subscriptions}}
		);
	}
	$adapter ||= Adapter::Async::OrderedList::Array->new;
	$self->{adapter} = $adapter;

	$adapter->bus->subscribe_to_event(
		@{ $self->{adapter_subscriptions} = [
			splice => $self->curry::weak::on_splice_event,
			clear => $self->curry::weak::on_clear_event,
		] }
	);
	$self->update_crumbs;
	$self->window->expose if $self->window;
	@_ ? $self : $self->{adapter};
}

sub window_gained {
	my ($self, $win) = @_;
	$self->{highlight} //= 0;
	$self->update_cursor;
	$self->SUPER::window_gained($win);
}

sub on_splice_event {
	my ($self) = @_;
	$self->update_crumbs
}

sub on_clear_event {
}

sub update_cursor {
	my ($self) = @_;
	return unless my $win = $self->window;
	$win->cursor_at(0, $self->item_col($self->highlight));
	$win->cursor_visible(0);
}

sub item_width {
	my ($self, $idx) = @_;
	3 + textwidth $self->{crumbs}[$idx];
}

sub key_prev {
	my ($self) = @_;
	return unless $self->{highlight};
	--$self->{highlight};
	return unless $self->window;
	$self->update_cursor;
	$self->window->expose;
}

sub key_next {
	my ($self) = @_;
	return unless $self->{crumbs};
	return if $self->{highlight} == $#{$self->{crumbs}};
	++$self->{highlight};
	return unless $self->window;
	$self->update_cursor;
	$self->window->expose;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Tickit::Widgets> - the standard Tickit widgetset.

=item * L<Tickit>

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.
