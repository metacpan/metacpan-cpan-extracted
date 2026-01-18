package Thunderhorse::Module::Template;
$Thunderhorse::Module::Template::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use Gears::X::Thunderhorse;
use Gears::Template::TT;

extends 'Thunderhorse::Module';

has field 'template' => (
	isa => InstanceOf ['Gears::Template'],
	lazy => 1,
);

sub _build_template ($self)
{
	my $config = $self->config;

	return Gears::Template::TT->new($config->%*);
}

sub build ($self)
{
	weaken $self;
	my $tpl = $self->template;

	$self->add_method(
		controller => template => sub ($controller, $template, $vars = {}) {
			return $tpl->process($template, $vars);
		}
	);
}

__END__

=head1 NAME

Thunderhorse::Module::Template - Template module for Thunderhorse

=head1 SYNOPSIS

	# in application build method
	$self->load_module('Template' => {
		paths => ['views'],
		conf => {
			EVAL_PERL => true,
		},
	});

	# in controller method
	sub show_page ($self, $ctx)
	{
		return $self->template('page', {
			title => 'My Page',
			content => 'Hello, World!',
		});
	}

	# parse DATA handle
	sub render_data ($self, $ctx)
	{
		return $self->template(\*DATA);
	}

=head1 DESCRIPTION

The Template module adds template rendering capabilities using
L<Template::Toolkit>. It adds a L</template> method to controllers.

=head1 CONFIGURATION

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

=head1 ADDED INTERFACE

=head2 Controller Methods

=head3 template

	$self->template('page', { title => 'My Page' });
	$self->template(\*DATA);
	$self->template(\$template_string);

Parses a template and returns the content. The first argument is the template
name (C<.tt> suffix will be added automatically), and the second is a hash
reference of variables to pass to the template. The method returns the parsed
content, which can then be returned from the handler to be sent to the client
as HTML (if the context is not already consumed).

If the first argument is passed as a reference, the behavior changes:

=over

=item * for GLOB refs, filehandle will be read and its contents will be used as the template

=item * for SCALAR refs, the referenced scalar will be used as the template

=back

GLOB refs will be rolled back after reading them automatically, making it
useful for rendering from C<DATA> handles.

=head1 SEE ALSO

L<Thunderhorse::Module>, L<Gears::Template>

