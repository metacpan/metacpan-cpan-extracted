package XUL::Node::Application::MultipleViewsExample;

use strict;
use warnings;
use Carp;
use XUL::Node::MVC;

use base 'XUL::Node::Application';

sub start {
	my $value: Value = 0;
	Window(SIZE_TO_CONTENT,
		VBox(
			HBox(
				Button(label => '+', Click => sub { $value++ }),
				Button(label => '-', Click => sub { $value-- }),
			),
			Label(value => $value),
			TextBox(DISABLED, value => $value),
		),
	);

return tied($value); # DO NOT REMOVE!- this is for unit testing MVC
                     # and for unit tests only. Lets us check the value
                     # from the outside
}

1;










































#Window(
#	model => my $model = SelectionInListModel
#		(list_data => $phonebook->children, selected_index => 0),
#	HBox(
#		ListBoxView(renderer => sub { label => shift->name }), 
#		VBox(
#			model => Bind 'selection',
#			TextBox(value => Bind 'value.name'),
#			TextBox(value => Bind(path => 'value.age', tie => my $age)),
#			HBox(
#				Button(label => 'age++', Click => sub { $age++ }),
#				Button(label => 'dump' , Click => sub
#					{ $person_dump = $model->selected_item->dump },
#				),
#			),
#			HBox(
#				Label(value => 'dump: '),
#				Label(value => $person_dump),
#			),
#		),
#	),
#);














