package WebService::Shutterstock::Lightbox;
{
  $WebService::Shutterstock::Lightbox::VERSION = '0.006';
}

# ABSTRACT: Representation of a lightbox in Shutterstock's public API

use strict;
use version;
use Moo;
use WebService::Shutterstock::Image;
use WebService::Shutterstock::DeferredData qw(deferred);

use WebService::Shutterstock::AuthedClient;
with 'WebService::Shutterstock::AuthedClient';

deferred(
	['lightbox_name' => 'name', 'rw'],
	['images' => '_images', 'ro'],
	sub {
		my $self = shift;
		my $client = $self->client;
		$client->GET( sprintf('/lightboxes/%s/extended.json', $self->id), $self->with_auth_params );
		return $client->process_response;
	}
);


has id => ( is => 'rw', init_arg => 'lightbox_id' );
has public_url => ( is => 'lazy' );

sub _build_public_url {
	my $self = shift;
	my $client = $self->client;
	$client->GET( sprintf( '/lightboxes/%s/public_url.json', $self->id ), $self->with_auth_params );
	if(my $data = $client->process_response){
		return $data->{public_url};
	}
	return;
}


sub delete_image {
	my $self = shift;
	my $image_id = shift;
	my $client = $self->client;
	$client->DELETE(
		sprintf( '/lightboxes/%s/images/%s.json', $self->id, $image_id ),
		$self->with_auth_params( username => $self->username )
	);
	delete $self->{_images};
	return $client->process_response;
}


sub add_image {
	my $self = shift;
	my $image_id = shift;
	my $client = $self->client;
	$client->PUT(
		sprintf(
			'/lightboxes/%s/images/%s.json?%s',
			$self->id,
			$image_id,
			$client->buildQuery(
				username   => $self->username,
				auth_token => $self->auth_token
			)
		)
	);
	delete $self->{_images};
	return $client->process_response;
}


sub images {
	my $self = shift;
	return [ map { $self->new_with_auth('WebService::Shutterstock::Image', %$_ ) } @{ $self->_images || [] } ];
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::Lightbox - Representation of a lightbox in Shutterstock's public API

=head1 VERSION

version 0.006

=head1 ATTRIBUTES

=head2 id

The ID of this lightbox

=head2 name

The name of this lightbox

=head2 public_url

Returns a URL for access this lightbox without authenticating.

=head2 images

Returns a list of L<WebService::Shutterstock::Image> objects that are in this lightbox.

=head1 METHODS

=head2 delete_image

Removes an image from this lightbox.

=head2 add_image($id)

Adds an image to this lightbox.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
