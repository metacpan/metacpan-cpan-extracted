package Thunderhorse;
$Thunderhorse::VERSION = '0.100';
##################################
# ~~~~~~~~~~~~ Ride ~~~~~~~~~~~~ #
# ~~~~~~~~~~~~ Ride ~~~~~~~~~~~~ #
# ~~~~~~~~~~~~ Ride ~~~~~~~~~~~~ #
# ~~~~~~~~~~~~ Ride ~~~~~~~~~~~~ #
# ~~~~~~~~ Thunderhorse ~~~~~~~~ #
# ~~~~~~~~ Thunderhorse ~~~~~~~~ #
# ~~~~~~~~ Thunderhorse ~~~~~~~~ #
# ~~~~~~~~ Thunderhorse ~~~~~~~~ #
# ~~~~~~~~~~~ Revenge ~~~~~~~~~~ #
# ~~~~~~~~~~~ Revenge ~~~~~~~~~~ #
# ~~~~~~~~~~~ Revenge ~~~~~~~~~~ #
##################################

use v5.40;

use Exporter qw(import);
use Future::AsyncAwait;

use Gears::X::Thunderhorse;

our @EXPORT_OK = qw(
	pagi_loop
	adapt_pagi
	build_handler
);

async sub pagi_loop ($ctx, @matches)
{
	my @pagi = $ctx->pagi->@*;

	foreach my $match (@matches) {
		# is this a bridge? If yes, take first element (the bridge location).
		# It is guaranteed to be a match, not an array
		my $loc = (ref $match eq 'ARRAY' ? $match->[0] : $match)->location;

		# $ctx->match may be an array if this is a bridge. Location handler
		# takes care of that
		$ctx->set_match($match);

		# execute location handler (PAGI application)
		await $loc->pagi_app->(@pagi);
		last if $ctx->is_consumed;
	}
}

sub adapt_pagi ($destination)
{
	# no need to async here because we don't await - destination must return a promise anyway
	# TODO: think of a proper way to enforce last placeholder being at the very end of the url
	return sub ($scope, @args) {
		Gears::X::Thunderhorse->raise('bad PAGI execution chain, not a Thunderhorse app')
			unless my $ctx = $scope->{thunderhorse};

		# consume this context eagerly to keep further matches from firing
		$ctx->consume;

		# take last matched element as the path
		# pagi apps can't be bridges, so don't check if $ctx->match is an array
		my $path = $ctx->match->matched->[-1] // '';
		my $trailing_slash = $scope->{path} =~ m{/$} ? '/' : '';
		$path =~ s{^/?}{/};
		$path =~ s{/?$}{$trailing_slash};

		# modify the scope for the app
		$scope = {$scope->%*};
		$scope->{root_path} = ($scope->{root_path} . $scope->{path}) =~ s{\Q$path\E$}{}r;
		$scope->{path} = $path;

		return $destination->($scope, @args);
	}
}

sub build_handler ($controller, $destination)
{
	return async sub ($scope, $receive, $send) {
		Gears::X::Thunderhorse->raise('bad PAGI execution chain, not a Thunderhorse app')
			unless my $ctx = $scope->{thunderhorse};

		$ctx->update($scope, $receive, $send);

		my $match = $ctx->match;
		my $bridge = ref $match eq 'ARRAY';

		# this location may be unimplemented when destination is undefined, but
		# a full handler should be built anyway. Unimplemented destinations
		# should still be wrappable in middleware.
		if (defined $destination) {
			try {
				my $facade = $controller->make_facade($ctx);
				my $result = $destination->($controller, $facade, ($bridge ? $match->[0] : $match)->matched->@*);
				$result = await $result
					if $result isa 'Future';

				if (!$ctx->is_consumed) {
					if (defined $result) {
						await $controller->render_response($ctx, $result);
					}
					else {
						weaken $facade;
						Gears::X::Thunderhorse->raise("context hasn't been given up - forgot await?")
							if defined $facade;
					}
				}
			}
			catch ($ex) {
				await $controller->_on_error($ctx, $ex);
			}
		}

		# if this is a bridge and bridge did not render, it means we are
		# free to go deeper. Avoid first match, as it was handled already
		# above
		if ($bridge && !$ctx->is_consumed) {
			await pagi_loop($ctx, $match->@[1 .. $match->$#*]);
		}
	};
}

__END__

=head1 NAME

Thunderhorse - A no-compromises brutally-good web framework

=head1 SYNOPSIS

First ...

	# app.pl
	use v5.40;

	package MyApp;
	use Mooish::Base;
	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->router->add('/hello/:name', { to => 'greet' });
	}

	sub greet ($self, $ctx, $name)
	{
		return "Hello, $name!";
	}

	MyApp->new->run;

Then ...

	> pagi-server app.pl

=head1 DESCRIPTION

Thunderhorse is a web framework which supports L<PAGI> protocol natively. It
builds around tools delivered by PAGI to achieve a simple, capable, and
async-ready framework. The same ideas were used to build L<Kelp>, which was
based on L<PSGI> and L<Plack>. Thunderhorse is the spiritual successor of Kelp
and carries its legacy into the world of real-time web.

Thunderhorse was designed to be light, extensible and reusable. It can
seamlessly integrate with PAGI apps or middlewares, which makes it very easy to
build a web server from available components. It has a very powerful and
cache-friendly router. It is built on top of L<Gears>, which means its parts
are very hackable and easy to reuse in other projects.

Unlike other frameworks, Thunderhorse neither reinvents all of its wheels, nor
depends on numerous CPAN dependencies to work. It leverages a moderate,
hand-picked set of distributions to deliver concise, performant and
well-organized system. It is also based on perl 5.40 and uses modern syntax
features in its core, which allows it to further reduce the set of required
dependencies and keep the core small.

=head2 Stability notice

B<Thunderhorse is currently in a beta phase> and will stabilize on version
C<1.000>. Until then, no stability promises are made and everything is up for
changing.

Starting with version C<1.000>, all documented interface will only be a subject
to breaking backward compatibility after a B<two year deprecation period>,
starting when the deprecation is announced in L<Thunderhorse::Compatibility>.
The only exception to that rule is when breaking compatibility is required to
fix a severe security issue. Note that this policy does not apply to changes in
L<PAGI> itself.

=head2 Thunderhorse and PAGI

Thunderhorse is a layer built around L<PAGI> spec, so it requires at least some
PAGI knowledge to use effectively. L<PAGI::Tutorial> may be a good starting
point, but it contains more than required to build functional Thunderhorse
applications. Here's the bare minimum to get you started:

=over

=item

Each PAGI app is a plain C<async sub>, while Thunderhorse app is a blessed
object. Thunderhorse apps have a C<run> method, which returns a PAGI app when
called. This app is an entry point for all web requests.

=item

PAGI webapps need a bootstrapping script, like C<app.pl>. This script prepares
the app for the server. App obtained from C<run> method must be returned by the
script. This is usually achieved by putting C<< $app->run >> method call as
the very last operation in the file.

=item

Scripts must be called using C<pagi-server> (or other PAGI-specific software).
Running the script using C<perl> does nothing, as the application cannot run
itself - it will be built, but it will not set up a webserver.

=back

=head2 The thunderhorse script

The C<thunderhorse> script is a command-line utility for managing Thunderhorse
projects. It can be used to build new Thunderhorse projects or to inspect
existing ones.

The script can generate new applications from examples included with
Thunderhorse distribution (in the C<ex> directory):

	# simple application
	thunderhorse --generate hello-world My::App

	# advanced application
	thunderhorse --generate full-app My::App

This creates a complete application structure with all necessary files in the
current directory. Simple one-file examples like C<hello-world>, C<websocket>
or C<sse> can be useful for quick prototyping. C<full-app> is a full
application ready for serious development with the proposed standard directory
structure:

=over

=item * C<app.pl> - application bootstrap script

=item * C<lib/> - Perl code

=item * C<conf/> - configuration files

=item * C<views/> - HTML templates

=item * C<t/> - tests

=back

After generating, the script can be used to inspect projects:

=over

=item * showing current configuration

The following command gathers and dumps system configuration:

	thunderhorse --show-config app.pl

By default, production configuration is shown. Set C<PAGI_ENV> to
C<development> to show dev configuration:

	PAGI_ENV=development thunderhorse --show-config app.pl

=item * showing installed system locations

The following command gathers and dumps router locations:

	thunderhorse --show-locations app.pl

The list of locations will be sorted in the order in which they are matched.
Nested arrays in the list will be used when a bridge is encountered.

=back

Note that C<thunderhorse> script does not actually run the applications - use
C<pagi-server> for that.

=head2 The application class

Each Thunderhorse application is required to define an application class, which
is a package subclass of L<Thunderhorse::App>. The mechanism of subclassing can
be chosen at will, but docs and examples will suggest L<Mooish::Base>, which is
also what the core of Thunderhorse uses. Mooish::Base imports Moo, but
will also ensure all known performance-enhancing modules are loaded.

Most minimal Thunderhorse application (which does nothing) looks like this:

	# lib/MyApp.pm
	package MyApp;

	use v5.40;
	use Mooish::Base;

	extends 'Thunderhorse::App';

To run it, a perl file is required, which will load, instantiate and run it (as
the last expression):

	# app.pl
	use lib 'lib';
	use MyApp;

	MyApp->new->run;

C<app.pl> can now be run using C<pagi-server>, which will take the last
expression of the file and run it when requests arrive. In the above example,
all these requests will return HTTP code C<404>, since we haven't declared any
routing yet.

Of course, for the sake of quick prototyping, C<lib/MyApp.pm> can be merged
into C<app.pl>. Thunderhorse does not ship with any DSL variant for simple
apps, since writing the application is easy enough as it is. We believe
creating such DSL would only cause confusion without any measurable benefit. We
suggest to not use C<package NAME BLOCK> syntax in this scenario, since it
makes it much harder to access C<DATA> handle (which will be useful later, in
L</Template> section):

	package MyApp;

	use v5.40;
	use Mooish::Base;

	extends 'Thunderhorse::App';

	MyApp->new->run;

=head2 Routing

To make our application do anything useful, we need to obtain the router
(L<Thunderhorse::Router>) and call C<add> method on it. This is commonly done
in the C<build> method of the application, which is called automatically when
the application object is created:

	# in lib/MyApp.pm
	sub build ($self)
	{
		my $router = $self->router;

		$router->add(
			'/request/path' => {
				to => sub ($self, $ctx) {
					return 'Hello?';
				},
			}
		);
	}

The code above lets us now visit C<localhost:5000/request/path> and see text
C<Hello?> in the browser. This is called I<a routing location>, and typically
points at a subroutine or its name using C<to>, also called destination. The
code above could be rewritten to the following form, which would yield the
exact same result:

	sub build ($self)
	{
		my $router = $self->router;

		$router->add(
			'/request/path' => {
				to => 'hello', # name of a method in this controller
			}
		);
	}

	sub hello ($self, $ctx)
	{
		return 'Hello?';
	}

=head3 Destinations

Destination can be a C<sub> or C<async sub> (using L<Future::AsyncAwait>). It
accepts two base arguments: C<$self> which is the instance of the controller
(L<Thunderhorse::Controller>), and C<$ctx> which is current request's context
(L<Thunderhorse::Context>). In Thunderhorse, controllers are persistent and
shared across all requests, which is why a context object is defined.
Controllers can never hold request-specific state, because there are multiple
concurrent requests being handled at the same time due to asynchronous nature
of PAGI. If destination is C<async>, then it must C<await> all asynchronous
calls as defined by PAGI specification.

Return value of the destination sub is by default sent to the requestor as
C<text/html> with status code C<200>. This is a common and handy shortcut, but
it is equally easy to do something else. Take the following destination example:

	async sub send_custom ($self, $ctx)
	{
		await $ctx->res->text('Plaintext response');
		return 'this will not get rendered';
	}

This takes response (L<Thunderhorse::Response>) from context, and sends
plaintext manually. This action I<consumes> the context, marking it as
finished. In this case, return value of the destination is ignored. Note that
the await call on C<< ->text >> method is mandatory.

Another example:

	sub send_custom2 ($self, $ctx)
	{
		$ctx->res->status(400)->content_type('text/plain');
		return 'this is rendered as plaintext and status 400';
	}

This time, the return value of the destination is not ignored, since only
setting response metadata does not cause the context to be consumed. Status and
I<Content-Type> header will not be overridden, so the response will be sent as
plaintext. In this case, there is no need to await anything.

While not very common, a destination can be unimplemented when C<to> is
skipped. Unimplemented locations will be "stepped over" during request
handling. This may be useful in combination with bridges or PAGI middlewares,
explained later.

=head3 Placeholders

Routes can contain placeholders which match parts of the URL path and make
those parts available to the destination handler. Placeholders are specified
using sigils in the pattern:

	$router->add(
		'/user/:id' => {
			to => sub ($self, $ctx, $id) {
				return "User ID: $id";
			}
		}
	);

This location matches C</user/123> and passes C<123> as the C<$id> parameter.
Each matched placeholder is passed as additional arguments to the destination,
after C<$self> and C<$ctx>.

Thunderhorse supports four types of placeholders:

=over

=item * C<:name> - required placeholder

Matches any characters except slash. The placeholder must be present in the URL
for the route to match.

	# matches /user/123 but not /user/ or /user
	'/user/:id'

=item * C<?name> - optional placeholder

Matches any characters except slash. If the placeholder is not present, it will
be passed as C<undef> to the destination. If it follows a slash with no curly
braces, that slash becomes optional as well.

	# matches both /post/my-slug and /post
	# in second case, $slug will be undef
	'/post/?slug'

=item * C<*name> - wildcard placeholder

Matches any characters including slashes. Always required.

	# matches /files/path/to/file.txt
	# $path will be 'path/to/file.txt'
	'/files/*path'

=item * C<E<gt>name> - slurpy placeholder

Optional wildcard that matches everything including slashes. If it follows a
slash with no curly braces, the slash is made optional as well.

	# matches both /api and /api/v1/users
	'/api/>rest'

=back

Placeholders can be enclosed in curly braces to separate them from surrounding
text:

	'/user-{:id}-profile'

Placeholders can be validated using C<checks> parameter, which maps placeholder
names to regular expressions:

	$router->add(
		'/user/:id' => {
			to => 'show_user',
			checks => { id => qr/\d+/ },
		}
	);

Optional placeholders can be given default values using C<defaults> parameter:

	$router->add(
		'/post/?page' => {
			to => 'list_posts',
			defaults => { page => 1 },
		}
	);

When a default is specified, the destination will receive that value instead of
C<undef> when the placeholder is not present in the URL.

=head3 Bridges

Bridges are routes that have children. They are useful for implementing
authentication, authorization, or any other pre-processing logic that should
apply to multiple routes. They may also be used to group routes together. A
bridge is created when you call C<add> on the result of another C<add>:

	my $admin_bridge = $router->add(
		'/admin' => {
			to => 'check_admin',
		}
	);

	$admin_bridge->add(
		'/users' => {
			to => 'list_users',
		}
	);

When C</admin/users> is requested, both C<check_admin> and C<list_users> will
be called in sequence. The bridge destination receives the same arguments as
regular destinations. If the bridge consumes the context (by sending a
response), further matching stops. Otherwise, the next matching location is
called. For this reason, bridge destinations should return C<undef> explicitly
to avoid consuming the context by accident:

	sub check_admin ($self, $ctx)
	{
		await $self->render_error($ctx, 403)
			unless $ctx->req->session->{is_admin};

		# if context is not consumed, continue to next match
		return undef;
	}

Bridges only match for paths when a full level is matched, for example the
above admin bridge will match for C</admin> and C</admin/test>, but not for
C</admins>. For this reason, all locations under the bridge should start their
patterns with C</>. The sole exception to this is creating a location under a
bridge with an empty pattern, which will match the exact same pattern as the
bridge, but still be under the bridge in the hierarchy:

	# ran after $admin_bridge, but only on the same pattern
	$admin_bridge->add(
		'' => {
			to => 'admin_homepage',
		},
	);

=head3 Actions

Actions allow routes to be restricted to specific request types. By default,
routes match all HTTP methods and scopes. Actions are specified using
the C<action> parameter:

	$router->add(
		'/api/data' => {
			to => 'get_data',
			action => 'http.get',
		}
	);

Action format is C<scope.method> where scope is one of C<http>, C<sse>, or
C<websocket>, and method is an HTTP method for C<http> or C<sse> scope, or
omitted for C<websocket>. Either part can be C<*> to match anything.

If a C<.get> route is created, it is automatically valid for similar C<HEAD>
requests as well. If special C<HEAD> handling is required, a check can be made
in handler code:

	sub handle ($self, $ctx)
	{
		...; # set headers

		# return empty (but defined) response if we have HEAD, full body
		# otherwise
		return '' if $ctx->req->is_head;
		return 'full body';
	}

Common action patterns:

	# Match only HTTP POST requests
	action => 'http.post'

	# Match any HTTP method
	action => 'http.*'

	# Match only WebSocket connections
	action => 'websocket'

	# Match only Server-Sent GET and HEAD Events
	action => 'sse.get'

	# Match any request type (default)
	action => '*.*'

Multiple routes with the same pattern but different actions can coexist,
allowing different handlers for different request types:

	$router->add('/api/data' => { to => 'get_data', action => 'http.get' });
	$router->add('/api/data' => { to => 'post_data', action => 'http.post' });
	$router->add('/api/data' => { to => 'stream_data', action => 'websocket' });

If the handler is the same for all actions, it can be achieved with a simple
for loop:

	for my $action (qw(http.get http.post websocket)) {
		$router->add('/api/data' => { to => 'handle_api_data', action => $action });
	}

Make sure that the order of route building is deterministic, and that C<name>
(if provided) is unique.

=head3 PAGI compatibility

Thunderhorse was coded in such a way that allows it to fully integrate the PAGI
ecosystem. Instead of a destination described in L</Destinations>, a
PAGI application can be specified, together with C<< pagi => true >> argument:

	$router->add('/pagi-app' => { to => $pagi_app, pagi => true });
	$router->add('/pagi-app/>path' => { to => $pagi_app, pagi => true });

C<$pagi_app> must be a PAGI-native async sub. In the first instance, we mount
the application under C</pagi-app>, but C</pagi-app/something> will not be
routed through it. In the second instance, we use slurpy placeholder to route
both C</pagi-app> and all routes underneath it to that application.

In addition to native support for PAGI applications, any location can be
wrapped in extra PAGI middleware (including those handled Thunderhorse-native
destinations described in L</Destinations>):

	$router->add('/with-middleware' => {
		to => sub { ... },
		pagi_middleware => sub ($app) {
			builder {
				enable 'Some::Middleware';
				$app;
			};
		};
	});

The above example uses L<PAGI::Middleware::Builder> to wrap the C<$app> object
in the middlewares, but any valid method of doing that can be used. PAGI
middlewares are always run just before the destination handler is fired, as one
would expect.

=head2 Controllers

By default, all routes defined in the application's C<build> method belong to
the application controller (L<Thunderhorse::AppController>). However, as
applications grow, it becomes useful to organize routes and their handlers into
separate controller classes. Each controller is a self-contained unit with its
own routes and methods.

Controllers are subclasses of L<Thunderhorse::Controller> and typically live in
a namespace under your application. Each controller has its own C<build> method
where routes are defined:

	# lib/MyApp/Controller/User.pm
	package MyApp::Controller::User;

	use v5.40;
	use Mooish::Base;

	extends 'Thunderhorse::Controller';

	sub build ($self)
	{
		my $r = $self->router;

		$r->add('/users' => { to => 'list' });
		$r->add('/user/:id' => { to => 'show' });
	}

	sub list ($self, $ctx)
	{
		return "List of users";
	}

	sub show ($self, $ctx, $id)
	{
		return "User $id";
	}

Controllers have access to C<< $self->app >> to reach the application object,
and C<< $self->router >> which automatically sets the controller context for
route definitions. Do not use C<< $self->app->router >>, as this will yield
router configured for use in base app.

=head3 Loading controllers

Controllers are loaded in the application's C<build> method using
C<load_controller>:

	# in MyApp
	sub build ($self)
	{
		$self->load_controller('User');
	}

The C<load_controller> method takes a short name and automatically prepends
your application's namespace. In the above example, it loads
C<MyApp::Controller::User>. The controller's C<build> method is called
automatically, registering all its routes.

To load a controller from a different namespace, prefix the name with C<^>:

	$self->load_controller('^Some::Other::Controller::Class');

Controllers can also be loaded from configuration files, which is covered in
the L</Configuration> section.

=head2 Modules

Modules are reusable, configurable parts of Thunderhorse that have great power
over the system. They can add new methods and wrap application in middlewares.
Creation of modules is an advanced topic, discussed in L<Thunderhorse::Module>.
Here, we will focus on modules available in base Thunderhorse.

To load a module, the following call must be made in the application:

	$self->load_module('Name' => { config_key => config_value });

This loads C<Thunderhorse::Module::Name> and initializes it with the given hash
configuration. If C<Name> is a full name of the module, it should instead be
passed as C<^Name> to avoid adding the namespace prefix.

=head3 Logger

The Logger module (L<Thunderhorse::Module::Logger>) adds logging capabilities
to the application. It wraps the entire application to catch and log errors,
and adds a C<log> method to controllers.

Loading the module:

	$self->load_module('Logger' => {
		outputs => [
			screen => {
				'utf-8' => true,
			},
		],
	});

Configuration is passed to C<Gears::Logger::Handler>, which handles the actual
logging using L<Log::Handler>. Common configuration keys:

=over

=item * C<outputs> - hash of Log::Handler output destinations (file, screen, etc.)

=item * C<date_format> - strftime date format in logs, mimicing apache format by default

=item * C<log_format> - sprintf log format, mimicing apache format by default

=back

The default C<log_format> is C<[%s] [%s] %s>, where placeholders are: date,
level and message. Log format can be specified on Log::Handler level in
C<outputs> (per output), but it would cause duplication of formatting. In that
case C<log_format> must be set to C<undef> to avoid an exception on startup.

Once loaded, logging can be done from any controller method:

	sub some_action ($self, $ctx)
	{
		$self->log(info => 'Processing request');
		$self->log(error => 'Something went wrong');

		return "Done";
	}

The Logger module also automatically logs any unhandled exceptions that occur
during request processing.

=head3 Template

The Template module (L<Thunderhorse::Module::Template>) adds template rendering
capabilities using L<Template::Toolkit>. It adds a
L<Thunderhorse::Module::Template/template> method to controllers.

Loading the module:

	$self->load_module('Template' => {
		paths => ['views'],
		conf => {
			EVAL_PERL => true,
		},
	});

Configuration is passed to C<Gears::Template::TT>, which wraps Template
Toolkit.

=over

=item * C<conf> - hash of Template::Toolkit configuration values

=item * C<paths> - array ref of paths to search for templates

=item * C<encoding> - encoding of template files, UTF-8 by default

=back

C<paths> and C<encoding> will be automatically set as proper keys in
Template::Toolkit config, unless it was specified there separately, in which
case they will be ignored.

Once loaded, templates can be rendered from controller methods:

	sub show_page ($self, $ctx)
	{
		return $self->template('page', {
			title => 'My Page',
			content => 'Hello, World!',
		});
	}

The first argument is the template name (C<.tt> suffix will be added
automatically), and the second is a hash reference of variables to pass to the
template. The method returns the rendered content, which is then sent to the
client as HTML (if the context is not already consumed).

If the first argument is passed as the reference, the behavior changes:

=over

=item * for GLOB refs, filehandle will be read and its contents will be used as the template

=item * for SCALAR refs, the referenced scalar will be used as the template

=back

For simple apps, it is often useful to parse C<DATA>. GLOB refs will be
rolled back after reading them automatically.

	sub render_data ($self, $ctx)
	{
		return $self->template(\*DATA);
	}

=head3 Middleware

The Middleware module (L<Thunderhorse::Module::Middleware>) allows loading any
PAGI middleware into the application. It wraps the entire PAGI application
with specified middlewares.

Loading the module:

	$self->load_module('Middleware' => {
		Static => {
			path => '/static',
			root => 'public',
		},
		Session => {
			store => 'file',
		},
	});

Each key in the configuration is a middleware class name (will be prefixed with
C<PAGI::Middleware::> unless it starts with C<^>). The value is a hash
reference of configuration passed to that middleware's constructor.

Middlewares are applied in deterministic order (sorted by key name). To control
the order explicitly, use the C<_order> key in middleware configuration:

	$self->load_module('Middleware' => {
		Static => { path => '/static', root => 'public', _order => 1 },
		Session => { store => 'file', _order => 2 },
	});

Lower C<_order> values are applied first, higher values are
applied last.

=head2 Configuration

Thunderhorse applications can be configured using configuration files or by
passing a hash to the constructor. Configuration is managed by
L<Thunderhorse::Config>, which extends L<Gears::Config>.

=head3 Loading configuration from files

By default, Thunderhorse does not look for any configuration files. A string
can be passed to C<initial_config>, specifying the directory in which to look:

	MyApp->new(initial_config => 'conf')->run;

This will load configuration from the C<conf> directory. Configuration files
are loaded in order:

=over

=item 1. C<config.$ext> - base configuration

=item 2. C<$env.$ext> - environment-specific configuration

=back

Where C<$ext> is any extension handled by available config readers (C<.pl> for
Perl scripts by default), and C<$env> is the current environment (production,
development, or test). The environment can be set via the C<PAGI_ENV>
environment variable or the C<env> constructor parameter. C<pagi-server -E
production> also sets C<PAGI_ENV>.

Configuration files are merged together, with environment-specific settings
overriding base settings. Example structure:

	# conf/config.pl
	{
		modules => {
			Logger => {
				outputs => [ screen => { ... } ],
			},
		},
	}

	# conf/production.pl
	{
		modules => {
			Logger => {
				'=outputs' => [ file => { ... } ],
			},
		},
	}

In production environment, the Logger module will use C<file> output instead of
the C<screen> output from base config.

=head3 Configuration merging

When multiple configuration sources are loaded, they are merged together using
a smart merge system. By default, configuration keys are merged intelligently
based on their types:

=over

=item * C<key> - Smart merge (default)

Without any prefix, configuration values are merged based on their type. Hash
references are merged recursively, applying new keys and updating existing ones
from the new configuration. Array references are extended with new values.
Scalar values and mismatched reference types replace the old value.

	# base config
	{ controllers => ['User', 'Admin'] }

	# override config
	{ controllers => ['Admin', 'API'] }

	# result: all controllers are loaded
	{ controllers => ['User', 'Admin', 'API'] }

=item * C<=key> - Replace

The equals sign prefix forces complete replacement of the value, regardless of
type. This is useful when you want to completely override a complex structure
instead of merging it.

	# base config
	{ controllers => ['User', 'Admin'] }

	# override config
	{ '=controllers' => ['Admin', 'API'] }

	# result: config is overridden
	{ controllers => ['Admin', 'API'] }

=item * C<+key> - Add

The plus sign prefix explicitly adds to the existing value. For arrays, new
elements are appended. For hashes, new keys are added and existing keys are
merged recursively.

	# base config
	{ controllers => ['User', 'Admin'] }

	# override config
	{ '+controllers' => ['Admin', 'API'] }

	# result: duplicates are applied
	{ controllers => ['User', 'Admin', 'Admin', 'API'] }

=item * C<-key> - Remove

The minus sign prefix removes values from arrays. It compares the array in the
new configuration with the existing array and removes matching elements. This
only works for arrays.

	# base config
	{ controllers => ['User', 'Admin'] }

	# override config
	{ '-controllers' => ['Admin', 'API'] }

	# result: the set is reduced by matched keys
	{ controllers => ['User'] }

=back

Type mismatches (such as trying to merge a hash into an array) raise an error.
The C<=> prefix can be used to force replacement when changing types.

Prefixes apply to the immediate key only and do not affect nested structures.
To control merging of nested keys, apply prefixes to those keys explicitly:

	{
		modules => {
			Logger => {
				'=outputs' => ['file'],
				'+extra' => { new_key => 'value' },
			},
		},
	}

=head3 Loading configuration from hash

Configuration can be provided directly as a hash reference:

	MyApp->new(initial_config => {
		modules => {
			Logger => { outputs => [ screen => {} ] },
		},
	})->run;

This approach is useful for testing or when configuration comes from other
sources.

=head3 Loading controllers and modules from configuration

Controllers and modules can be specified in configuration files instead of
calling C<load_controller> and C<load_module> in code:

	# in config file
	{
		controllers => ['User', 'Admin', 'API'],
		modules => {
			Logger => {
				outputs => [ screen => {} ],
			},
			Template => {
				paths => ['views'],
			},
		},
	}

The C<controllers> key is an array of controller names to load. The C<modules>
key is a hash where keys are module names and values are configuration hashes
for each module. Both controllers and modules are loaded during application
initialization, before the C<build> method is called.

=head2 Hacking and extending

Thunderhorse is very hackable due to the system being based on events and
callbacks. Events are handled by hooks, while callbacks are executed using
various overridable methods.

=head3 Hooks

Hooks are pieces of code which are executed when a certain event is fired in
the system. There are two usage patterns for event handling with hooks:

=over

=item * hook methods

	# in controller
	async sub on_error ($self, $ctx, $error)
	{
		warn "error occured: $error";
	}

	# in app
	async sub on_error ($self, $controller, $ctx, $error)
	{
		warn "error occured: $error";
	}

Declaring hook like this allows full control over handling of an event. It can be
added on controller level or on application level. Overriding any hook method
can completely change how Thunderhorse handles this type of event. The
method calls will be awaited, but their return values are ignored.

Hooks methods prioritize controller-specific implementations over
application-level ones. For example, if a controller defines its own
C<on_error>, it will be called instead of the application's versions. This
allows fine-grained control over error handling for different parts of the
application. By default, all controller implementations delegate their work to
application's implementation.

Hook methods are useful to change how the event is handled or introduce special
event handling on the controller level.

=item * Hook notifications

	$app->hook(error => sub ($controller, $ctx, $error) {
		warn "error occured: $error";
	});

This use of hooks is easily pluggable into the system from any place and can be
used to add multiple handlers at once. Only application-wide hook notifications
are supported. Their return values are completely ignored. System will not
C<await> for their completion.

They are useful if you need to perform some extra internal tasks when an event
is fired, without modifying how event will be handled. This is especially
useful when developing a Thunderhorse module.

I<Note:> since hooks are stored in the application's instance, avoid creating a
strong reference cycle in memory by calling C<weaken> on all references to the
application's instance (for example by weakening C<$self> in C<build> method).

=back

Thunderhorse defines a closed set of supported hooks:

=head4 startup

	$app->hook(startup => sub ($state) { ... });

	async sub on_startup ($self, $state) { ... }

This is a lifespan hook, called during PAGI application lifecycle, when worker
processes is started.

Receives a C<$state> hash reference that is shared across the system. This can
be used to store handles or other resources that need to be managed on
per-worker basis.

This hook's method B<cannot be declared on a controller level>.

=head4 shutdown

	$app->hook(shutdown => sub ($state) { ... });

	async sub on_shutdown ($self, $state) { ... }

This is a lifespan hook, called during PAGI application lifecycle, when worker
processes is killed.

Receives a C<$state> hash reference that is shared across the system. This can
be used to free handles or other resources that need to be managed on
per-worker basis.

This hook's method B<cannot be declared on a controller level>.

=head4 error

	$app->hook(error => sub ($controller, $ctx, error) { ... });

	async sub on_error ($self, $ctx, $error) { ... }
	async sub on_error ($self, $controller, $ctx, $error) { ... }

The C<on_error> hook is called when an exception occurs during request
processing.

This hook should consume the context by sending a response. The default handler
calls L</render_error> method a text page with an error message.

=head3 Overriding system methods

Overridable methods are similar to hook methods. They are required to perform
certain actions in the system. Like hook methods, they can be defined on app
level or controller level. Unlike hooks, there are no notifications fired for
them.

=head4 render_response

	async sub render_response($self, $ctx, $result) { ... }
	async sub render_response($self, $controller, $ctx, $result) { ... }

This method is only run when a handler for a location does not consume the
context, but returns a defined value. The default implementation does the
following things:

=over

=item * tries to set HTTP status code to 200 (if it was not set already)

=item * tries to set C<Content-Type> header to C<text/html> (if it was not set already)

=item * awaits sending C<$result> to the client using L<PAGI::Response/send> method (as text)

=back

It can be modified to add more DWIM-based behavior, for example check for
references and render them as JSON/YAML.

=head4 render_error

	async sub render_error($self, $ctx, $code, $message = undef) { ... }
	async sub render_error($self, $controller, $ctx, $code, $message = undef) { ... }

This method's default implementation sends a plain text response with code
C<500>. The default implementation checks C<is_production> method of the
application to avoid rendering the original error message which may contain
sensitive information. It also acknowledges the existence of L<Gears::X::HTTP>,
which may change the error code to something else.

=head2 Performance tuning

If performance becomes a concern, the first step would be to make sure the
configuration of the PAGI server which runs the application is tuned for
performance. Since PAGI is based on an event loop, a choice of an event loop
backend may affect performance.

It may be the case that the application is not using all the available CPU, but
rather blocking the event loop waiting for I/O operations to finish, while
other requests are queued up for their turn to be handled. The most common
cause of this would be long database queries. If the system architecture allows
it, use non-blocking I/O operations, which allows for smoother handling of
requests. Long-running calculations like password hashing can be offloaded to
subprocesses and awaited.

For big applications with a lot of routes, setting
L<Thunderhorse::Router/cache> could noticeably affect performance. Thunderhorse
router is cache-friendly, and all workers can use the same cache keys when the
cache is located outside of the perl process, reducing the memory footprint.

Framework's performance can be improved for free simply by installing extra
modules which improve the performance of Moo and Type::Tiny. The module will
use them automatically if available. The list includes:

=over

=item * L<MooX::TypeTiny>

=item * L<Class::XSAccessor>

=item * L<MooX::XSConstructor>

=item * L<Type::Tiny::XS>

=back

If you find a performance bottleneck in the framework's code, please let us know.

=head2 Getting help

Use L<issues on
GitHub|https://github.com/Thunderhorse-Framework/Thunderhorse/issues> to report
bugs or request enhancements.

Use L<discussions on
GitHub|https://github.com/orgs/Thunderhorse-Framework/discussions> to ask
questions or discuss Thunderhorse.

For private inquiries, use the author's mail listed in L</Author>.

=head1 SEE ALSO

L<PAGI>, L<Gears>, L<Kelp>

=head1 CREDITS

=head2 Author

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

Consider supporting my effort: https://bbrtj.eu/support

=head2 Contributors

None yet

=head2 Acknowledgements

Thank you to Stefan Geneshky who created L<Kelp>, which was an inspiration for
Thunderhorse.

Thank you to John Napiorkowski who created L<PAGI>, which made Thunderhorse
possible.

Thank you to Alexander Karelas for his encouragement and counseling during
development of Thunderhorse.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

