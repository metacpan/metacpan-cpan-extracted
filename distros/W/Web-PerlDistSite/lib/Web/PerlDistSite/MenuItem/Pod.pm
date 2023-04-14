package Web::PerlDistSite::MenuItem::Pod;

our $VERSION = '0.001010';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

use Pod::Find qw( pod_where );

extends 'Web::PerlDistSite::MenuItem';
with 'Web::PerlDistSite::MenuItem::_PodCommon';

has '+title' => (
	is       => 'lazy',
	default  => sub ( $s ) {
		$s->pod;
	},
);

has '+name' => (
	is       => 'lazy',
	default  => sub ( $s ) {
		$s->pod =~ s{::}{-}gr;
	},
);

has pod => (
	is       => 'ro',
	isa      => Str,
);

has raw_content => (
	is       => 'lazy',
	isa      => Str,
	builder  => true,
);

sub body_class {
	return 'page from-pod';
}

sub _build_raw_content ( $self ) {
	
	my $local = pod_where( { -inc => true }, $self->pod );
	return path( $local )->slurp_utf8 if $local;
	
	require HTTP::Tiny;
	state $ua = HTTP::Tiny->new;
	my $response = $ua->get( sprintf(
		'https://fastapi.metacpan.org/v1/pod/%s?content-type=text/x-pod',
		$self->pod,
	) );
	return $response->{content} if $response->{success};
	
	die sprintf( "pod not found: %s\n", $self->pod );
}

sub write_page ( $self ) {
	$self->system_path->parent->mkpath;
	$self->system_path->spew_if_changed( $self->compile_page );
}

1;
