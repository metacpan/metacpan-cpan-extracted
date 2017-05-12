package XUL::Node;

use strict;
use warnings;
use Carp;
use Scalar::Util qw(weaken);
use Aspect::Library::Listenable;
use XUL::Node::Constants;

our $VERSION = '0.06';

# hash of class => keys for all custom widgets that were imported
# this allows custom widgets to pass their constructor parameters
# unharmed through the XUL::Node constructor DWIMer
my %Widget_Keys = ();

# creating --------------------------------------------------------------------

sub new {
	my $class = shift;
	my $self = bless {
		attributes   => {},
		children     => [],
		parent_node  => undef,
		is_destroyed => 0,
	}, $class;
	my %subclass_params = ();
	# what's in my @_?
	while (my $param = shift @_) {

		if (UNIVERSAL::isa($param, __PACKAGE__)) # a node
			{ $self->add_child($param) }

		elsif ($Widget_Keys{$class} && $Widget_Keys{$class}->{$param}) # not me
			{ $subclass_params{$param} = $_[0]; shift }

		elsif ($param =~ /^[a-z]/) # an attribute
			# must reference @_ directly, so as not to lose the ties
			{ $self->set_attribute($param => $_[0]); shift }

		elsif ($param =~ /^[A-Z]/) # an event listener
			{ add_listener $self, $param => shift }

		else
			{ croak "unrecognized param: [$param]" }

	}
	$self->init(%subclass_params);
	# if tag has not been set by subclass init or in params, then we get it from
	# the template method
	$self->tag( $self->my_tag ) unless $self->tag;
	return $self;
}

# template methods
sub init    {}
sub my_keys { () }
sub my_tag  { 'Box' }
sub my_name {
	my $package = shift;
	$package =~ /([^:]+)$/; # last part of Perl package name
	return $1;
}

# attribute handling ----------------------------------------------------------

sub attributes     { wantarray? %{shift->{attributes}}: shift->{attributes} }
sub get_attribute  { shift->attributes->{pop()} }
# For our friends the aspects, we set attribute in 2 stages. set_attribute
# delegates to _set_attribute, and does nothing else. 2 different aspects
# need 2 different pointcuts:
#  1) MVC advises set_attribute, listenable models call _set_attribute
#  2) change manager advises _set_attribute
# The public API is set_attribute.
# _set_attribute exists so that we can have a 2 way binding between between
# widget and model, yet avoid infinite event firing cycles.
# Event calls them both when a client event is received- _set_attribute when
# created, set_attribute when fired
sub set_attribute  { $_[0]->_set_attribute($_[1], $_[2]) }
sub _set_attribute { $_[0]->attributes->{pop()} = pop; $_[0] }

# all unhandled calls go to g/set attribute
sub AUTOLOAD {
	my $self = shift;
	my $key  = our $AUTOLOAD;
	return if $key =~ /DESTROY$/;
	$key =~ s/^.*:://;
	return
		$key =~ /^[a-z]/? # property access?
			@_ == 0? # property get?
				$self->get_attribute($key):
				$self->set_attribute($key, shift):
			$key =~ /^_([a-z].*)/? # direct property access?
				$self->_set_attribute($1, shift):
				croak __PACKAGE__. "::AUTOLOAD: no message called [$key]";
}

# compositing -----------------------------------------------------------------

sub children        { wantarray? @{shift->{children}}: shift->{children} }
sub child_count     { scalar @{shift->{children}} }
sub first_child     { shift->{children}->[0] }
sub get_child       { shift->{children}->[pop] }
sub get_parent_node { shift->{parent_node} }

sub set_parent_node {
	my ($self, $parent_node) = @_;
	croak "cannot re-parent node" if $self->{parent_node} && $parent_node;
	$self->{parent_node} = $parent_node;
	weaken $parent_node;
}

sub add_child {
	my ($self, $child, $index) = @_;
	my $child_count = $self->child_count;
	$index = $child_count unless defined $index;
	croak "index out of bounds: [$index:$child_count]"
		if ($index < 0 || $index > $child_count);
	$self->_add_child_at_index($child, $index);
	$child->set_parent_node($self);
	return $child;
}

sub remove_child {
	my ($self, $something) = @_; # something is index or widget
	my ($child, $index) = $self->_compute_child_and_index($something);
	splice @{$self->{children}}, $index, 1;
	$child->destroy;
	return $self;
}

# get the index of a child in its parent
sub get_child_index {
	my ($self, $child) = @_;
	my $index = 0;
	my @children = @{$self->{children}};
	$index++ until $index > @children || $child eq $children[$index];
	croak 'child not in parent' unless $children[$index] eq $child;
	return $index;
}

# computes child and index from child or index
sub _compute_child_and_index {
	my ($self, $something) = @_;
	my $is_node = UNIVERSAL::isa($something, __PACKAGE__);
	my $child   = $is_node? $something: $self->get_child($something);
	my $index   = $is_node? $self->get_child_index($something): $something;
	return wantarray? ($child, $index): $child;
}

sub _add_child_at_index {
	my ($self, $child, $index) = @_;
	splice @{$self->{children}}, $index, 0, $child;
	return $child;
}

sub remove_all_children {
	my $self = shift;
	$self->remove_child(0) for 1..$self->child_count;
}

# destroying ------------------------------------------------------------------

# this is here just to keep track of destruction
# no cycles need to be broken thanx to weaken
sub destroy {
	my $self = shift;
	$_->destroy for $self->children;
	$self->set_parent_node(undef);
	$self->{is_destroyed} = 1;
}

# testing ---------------------------------------------------------------------

sub is_destroyed { shift->{is_destroyed} }

sub as_xml {
	my $self       = shift;
	my $level      = shift || 0;
	my $tag        = $self->tag;
	my $attributes = $self->attributes_as_xml;
	my $children   = $self->children_as_xml($level + 1);
	my $indent     = $self->get_indent($level);
	return
		qq[<$tag$attributes${\( $children? ">\n$children$indent</$tag": '/' )}>];
}

sub attributes_as_xml {
	my $self       = shift;
	my %attributes = $self->attributes;
	my $xml        = '';
	$xml .= qq[ $_="${\( $self->$_ )}"]
		for grep { $_ ne 'tag'} keys %attributes;
	return $xml;
}

sub children_as_xml {
	my $self   = shift;
	my $level  = shift || 0;
	my $indent = $self->get_indent($level);
	my $xml    = '';
	$xml .= qq[$indent${\( $_->as_xml($level) )}\n] for $self->children;
	return $xml;
}

sub get_indent { ' ' x (3 * pop) }

# exporting -------------------------------------------------------------------

use constant XUL_ELEMENTS => (qw(
	Window Box HBox VBox Label Button TextBox TabBox Tabs TabPanels Tab TabPanel
	Grid Columns Column Rows Row CheckBox Seperator Caption GroupBox MenuList
	MenuPopup MenuItem ListBox ListItem Splitter Deck Spacer HTML_Pre HTML_H1
	HTML_H2 HTML_H3 HTML_H4 HTML_A HTML_Div ColorPicker Description Image
	ListCols ListCol ListHeader ListHead Stack RadioGroup Radio Grippy
	ProgressMeter ArrowScrollBox ToolBox ToolBar ToolBarSeparator ToolBarButton
	MenuBar Menu MenuSeparator StatusBarPanel StatusBar
));

# export factory methods for each xul element type, xul element constants, and
# listenable aspect add/remove listener, also custom widgets, but we dont know
# about these until import time
our %EXPORT  = (
	(map { my $name = $_; (
		$name => sub { my $scalar_context = __PACKAGE__->new(tag => $name, @_) }
	) } XUL_ELEMENTS),
	(map { $_ => $_ }
		(@XUL::Node::Constants::EXPORT, qw(add_listener remove_listener))
	),
);

our @EXPORT = keys %EXPORT;

sub import {
	my $class   = shift;
	my $package = caller();
	my @widgets = @_;
	import_item($_ => $EXPORT{$_}) for @EXPORT;
	# import custom widgets
	import_widgets($package, @widgets);
	
}

sub import_widgets {
	my ($package, @widgets) = @_;
	import_widget($package, $_) for @widgets;
}

sub import_widget {
	my ($package, $widget_class) = @_;
	no strict 'refs';
	local $_;
	use_widget($widget_class) unless UNIVERSAL::can($widget_class, 'import');
	my $name = $widget_class->can('my_name')?
		$widget_class->my_name:
		get_widget_name($widget_class);
	*{"${package}::$name"} =
		sub { my $scalar_context = $widget_class->new(@_) };
	$Widget_Keys{$widget_class} = {map {$_ => 1} $widget_class->my_keys};
}

sub import_item {
	my ($name, $func) = @_;
	my $package = caller(1);
	no strict 'refs';
	*{"${package}::$name"} = ref $func eq 'CODE'? $func: *{"$func"};
}

sub use_widget {
	my $package = pop;
	eval "use $package";
	croak "cannot use widget package [$package]: $@" if $@;
}

1;

=head1 NAME

XUL-Node - server-side XUL for Perl

=head1 SYNOPSIS

  use XUL::Node;

  # creating
  $window = Window(                             # window with a header,
     HTML_H1(textNode => 'a heading'),          # a label, and a button
     $label = Label(FILL, value => 'a label'),
     Button(label => 'a button'),
  );

  # attributes
  $label->value('a value');
  $label->style('color:red');
  print $label->flex;

  # compositing
  print $window->child_count;                   # prints 3: H1, label, button
  $window->add_child(Label(value =>'foo'));     # add label to thw window
  $window->add_child(Label(value => 'bar'), 0); # add at an index, 0 is top
  $button = $window->get_child(3);              # navigate down the widget tree
  print $button->get_parent->child_count;       # naviate up, prints 6
  $window->remove_child(0);                     # remove child at index
  $foo_label = $window->get_child(3);
  $window->remove_child($foo_label);            # remove child
  

  # events
  $button = $window->add_child
  	(Button(Click => sub { $label->value('clicked!') }));
  my $sub = sub { $label->value('clicked!') }
  add_listener $button, Click => $sub;          # add several event listeners
  remove_listener $button, Click => $sub;
  $window->add_child(MenuList(
     MenuPopup(map { MenuItem(label => "item #$_", ) } 1..10),
     Select => sub { $label->value(shift->selectedIndex) },
  ));

  # destroying
  $window->remove_child($button);               # remove child widget
  $window->remove_child(1);                     # remove child by index

=head1 DESCRIPTION

XUL-Node is a rich user interface framework for server-based Perl
applications. It includes a server, a UI framework, and a Javascript XUL
client for the Firefox web browser. Perl applications run inside a POE
server, and are displayed in a remote web browser.

The goal is to provide Perl developers with the well known XUL/Javascript
development model, but with two small differences:

=over 4

=item Make it Perl friendly

Not one line of Javascript required. Be as Perlish as possible.

=item Make it Remote

Allow users to run the application on remote servers. Client
requirements: Firefox. Server requirements: Perl.

=back

XUL-Node works by splitting each widget into two: a server half, and a
client half. The server half sends DOM manipulation commands, and the
client half sends DOM events. A small Javascript client library takes
care of the communications.

The result is an application with a rich user interface, running in
Firefox with no special security permissions, built in 100% pure Perl.

=head1 DEVELOPER GUIDE

Programming in XUL-Node feels very much like working in a desktop UI
framework such as PerlTk or WxPerl. You create widgets, arrange them in a
composition tree, configure their attributes, and listen to their events.

Web development related concerns are pushed from user code into the
framework- no need to worry about HTTP, parameter processing, saving
state, and all those other things that make it so hard to develop a
high-quality web application.

=head2 Welcome to XUL

XUL is an XML-based User interface Language. XUL-Node exposes XUL to the
Perl developer. You need to know the XUL bindings to use XUL-Node.
Fortunately, these can be learned in minutes. For a XUL reference, see
XUL Planet (L<http://www.xulplanet.com/>).

=head2 Hello World

We start with the customary Hello World:

  package XUL::Node::Application::HelloWorld;
  use XUL::Node;
  use base 'XUL::Node::Application';

  sub start { Window Label value => 'Hello World!' }

  1;

This is an application class. It creates a window with a label as its
only child. The label value is set to 'Hello World!'.

=head2 Applications

To create an application:

=over 4

=item *

Subclass L<XUL::Node::Application>.

=item *

Name your application package under C<XUL::Node::Application>. E.g.
C<XUL::Node::Application::MyApp>.

=item *

Implement one template method, C<start()>.

=back

In C<start()> you must create at least one window, if you want the UI to
show. The method is run once, when a session begins. This is where you
create widgets and add event listeners.

XUL-Node comes with 14 example applications in the
C<XUL::Node::Application> namespace.

Applications are launched by starting the server and pointing Firefox at
a URL. You start the server with the command:

  xul-node-server

Run it with the option C<--help> for usage info. This will start a
XUL-Node server on the default server root and port you defined when
running the C<Makefile.PL> script.

You can then run the application from Firefox, by constructing a URL so:

  http://SERVER:PORT/start.xul?APPLICATION#DEBUG

  SERVER       server name
  PORT         HTTP port configured when starting server
  APPLICATION  application name, if none given, runs HelloWorld
  DEBUG        0 or 1, default is 0, turn on client debug info

The application name is the last part of its package name. So the package
C<XUL::Node::Application::PeriodicTable> can be run using the application
name C<PeriodicTable>. All applications must exist under C<@INC>, under
the namespace C<XUL::Node::Application>.

So for example, to run the splitter example on a locally installed server,
you would browse to:

  http://localhost:8077/start.xul?SplitterExample#1

The installation also creates an index page, providing links to all
examples. By default it will be available at:

  http://localhost:8077

=head2 Widgets

To create a UI, you will want your C<start()> method to create a window
with some widgets in it. Widgets are created by calling a function named
after their tag:

  $button = Button;                           # orphan button with no label
  $widget = XUL::Node->new(tag_name => $tag); # another orphan, more verbose

After creating a widget, you must add it to a parent. The widget will
show when there is a containment path between it and a window. There are
two ways to parent widgets:

  $parent->add_child($button);                # using add_child
  Box(style => 'color:red', Button);          # add in parent constructor

Widgets have attributes. These can be set in the constructor, or via
get/set methods:

  $button->label('a button');
  print $button->label;                       # prints 'a button'

Widget can be removed from the document by calling the C<remove_child()>
method on their parent. The only parameter is a widget, or an index of a
widget. For example:

  $box->remove_child($button);
  $box->remove_child(0);

You can configure all attributes, event handlers, and children of a
widget, in the constructor. There are also constants for commonly used
attributes. This allows for some nice code:

  Window(SIZE_TO_CONTENT,
     Grid(FLEX,
        Columns(Column(FLEX), Column(FLEX)),
        Rows(
           Row(
              Button(label => "cell 1"),
              Button(label => "cell 2"),
           ),
           Row(
              Button(label => "cell 3"),
              Button(label => "cell 4"),
           ),
        ),
     ),
  );

Check out the XUL references (L<http://www.xulplanet.com>) for
an explanation of available widget attributes.

=head2 Events

Widgets receive events from their client halves, and pass them on to
attached listeners in the application. You add a listener to a widget
so:

  # listening to existing widget
  add_listener $button, Click => sub { print 'clicked!' };

  # listening to widget in constructor
  TextBox(Change => sub { print shift->value });

You add events by providing an event name and a listener. Possible event
names are C<Click>, C<Change>, C<Select>, and C<Pick>. Different widgets
fire different events. These are listed in L<XUL::Node::Event>.

Widgets can have any number of registered listeners. They can be removed
using C<remove_listener>. A listener can be a C<CODE> ref, or a method on
some object.

  # call MyListener::handle_event_Click as a method
  add_listener $button, Click => MyListener->new; 

  # call MyListener::my_handler as a method
  add_listener $button, Click => [my_handler => MyListener->new];

See L<Aspect::Library::Listenable|ADDING AND REMOVING LISTENERS> for more
information about writing listeners.

Listener receive a single argument: the event object. You can query this
object for information about the event: C<name>, C<source>, and depending
on the event type: C<checked>, C<value>, C<color>, and C<selectedIndex>.

See L<XUL::Node::Server::Event> for more information about event types.

Here is an example of listening to the C<Select> event of a list box:

  Window(
     VBox(FILL,
        $label = Label(value => 'select item from list'),
        ListBox(FILL, selectedIndex => 2,
           (map { ListItem(label => "item #$_") } 1..10),
           Select => sub {
              $label->value
                 ("selected item #${\( shift->selectedIndex + 1 )}");
           },
        ),
     ),
  );

=head2 Images and Other Resources

When XUL-Node is installed, a server root directory is created at a
user-specified location. By default it is C<C:\Perl\xul-node> on
C<Win32>, and C</usr/local/xul-node> elsewhere.

You place images and other resources you want to make available via HTTP
under the directory:

  SERVER_ROOT/xul

The example images are installed under:

  SERVER_ROOT/xul/images

You can access them from your code by pointing at the file:

  Button(ORIENT_VERTICAL,
     label => 'a button',
     image => 'images/button_image.png',
  );

Any format Firefox supports should work.

=head2 XUL-Node API vs. the Javascript XUL API

The XUL-Node API is different in the following ways:

=over 4

=item *

Booleans are Perl booleans.

=item *

There is no difference between attributes, properties, and methods. They
are all attributes.

=item *

There exist constants for common attribute key/value pairs. See
C<XUL::Node::Constants>.

=item *

Works around Firefox XUL bugs.

=back

=head1 INTERNALS

XUL-Node acts as a very thin layer between your Perl application, and the
Firefox web browser. All it does is expose the XUL API in Perl, and
provide the server so you can actually use it. Thus it is very small.

It does this using the Half Object pattern
(L<http://c2.com/cgi/wiki?HalfObjectPlusProtocol>). XUL elements have a
client half (the DOM element in the document), but also a server half,
represented by a C<XUL::Node> object. User code calls methods on the
server half, and listens for events. The server half forwards them to the
client, which runs them on the displayed DOM document.

=head2 The Wire Protocol

Communications is done through HTTP POST, with an XML message body in the
request describing the event, and a response composed of a list of DOM
manipulation commands.

Here is a sample request, showing a boot request for the C<HelloWorld>
application:

  <xul>
     <type>boot</type>
     <name>HelloWorld</name>
  </xul>

Here is a request describing a selection event in a C<MenuList>:

  <xul>
     <type>event</type>
     <name>Select</name>
     <source>E2</source>
     <session>ociZa4lBESk+9ptkVfr5qw</session>
     <selectedIndex>3</selectedIndex>
  </xul>

Here is the response to the C<HelloWorld> boot request. The 1st line of
the boot response is the session ID created by the server.

  Li6iZ6soj4JqwnkDUmmXsw
  E2.new(window, 0)
  E2.set(sizeToContent, 1)
  E1.new(label, E2)
  E1.set(value, Hello World!)

Each command in a response is built of the widget ID, the
attribute/property/method name, and an argument list.

=head2 The Server

The server uses C<POE::Component::HTTPServer>. It configures a handler
that forwards requests to the session manager. The session manager
creates or retrieves the session object, and gives it the request. The
session runs user code, and collects any changes done by user code to the
DOM tree. These are sent to the client.

Aspects are used by C<XUL::Node::ChangeManager> to listen to DOM state
changes, and record them for passing on to the client.

The C<XUL::Node::EventManager> keeps a weak list of all widgets, so they
can be forwarded events, as they arrive from the client.

A time-to-live timer is run using C<POE>, so that sessions will expire
after 10 minutes of inactivity.

=head2 The Client

The client is a small Javascript library which handles:

=over 4

=item *

Client/server communications, using Firefox C<XMLHTTPRequest>.

=item *

Running commands as they are received from the server.

=item *

Unifying attributes/properties/methods, so they all seem like attributes
to the XUL-Node developer.

=item *

Work-arounds for Firefox bugs and inconsistencies.

=back

=head1 SUPPORTED TAGS

These XUL tags have been tested and are known to work.

=over 4

=item containers

Window, Box, HBox, VBox, GroupBox, Grid, Columns, Column, Rows, Row,
Deck, Stack, ArrowScrollBox

=item labels

Label, Image, Caption, Description

=item Simple Controls

Button, TextBox, CheckBox, Seperator, Caption, RadioGroup, Radio,
ProgressMeter, ColorPicker

=item lists

ListBox, ListCols, ListCol, ListHeader, ListHead, ListItem

=item notebook parts

TabBox, Tabs, TabPanels, Tab, TabPanel

=item menus, status bars and toolbars

MenuBar, Menu, MenuSeparator, MenuList, MenuPopup, MenuItem, ToolBox,
ToolBar, ToolBarButton, ToolBarSeperator, StatusBarPanel, StatusBar,
Grippy

=item layout

Spacer, Splitter

=item HTML elements

HTML_Pre, HTML_A, HTML_Div, HTML_H1, HTML_H2, HTML_H3, HTML_H4

=back

=head1 LIMITATIONS

=over 4

=item *

Some widgets are not supported yet: tree, popup, and multiple windows

=item *

Some widget features are not supported yet:

  * multiple selections
  * color picker will not fire events if type is set to button

=back

See the TODO file included in the distribution for more information.

=head1 SEE ALSO

L<XUL::Node::Event> presents the list of all possible events.

L<http://www.xulplanet.com> has a good XUL reference.

L<http://www.mozilla.org/products/firefox/> is the browser home page.

=head1 BUGS

None known so far. If you find any bugs or oddities, please do inform the
author.

=head1 AUTHOR

Ran Eilam <eilara@cpan.org>

=head1 COPYRIGHT

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
