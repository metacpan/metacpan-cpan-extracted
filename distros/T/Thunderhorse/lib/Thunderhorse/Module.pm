package Thunderhorse::Module;
$Thunderhorse::Module::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

extends 'Gears::Component';

has extended 'app' => (
	handles => [
		qw(
			add_method
			add_middleware
			add_hook
		)
	],
);

has param 'config' => (
	isa => HashRef,
);

__END__

=head1 NAME

Thunderhorse::Module - Base class for Thunderhorse modules

=head1 SYNOPSIS

	package MyApp::Module::Custom;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Thunderhorse::Module';

	sub build ($self)
	{
		# Add a method to controllers
		$self->add_method(
			controller => custom_action => sub ($controller, @args) {
				# your custom logic here
				return $controller;
			}
		);

		# Add a hook
		$self->add_hook(
			error => sub ($controller, $ctx, $error) {
				# handle errors
			}
		);

		# Add middleware
		$self->add_middleware($middleware_instance);
	}

=head1 DESCRIPTION

Thunderhorse::Module is the base class for creating reusable modules that
extend application functionality. Modules are loaded via configuration and can
perform actions like adding methods to controllers, registering hooks, and
adding middleware to the application.

Modules are automatically loaded during application startup when configured in
the C<modules> section of application configuration. Each module receives its
configuration hash as the L</config> attribute.

To create a custom module, extend this class and implement the
L<Gears::Component/build> method. Use the provided methods (L</add_method>,
L</add_middleware>, L</add_hook>) to extend application functionality.

=head1 INTERFACE

Inherits all interface from L<Gears::Component>, and adds the
interface documented below.

=head2 Attributes

=head3 config

Configuration hash reference containing module-specific configuration values.
This is populated from the application's configuration file when the module is
loaded.

I<Required in the constructor>

=head2 Methods

=head3 add_method

Delegated to L<Thunderhorse::App/add_method>.

=head3 add_middleware

Delegated to L<Thunderhorse::App/add_middleware>.

=head3 add_hook

Delegated to L<Thunderhorse::App/add_hook>.

=head1 SEE ALSO

L<Gears::Component>

