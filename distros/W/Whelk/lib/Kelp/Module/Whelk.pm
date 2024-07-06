package Kelp::Module::Whelk;
$Kelp::Module::Whelk::VERSION = '0.04';
use Kelp::Base 'Kelp::Module';
use Kelp::Util;
use Carp;
use Whelk::Schema;
use Whelk::ResourceMeta;

attr config => undef;
attr inhale_response => !!1;
attr openapi_generator => undef;
attr resources => sub { {} };
attr endpoints => sub { [] };

sub build
{
	my ($self, %args) = @_;
	$self->_load_config(\%args);

	# register before loading, so that controllers have acces to whelk
	$self->register(whelk => $self);
}

sub finalize
{
	my ($self) = @_;

	$self->_initialize_resources();
	$self->_install_openapi();
}

sub _load_package
{
	my ($self, $package, $base) = @_;

	my $class = Kelp::Util::camelize($package, $base, 1);
	return Kelp::Util::load_package($class);
}

sub _load_config
{
	my ($self, $args) = @_;
	my $app = $self->app;

	# if this is Whelk or based on Whelk, use the main config
	if ($app->isa('Whelk')) {
		$args->{$_} //= $app->config($_)
			for qw(
			resources
			openapi
			wrapper
			formatter
			inhale_response
			);
	}

	$args->{wrapper} //= 'Simple';
	$args->{formatter} //= 'JSON';

	$self->inhale_response($args->{inhale_response})
		if defined $args->{inhale_response};

	$self->config($args);
}

sub _initialize_resources
{
	my ($self) = @_;
	my $app = $self->app;
	my $args = $self->config;

	my %resources = %{$args->{resources} // {}};
	carp 'No resources for Whelk, you should define some in config'
		unless keys %resources;

	# sort to have deterministic order of endpoints
	foreach my $resource (sort keys %resources) {
		my $controller = $app->context->controller($resource);
		my $config = $resources{$resource};

		$config = {
			path => $config
		} unless ref $config eq 'HASH';

		croak "$resource does not extend " . $app->routes->base
			unless $controller->isa($app->routes->base);

		croak "$resource does not implement Whelk::Role::Resource"
			unless $controller->DOES('Whelk::Role::Resource');

		croak "Wrong path for $resource"
			unless $config->{path} =~ m{^/};

		$self->resources->{ref $controller} = {
			base_route => $config->{path},
			wrapper => $self
				->_load_package(
					$config->{wrapper} // $args->{wrapper},
					'Whelk::Wrapper',
				)
				->new,

			formatter => $self
				->_load_package(
					$config->{formatter} // $args->{formatter},
					'Whelk::Formatter',
				)
				->new(app => $self->app),

			resource => Whelk::ResourceMeta
				->new(
					class => $resource,
					config => $config,
				),
		};

		$controller->api;
	}
}

sub _install_openapi
{
	my ($self) = @_;
	my $app = $self->app;
	my $args = $self->config;

	my $config = $args->{openapi};
	return unless $config;

	$config = {
		path => $config
	} unless ref $config eq 'HASH';

	croak "Wrong path for openapi"
		unless $config->{path} =~ m{^/};

	my $openapi_class = $self->_load_package($config->{class} // 'Whelk::OpenAPI');
	$self->openapi_generator($openapi_class->new);

	my $formatter_class = $self->_load_package($config->{formatter} // $args->{formatter}, 'Whelk::Formatter');
	my $formatter = $formatter_class->new(app => $self->app);

	$self->openapi_generator->parse(
		app => $app,
		info => $config->{info},
		extra => $config->{extra},
		endpoints => $self->endpoints,
		schemas => Whelk::Schema->all_schemas,
	);

	$app->add_route(
		[GET => $config->{path}] => sub {
			my ($app) = @_;

			my $generated = $self->openapi_generator->generate();

			return $formatter->format_response($app, $generated, 'openapi');
		}
	);
}

1;

