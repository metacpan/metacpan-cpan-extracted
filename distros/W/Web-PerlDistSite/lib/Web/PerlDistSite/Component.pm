package Web::PerlDistSite::Component;

our $VERSION = '0.001010';

use Moo::Role;
use Web::PerlDistSite::Common -lexical, -all;

requires 'raw_content', 'filename';

has project => (
	is       => 'rw',
	isa      => Object,
);

sub write ( $self ) {
	my $path = $self->project->root->child( $self->filename );
	$path->parent->mkpath;
	$path->spew_if_changed( $self->raw_content );
}

1;
