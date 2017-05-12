package XUL::Node::Application;

use strict;
use warnings;
use Carp;

use constant {
	DEFAULT_NAME => 'HelloWorld',
	EXEC_PACKAGE => 'XUL::Node::Application',
};

sub create {
	my $self = shift;
	my $package = application_to_package(shift);
	runtime_use($package);
	return $package->new;
}

sub new { bless {}, shift }

sub application_to_package {
	my $name = pop || DEFAULT_NAME;
	# want to remove the following line? say hello to one big security hole
	croak "illegal name: [$name]" unless $name =~ /^[A-Z](?:\w*::)*\w+$/;
	$name = EXEC_PACKAGE. "::$name";
}

# private ---------------------------------------------------------------------

sub runtime_use {
	my $package = pop;
	eval "use $package";
	croak "cannot use: [$package]: $@" if $@;
}

# template methods ------------------------------------------------------------

sub start { croak "must be implemented in subclass" }

1;

=head1 NAME

XUL::Node::Application - base class for XUL-Node applications

=head1 SYNOPSYS

  # subclassing to create your own application
  package XUL::Node::Application::MyApp;
  use base 'XUL::Node::Application';
  sub start { Window(Label(value => 'Welcome to MyApp')) }

  # running the application from some handler in some server
  use XUL::Node::Application;
  XUL::Node::Application->create('MyApp')->start;

  # Firefox URL
  http://SERVER:PORT/start.xul?MyApp

=head1 DESCRIPTION

To create a XUL-Node application, subclass from this class and provide
one template method: C<start()>. It will be called when the application
is started.

C<XUL::Node::Server::Session> starts applications by calling the class method
C<create($application_name)>, then creating a closure which calls C<start()>
on the application object. The closure is run by the change manager, which
collects any changes to nodes so they can be passed to the client.

=cut
