package XUL::Node::Application::RemoveChildExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

use constant BUTTON_STYLE => (style => 'font-weight: bold; font-size: 17pt');

# demonstrates removing widgets, and adding widgets at a specific index

sub start {
	my $self = shift;
	Window(
		VBox(FILL,
			HBox(
				Button(BUTTON_STYLE, FLEX,
					label       => '+',
					tooltiptext => 'add item at selected index',
					Click       => [add => $self],
				),
				my $remove_button = Button(BUTTON_STYLE, FLEX, DISABLED,
					label       => '-',
					tooltiptext => 'remove selected item',
					Click       => [remove => $self],
				),
			),
			my $list = ListBox(FILL),
		),
	);
	$self->{list} = $list;
	$self->{remove_button} = $remove_button;
}

sub add {
	my $self  = shift;
	my $list  = $self->{list};
	my $index = $list->child_count? $list->selectedIndex + 1: 0;
	$list->add_child(ListItem(label => rand() * 10), $index);
	$self->{remove_button}->disabled(0);
	$self->select_and_ensure_visible($index);
}

sub remove {
	my $self  = shift;
	my $list  = $self->{list};
	return unless $list->child_count;
	my $index = $list->selectedIndex;
	$list->remove_child($index);
	unless ($list->child_count) {
		$self->{remove_button}->disabled(1);
		return;
	}
	--$index if $index;
	$self->select_and_ensure_visible($index);
}

sub select_and_ensure_visible {
	my ($self, $index) = @_;
	$self->{list}->
		selectedIndex($index)->
		ensureIndexIsVisible($index);
}

1;
