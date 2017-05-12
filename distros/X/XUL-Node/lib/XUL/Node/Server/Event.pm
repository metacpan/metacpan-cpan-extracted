package XUL::Node::Server::Event;

use strict;
use warnings;
use Carp;
use Aspect;
use XUL::Node;

# aspect setup ----------------------------------------------------------------

my %EVENTS = (
	Click  => 'checked',
	Change => 'value',
	Select => 'selectedIndex',
	Pick   => 'color',
);

while (my ($k, $v) = each %EVENTS) {
	eval "sub XUL::Node::handle_client_event_$k {}";
	croak "cannot create event trigger [$k]: $@" if $@;
	aspect Listenable => (
		$k => call("XUL::Node::handle_client_event_$k"),
		$v? ($v => $v): (),
		__always_fire => 1,
	);
}

# public API ------------------------------------------------------------------

sub new {
	my ($class, $request) = @_;
	my $self   = bless {}, $class;
	my $name   = $request->{name};

	croak "cannot create event with no name"   unless $name;
	croak "cannot create event with no source" unless $request->{source};
	croak "illegal event name"                 unless $name =~ /^\w+$/;

	$self->{$_} = $request->{$_} for keys %$request;
	$self->handle_direct_side_effects;
	return $self;
}

sub fire {
	my $self   = shift;
	my $name   = $self->name;
	my $source = $self->source;
	my $method = "handle_client_event_$name";
	croak "unknown event name: [$name]" unless $source->can($method);
	$self->handle_indirect_side_effects;
	$source->$method();
}

sub AUTOLOAD {
	my $self = shift;
	my $key  = our $AUTOLOAD;
	return if $key =~ /DESTROY$/;
	$key =~ s/^.*:://;
	return $self->{$key} if @_ == 0;
	$self->{$key} = shift;
}

# side effect handling --------------------------------------------------------

# this code runs outside the context of client-server XUL sync
# no changes to the XUL tree caused by its call flow are synced to client
# it is called the moment the event is received from the client
sub handle_direct_side_effects {
	my $self       = shift;
	my $direct_key = '_'. $EVENTS{$self->name};
	my $key        = $EVENTS{$self->name};
	if ($self->name eq 'Click') {
		my $checked = $self->checked;
		$checked = defined $checked && $checked eq 'true'? 1: 0;
		$self->checked($checked);
	}
	$self->source->$direct_key($self->$key);
}

# this code runs inside the context of client-server XUL sync
# all changes to the XUL tree caused by its call flow are synced to client
sub handle_indirect_side_effects {
	my $self = shift;
	my $key = $EVENTS{$self->name};
	$self->source->$key($self->$key);
}

1;

=head1 NAME

XUL::Node::Event - a user interface event

=head1 SYNOPSYS

  use XUL::Node;

  # listening to existing widget
  add_listener $button => Click => sub { print 'clicked!' };

  # listening to widget in constructor, listener prints event value
  TextBox(Change => sub { print shift->value });

  # more complex listeners
  add_listener $check_box => (Click => sub {
     my $event = shift; # event is the only argument
     print
       'source: '   . $event->source,  # source widget, a XUL::Node
       ', name: '   . $event->name,    # Click
       ', checked: '. $event->checked; # Perl boolean
  });

=head1 DESCRIPTION

Events are objects recieved as the only argument to a widget listener
callback. You can interrogate them for information concerning the event.

Each type of widget has one or more event types that it fires. Buttons
fire C<Click>, for example, but list boxes fire C<Select>.

Events from the UI can have side effects: a change in the textbox on the
screen, requires that the C<value> attribute of the Perl textbox object
change as well, to stay in sync. This happens automatically, and
I<before> listener code is run.

=head1 EVENT TYPES

All events have a C<name> and a C<source>. Each possible event name, can
have additional methods for describing that specific event:

=over 4

=item Click

C<Button, ToolBarButton, MenuItem when inside a Menu, CheckBox, Radio>.
Checkbox and radio events provide a method C<checked>, that returns the
widget state as a boolean.

=item Change

C<TextBox>. C<value> will return the new textbox value.

=item Select

C<MenuList, ListBox, Button with TYPE_MENU>. C<selectedIndex> will return
the index of the selected item in the widget.

=item Pick

C<ColorPicker>. C<color> will return the RGB value of the color selected.

=back

=head1 SEE ALSO

C<Aspect::Library::Listenable>

=cut
