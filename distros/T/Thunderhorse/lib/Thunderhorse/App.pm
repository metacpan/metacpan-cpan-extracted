package Thunderhorse::App;
$Thunderhorse::App::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use Thunderhorse qw(pagi_loop);
use Thunderhorse::Config;
use Gears qw(load_component get_component_name);
use Thunderhorse::Context;
use Thunderhorse::Router;
use Thunderhorse::Controller;
use Thunderhorse::AppController;
use Path::Tiny;

use HTTP::Status qw(status_message);
use IO::Async::Loop;
use Future::AsyncAwait;
use PAGI::Utils qw(handle_lifespan);
use FindBin;

extends 'Gears::App';

has param 'path' => (
	coerce => (InstanceOf ['Path::Tiny'])
		->plus_coercions(Str, q{ Path::Tiny::path($_) }),
	default => sub { $FindBin::Bin },
);

has param 'env' => (
	isa => Enum ['production', 'development', 'test'],
	default => sub { $ENV{PAGI_ENV} // 'production' },
);

has param 'initial_config' => (
	isa => Str | HashRef,
	default => sub { {} },
);

has field 'loop' => (
	isa => InstanceOf ['IO::Async::Loop'],
	default => sub { IO::Async::Loop->new },
);

# the base app controller
has field 'controller' => (
	isa => InstanceOf ['Thunderhorse::Controller'],
	lazy => '_build_app_controller',
);

has extended 'router' => (
	reader => '_router',
	isa => InstanceOf ['Thunderhorse::Router'],
	default => sub { Thunderhorse::Router->new },
);

has extended 'config' => (
	builder => 1,
);

has field 'modules' => (
	isa => ArrayRef,
	default => sub { [] },
);

has field 'extra_methods' => (
	isa => HashRef,
	default => sub {
		{
			controller => {},
		}
	},
);

has field 'extra_middleware' => (
	isa => ArrayRef,
	default => sub { [] },
);

has field 'extra_hooks' => (
	isa => HashRef,
	default => sub {
		{
			startup => [],
			shutdown => [],
			error => [],
		}
	},
);

#############################
### BOOTSTRAPPING SECTION ###
#############################

sub BUILD ($self, $)
{
	$self->late_configure;
}

sub _build_config ($self)
{
	my $conf = Thunderhorse::Config->new;
	foreach my $reader ($conf->readers->@*) {
		next unless $reader isa 'Gears::Config::Reader::PerlScript';

		# make app available from .pl config files
		$reader->declared_vars->%* = (
			$reader->declared_vars->%*,
			app => $self,
		);
	}

	return $conf;
}

sub _build_app_controller ($self)
{
	return $self->_build_controller('Thunderhorse::AppController');
}

sub _build_context ($self, @pagi)
{
	return Thunderhorse::Context->new(
		app => $self,
		pagi => \@pagi,
	);
}

sub is_production ($self)
{
	return $self->env eq 'production';
}

sub router ($self)
{
	my $router = $self->_router;
	$router->set_controller($self->controller);
	return $router;
}

sub configure ($self)
{
	my $config = $self->config;

	my $preconf = $self->initial_config;
	if (!ref $preconf) {
		$config->load_from_files($self->path->child($preconf), $self->env);
	}
	else {
		$config->add(var => $preconf);
	}

	# TODO: module dependencies and ordering
	my %modules = $config->get('modules', {})->%*;
	foreach my $module_name (sort keys %modules) {
		$self->load_module($module_name, $modules{$module_name});
	}
}

sub late_configure ($self)
{
	foreach my $controller ($self->config->get('controllers', [])->@*) {
		$self->load_controller($controller);
	}
}

sub load_module ($self, $module_class, $args = {})
{
	my $module = load_component(get_component_name($module_class, 'Thunderhorse::Module'))
		->new(app => $self, config => $args);

	push $self->modules->@*, $module;
	return $self;
}

###################################
### PAGI IMPLEMENTATION SECTION ###
###################################

async sub pagi ($self, $scope, $receive, $send)
{
	my $scope_type = $scope->{type};

	return await handle_lifespan(
		$scope, $receive, $send,
		startup => sub { $self->_on_startup(@_) },
		shutdown => sub { $self->_on_shutdown(@_) },
	) if $scope_type eq 'lifespan';

	# TODO: is this needed?
	die 'Unsupported scope type'
		unless $scope_type =~ m/^(http|sse|websocket)$/;

	# copy scope since we are modifying it
	$scope = {$scope->%*};
	my $ctx = $scope->{thunderhorse} = $self->_build_context($scope, $receive, $send);

	# query router for matches
	my $req = $ctx->req;
	my $matches = $self->_router->match(
		$req->path,
		(lc join '.', grep { defined } $scope_type, $req->method),
	);

	# run location handlers' nested structure
	await pagi_loop($ctx, $matches->@*);

	# 404 is possible even if we had matches, as long as no handler consumed
	# the context
	if (!$ctx->is_consumed) {
		await $self->render_error(undef, $ctx, 404);
	}

	return;
}

sub run ($self)
{
	# do not turn into PAGI application if run by a thunderhorse script
	return $self if $ENV{THUNDERHORSE_SCRIPT};

	my $pagi = sub (@args) {
		return $self->pagi(@args);
	};

	foreach my $mw ($self->extra_middleware->@*) {
		if (ref $mw eq 'CODE') {
			$pagi = $mw->($pagi);
		}
		elsif ($mw isa 'PAGI::Middleware') {
			$pagi = $mw->wrap($pagi);
		}
		else {
			Gears::X::Thunderhorse->raise('bad middleware, not CODE or PAGI::Middleware');
		}
	}

	return $pagi;
}

async sub render_error ($self, $controller, $ctx, $code, $message = undef)
{
	$message = defined $message && !$self->is_production ? $message : status_message($code);
	await $ctx->res->status($code)->text($message);
}

async sub render_response ($self, $controller, $ctx, $result)
{
	await $ctx->res
		->status_try(200)
		->content_type_try('text/html')
		->send($result);
}

#########################
### EXTENSION METHODS ###
#########################

sub add_method ($self, $for, $name, $code)
{
	my $area = $self->extra_methods->{$for};
	Gears::X::Thunderhorse->raise("bad area '$for' for symbol '$name'")
		unless defined $area;

	Gears::X::Thunderhorse->raise("symbol '$name' already exists in area '$for'")
		if exists $area->{$name};

	$area->{$name} = $code;
	return $self;
}

sub add_middleware ($self, $mw)
{
	push $self->extra_middleware->@*, $mw;
	return $self;
}

sub add_hook ($self, $hook, $handler)
{
	push $self->extra_hooks->{$hook}->@*, $handler;
	return $self;
}

#####################
### HOOKS SECTION ###
#####################

sub _fire_hooks ($self, $hook, @args)
{
	foreach my $handler ($self->extra_hooks->{$hook}->@*) {
		$handler->(@args);
	}
}

sub _on_startup ($self, @args)
{
	$self->_fire_hooks(startup => @args);
	return $self->on_startup(@args);
}

async sub on_startup ($self, $state)
{
}

sub _on_shutdown ($self, @args)
{
	$self->_fire_hooks(shutdown => @args);
	return $self->on_shutdown(@args);
}

async sub on_shutdown ($self, $state)
{
}

async sub on_error ($self, $controller, $ctx, $error)
{
	my $code = $error isa 'Gears::X::HTTP' ? $error->code : 500;
	await +($controller // $self->controller)->render_error($ctx, $code, $error);
}

__END__

=head1 NAME

Thunderhorse::App - Base application class for Thunderhorse

=head1 SYNOPSIS

	package MyApp;

	use v5.40;
	use Mooish::Base;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->router->add('/hello' => { to => 'greet' });
	}

	sub greet ($self, $ctx)
	{
		return "Hello, World!";
	}

	MyApp->new->run;

=head1 DESCRIPTION

Thunderhorse::App is the base application class for Thunderhorse
applications. It extends L<Gears::App> and provides all core functionality
needed to build PAGI web applications, including routing, configuration
management, controller loading, and request handling.

Every Thunderhorse application must be a subclass of this class. Method
L<Gears::Component/build> can be overridden to bootstrap the application.
Similar method L<Gears::Component/configure> is called before C<build>, but is
used internally by the application, so the C<SUPER> version must be called if
it is overridden. Method C<late_configure> works like C<configure> but is
executed B<after> C<build>. This must also call the C<SUPER> version if
overridden, since it is used to load controllers from configuration.

=head1 INTERFACE

Inherits all interface from L<Gears::App> and L<Gears::Component>, and adds the
interface documented below.

=head2 Attributes

=head3 path

Application's base path. Defaults to the path to application starter script,
like C<app.pl>.

I<Available in the constructor>

=head3 env

Application environment. Can be C<production>, C<development>, or C<test>.
Defaults to C<PAGI_ENV> environmental variable, or C<production>.

I<Available in the constructor>

=head3 initial_config

Initial configuration, either a hash reference or a string path to
configuration directory. Defaults to an empty hash.

The configuration directory path will be appended to L</path> before reading
the configuration.

I<Available in the constructor>

=head3 loop

L<IO::Async::Loop> instance for quick access.

I<Not available in constructor>

=head3 controller

Base application controller instance.

I<Not available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

Standard Mooish constructor. Consult L</Attributes> section for available
constructor arguments.

=head3 run

	$pagi_app = $app->run()

Returns a PAGI application coderef ready for C<pagi-server>. If called from a
L<thunderhorse> script (C<THUNDERHORSE_SCRIPT> environmental value is set),
returns the app object instead.

=head3 pagi

	$self->pagi($scope, $receive, $send)

Main PAGI application handler. This method is used in L</run>, so there is no
need to call it manually.

=head3 load_module

	$self = $self->load_module($name, $config = {})

Loads and initializes a Thunderhorse module. Module name is automatically
prefixed with C<Thunderhorse::Module::> unless it starts with C<^>.

=head3 load_controller

	$self = $self->load_controller($name)

Loads a controller class and registers its routes. Controller name is
automatically prefixed with application namespace unless it starts with C<^>.

=head3 add_method

	$self = $self->add_method($for, $name, $code)

Adds a method with a C<$name> dynamically. C<$for> specifies the target area.
Used by modules to extend functionality.

Allowed values for C<$for> are: C<controller>

=head3 add_middleware

	$self = $self->add_middleware($middleware)

Wraps the entire application in PAGI middleware. C<$middleware> can be a
coderef or a L<PAGI::Middleware> instance.

=head3 add_hook

	$self = $self->add_hook($hook, $handler)

Registers a hook handler for application events.

Allowed values for C<$hook> are: C<startup>, C<shutdown>, C<error>.

=head3 is_production

	$bool = $self->is_production()

Returns true if the application is running in production environment.

=head3 render_error

	$self->render_error($controller, $ctx, $code, $message = undef)

Renders an error response with the given HTTP status code. Can be overridden to
customize error pages.

=head3 render_response

	$self->render_response($controller, $ctx, $result)

Renders a response from C<$result>, which contains what was returned by the
handler. Can be overridden to change the default behavior of rendering result
as HTML.

=head3 on_startup

	async sub on_startup ($self, $state) { ... }

Lifespan hook called when the worker process starts. Can be overridden to
perform initialization tasks. C<$state> is a PAGI persistent hash reference
with state values.

=head3 on_shutdown

	async sub on_shutdown ($self, $state) { ... }

Lifespan hook called when the worker process shuts down. Can be overridden to
perform cleanup tasks. C<$state> is a PAGI persistent hash reference with state
values.

=head3 on_error

	async sub on_error ($self, $controller, $ctx, $error) { ... }

Error hook called when an exception occurs during request processing. Can be
overridden to customize error handling. Overriding it on application level will
change the default handler for all controllers.

=head1 SEE ALSO

L<Thunderhorse>, L<Gears::App>, L<Thunderhorse::Controller>

