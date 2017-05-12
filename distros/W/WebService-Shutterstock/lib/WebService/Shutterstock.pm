package WebService::Shutterstock;
{
  $WebService::Shutterstock::VERSION = '0.006';
}

# ABSTRACT: Easy access to Shutterstock's public API

use strict;
use warnings;

use Moo 1;
use REST::Client;
use MIME::Base64;
use JSON qw(encode_json decode_json);
use WebService::Shutterstock::Lightbox;
use WebService::Shutterstock::Client;
use WebService::Shutterstock::Customer;
use WebService::Shutterstock::SearchResults;
use WebService::Shutterstock::Exception;
use WebService::Shutterstock::Video;

has api_username => (
	is => 'ro',
	required => 1,
);
has api_key => (
	is => 'ro',
	required => 1,
);
has client => (
	is       => 'lazy',
	clearer  => 1,
);

sub _build_client {
	my $self = shift;
	my $client = WebService::Shutterstock::Client->new( host => $ENV{SS_API_HOST} || 'https://api.shutterstock.com' );
	$client->addHeader(
		Authorization => sprintf(
			'Basic %s',
			MIME::Base64::encode(
				join( ':', $self->api_username, $self->api_key )
			)
		)
	);
	return $client;
}



sub auth {
	my $self = shift;
	my %args = @_;
	$args{username} ||= $self->api_username;
	if(!$args{password}){
		die WebService::Shutterstock::Exception->new( error => "missing 'password' param for auth call");
	}
	$self->client->POST(
		'/auth/customer.json',
		{
			username => $args{username},
			password => $args{password}
		}
	);
	my $auth_info = $self->client->process_response;
	if(ref($auth_info) eq 'HASH'){
		return WebService::Shutterstock::Customer->new( auth_info => $auth_info, client => $self->client );;
	} else {
		die WebService::Shutterstock::Exception->new(
			response => $self->client->response,
			error    => "Error authenticating $args{username}: $auth_info"
		);
	}
}


sub categories {
	my $self = shift;
	$self->client->GET('/categories.json');
	return $self->client->process_response;
}


sub search {
	my $self = shift;
	my %args = @_;
	my $type = delete $args{type} || 'image';
	return WebService::Shutterstock::SearchResults->new( client => $self->client, query => \%args, type => $type );
}


sub search_images {
	return shift->search(@_, type => 'image');
}


sub search_videos {
	return shift->search(@_, type => 'video');
}


sub image {
	my $self = shift;
	my $image_id = shift;
	my $image = WebService::Shutterstock::Image->new( image_id => $image_id, client => $self->client );
	return $image->is_available ? $image : undef;
}


sub video {
	my $self = shift;
	my $video_id = shift;
	my $video = WebService::Shutterstock::Video->new( video_id => $video_id, client => $self->client );
	return $video->is_available ? $video : undef;
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock - Easy access to Shutterstock's public API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

	my $shutterstock = WebService::Shutterstock->new(
		api_username => 'justme',
		api_key      => 'abcdef1234567890'
	);

	# perform an image search
	my $search = $shutterstock->search( type => 'image', searchterm => 'hummingbird' );

	# or, a video search
	my $videos = $shutterstock->search( type => 'video', searchterm => 'hummingbird' );

	# retrieve results of search
	my $results = $search->results;

	# details about a specific image (lookup by ID)
	my $image = $shutterstock->image( 59915404 );

	# certain actions require credentials for a specific customer account
	my $customer = $shutterstock->auth( username => $customer, password => $password );

=head1 DESCRIPTION

This module provides an easy way to interact with the L<Shutterstock,
Inc. API|http://api.shutterstock.com>.  You will need an API username
and key from Shutterstock with the appropriate permissions in order to
use this module.

While there are some actions you can perform with this object (as shown
under the L</METHODS> section), many API operations are done within
the context of a specific user/account or a specific subscription.
Below are some additional examples of how to use this set of API modules.
You will find more examples and documentation in the related modules as
well as the C<examples> directory in the source of the distribution.

=head3 Licensing and Downloading

Licensing images happens in the context of a
L<WebService::Shutterstock::Customer> object.  For example:

	my $licensed_image = $customer->license_image(
		image_id => 59915404,
		size     => 'medium'
	);

If you have more than one active subscription, you will need to
specify which subscription to license the image under.  Please see
L<WebService::Shutterstock::Customer/license_image> for more details.

Once you have a L<licensed image|WebService::Shutterstock::LicensedImage>,
you can then download the image:

	$licensed_image->download(file => '/my/photos/hummingbird.jpg');

Every image licensed under your account (whether through shutterstock.com or the
API) can be retrieved using the L<customer|WebService::Shutterstock::Customer>
object as well:

	my $downloads = $customer->downloads;

Or, you can fetch one "page" (40 items) of downloads. Pages start being numbered at 0.

	my $page_two_of_downloads = $customer->downloads( page_number => 1 );

Or, you can fetch the C<redownloadable_state> of a particular image.

	my $redownloadable_state = $customer->downloads(
		image_id => 11024440,
		field    => "redownloadable_state"
	);

=head3 Lightboxes

Lightbox retrieval starts with a L<customer|WebService::Shutterstock::Customer>
as well but most methods are documented in the
L<WebService::Shutterstock::Lightbox> module.  Here's a short example:

	my $lightboxes = $customer->lightboxes;
	my($favorites) = grep {$_->name eq 'Favorites'} @$lightboxes;
	$favorites->add_image(59915404);

	my $favorite_images = $favorite->images;

=head1 METHODS

=head2 new( api_username => $api_username, api_key => $api_key )

Constructor method, requires both the C<api_username> and C<api_key>
parameters be passed in.  If you provide invalid values that the API
doesn't recognize, the first API call you make will throw an exception

=head2 auth(username => $username, password => $password)

Authenticate for a specific customer account.  Returns a
L<WebService::Shutterstock::Customer> object.  If authentication fails, an
exception is thrown (see L<WebService::Shutterstock::Exception> and L</"ERRORS">
section for more information).

This is the main entry point for any operation dealing with subscriptions,
image licensing, download history or lightboxes.

=head2 categories

Returns a list of photo categories (useful for specifying a category_id when searching).

=head2 search(%search_query)

Perform a search.  This method assumes you want to search images unless
you specify a C<type> parameter as part of the C<%search_query>.  Accepts
any params documented here: L<http://api.shutterstock.com/#imagessearch>.
Returns a L<WebService::Shutterstock::SearchResults> object.

=head2 search_images(%search_query)

Equivalent to calling C<search> with a C<type> parameter of C<image>.

=head2 search_videos(%search_query)

Equivalent to calling C<search> with a C<type> parameter of C<video>.

=head2 image($image_id)

Performs a lookup on a single image.  Returns a L<WebService::Shutterstock::Image> object (or C<undef> if the image doesn't exist).

=head2 video($video_id)

Performs a lookup on a single video.  Returns a L<WebService::Shutterstock::Video> object (or C<undef> if the image doesn't exist).

=head1 ERROR HANDLING

If an API call fails in an unexpected way, an exception object (see
L<WebService::Shutterstock::Exception>) will be thrown.  This object should
have all the necessary information for you to handle the error if you
choose but also stringifies to something informative enough to be
useful as well.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
