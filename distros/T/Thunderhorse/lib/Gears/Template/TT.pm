package Gears::Template::TT;
$Gears::Template::TT::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use Template;
use Gears::X::Template;

extends 'Gears::Template';

has param 'conf' => (
	isa => HashRef,
	default => sub { {} },
);

has field 'engine' => (
	isa => InstanceOf ['Template'],
	lazy => 1,
);

sub _build_engine ($self)
{
	my %conf = $self->conf->%*;
	$conf{ENCODING} //= $self->encoding;
	$conf{INCLUDE_PATH} //= $self->paths;

	return Template->new(\%conf);
}

# override process to let TT load the templates itself
sub process ($self, $template, $vars)
{
	my $pos = ref $template eq 'GLOB' ? tell $template : undef;

	$template =~ s{(\..+)?$}{$1 // '.tt' }e
		unless ref $template;

	my $output;
	$self->engine->process($template, $vars, \$output)
		or Gears::X::Template->raise('' . $self->engine->error);

	# rewind if we were passed a handle
	seek $template, $pos, 0
		if defined $pos;

	return $output;
}

