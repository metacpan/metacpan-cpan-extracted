package Web::PerlDistSite::MenuItem::File;

our $VERSION = '0.001010';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

extends 'Web::PerlDistSite::MenuItem';

has source => (
	is       => 'ro',
	isa      => PathTiny,
	coerce   => true,
);

sub body_class {
	return 'page';
}

sub compile_page ( $self ) {
	...;
}

sub raw_content ( $self ) {
	return $self->source->slurp_utf8;
}

sub write_page ( $self ) {
	$self->system_path->parent->mkpath;
	$self->system_path->spew_if_changed( $self->compile_page );
}

1;
