package WebService::Shutterstock::Customer;
{
  $WebService::Shutterstock::Customer::VERSION = '0.006';
}

# ABSTRACT: Class allowing API operations in the context of a specific customer

use strict;
use warnings;
use Moo;
use WebService::Shutterstock::Subscription;
use Carp qw(croak);
use JSON qw(encode_json);
use WebService::Shutterstock::LicensedVideo;

use WebService::Shutterstock::AuthedClient;
with 'WebService::Shutterstock::AuthedClient';


sub account_id {
	my $self = shift;
	return $self->_info->{account_id};
}


sub metadata_field_definitions {
	my $self = shift;
	return $self->_info->{metadata_field_definitions};
}

has _info => ( is => 'lazy' );
sub _build__info {
	my $self = shift;
	my $client = $self->client;
	$client->GET( sprintf( '/customers/%s.json', $self->username ), $self->with_auth_params );
	my $data = $client->process_response;
	return $data;
}


has subscriptions => ( is => 'lazy' );
sub _build_subscriptions {
	my $self = shift;
	$self->client->GET( sprintf( '/customers/%s/subscriptions.json', $self->username ), $self->with_auth_params );
	my $subscriptions = $self->client->process_response;
	return [ map { $self->new_with_auth( 'WebService::Shutterstock::Subscription', %$_ ) } @$subscriptions ]
}


sub subscription {
	my $self = shift;
	my ( $subscription, @extra ) = $self->find_subscriptions(@_);
	return $subscription;
}


sub find_subscriptions {
	my $self = shift;
	my %criteria = @_;
	my $filter = sub {
		my $s = shift;
		foreach my $m(keys %criteria){
			croak "Invalid subscription filter key '$m': no such attribute on WebService::Shutterstock::Subscription" if !$s->can($m);
			my $value = $s->$m;
			my $matcher = $criteria{$m};
			if(ref $matcher eq 'CODE'){
				local $_ = $value;
				return unless $matcher->($value);
			} elsif(ref $matcher eq 'Regexp'){
				return unless $value =~ $matcher;
			} else {
				return unless $value eq $matcher;
			}
		}
		return 1;
	};
	return grep { $filter->($_) } @{ $self->subscriptions };
}


sub lightboxes {
	my $self = shift;
	my $extended = shift || 0;
	$self->client->GET(
		sprintf(
			'/customers/%s/lightboxes%s.json',
			$self->username, $extended ? '/extended' : ''
		),
		$self->with_auth_params
	);
	my $lightboxes = $self->client->process_response;
	return [ map {$self->new_with_auth('WebService::Shutterstock::Lightbox', %$_) } @$lightboxes ];
}


sub lightbox {
	my $self = shift;
	my $id = shift;
	my $lightbox = $self->new_with_auth('WebService::Shutterstock::Lightbox', lightbox_id => $id);
	eval { $lightbox->load; 1 } or do {
		my $e = $@;
		if(eval { $e->isa('WebService::Shutterstock::Exception') } && ($e->code eq 404 || $e->code eq 500)){
			$lightbox = undef;
		} else {
			die $e;
		}
	};
	return $lightbox;
}


sub downloads {
	my $self = shift;
	my %args = @_;
	$self->client->GET(
		sprintf( '/customers/%s/images/downloads.json', $self->username ),
		$self->with_auth_params(%args) );
	return $self->client->process_response;
}


sub license_image {
	my $self     = shift;
	my %args     = @_;

	my $image_id = $args{image_id} or croak "Must specify image_id to license";

	my $editorial_acknowledgement = $args{editorial_acknowledgement} || 0;

	my $subscription = $self->_find_subscription_from_arg('photo', $args{subscription});
	if(!$subscription){
		croak "Must specify a subscription to license images under";
	}

	my $metadata = $self->_valid_metadata($args{metadata});

	my $size = $self->_valid_size_for_subscription($subscription, $args{size});

	my $format = $size eq 'vector' ? 'eps' : 'jpg';
	my $client = $self->client;

	$client->POST(
		sprintf(
			'/subscriptions/%s/images/%s/sizes/%s.json',
			$subscription->id, $image_id, $size
		),
		$self->with_auth_params(
			format                    => $format,
			editorial_acknowledgement => $editorial_acknowledgement,
			( $metadata ? ( metadata => encode_json($metadata) ) : () ),
		)
	);

	return WebService::Shutterstock::LicensedImage->new($client->process_response);
}


sub license_video {
	my $self     = shift;
	my %args     = @_;

	my $video_id = $args{video_id} or croak "Must specify video_id to license";

	my $editorial_acknowledgement = $args{editorial_acknowledgement} || 0;

	my $subscription = $self->_find_subscription_from_arg('video', $args{subscription});
	if(!$subscription){
		croak "Must specify a subscription to license videos under";
	}

	my $metadata = $self->_valid_metadata($args{metadata});

	my $size = $self->_valid_size_for_subscription($subscription, $args{size});

	my $client = $self->client;

	$client->POST(
		sprintf(
			'/subscriptions/%s/videos/%s/sizes/%s.json',
			$subscription->id, $video_id, $size
		),
		$self->with_auth_params(
			editorial_acknowledgement => $editorial_acknowledgement,
			( $metadata ? ( metadata => encode_json($metadata) ) : () ),
		)
	);

	return WebService::Shutterstock::LicensedVideo->new($client->process_response);
}

sub _find_subscription_from_arg {
	my $self = shift;
	my $type = shift;
	my $sub_arg = shift;


	my $single_finder = sub {
		my %criteria = @_;
		my @matching = $self->find_subscriptions( %criteria, is_active => 1, site => "${type}_subscription" );
		if ( @matching == 0 ) {
			croak "Unable to find a matching subscription to license ${type}s";
		} elsif ( @matching > 1 ) {
			croak "You have more than one active subscription.  Please provide a WebService::Shutterstock::Subscription object or specify unique critiria to identify which subscription you would like to use (i.e. { license => 'standard' } or { id => 26374582 } )";
		}
		return $matching[0];
	};

	my $subscription;

	if($sub_arg){
		if(!ref($sub_arg)){
			$subscription = $self->subscription( id => $sub_arg );
		} elsif(ref($sub_arg) eq 'HASH'){
			$subscription = $single_finder->( %$sub_arg );
		} elsif(eval { $sub_arg->isa('WebService::Shutterstock::Subscription') }){
			$subscription = $sub_arg;
		}
	} else {
		$subscription = $single_finder->();
	}
	if($subscription && $subscription->site ne "${type}_subscription"){
		croak sprintf('The subscription specified is for the wrong "site" (needed "%s_subscription", found %s)', $type, $subscription->site);
	}
	return $subscription;
}

sub _valid_size_for_subscription {
	my $self = shift;
	my $subscription = shift;
	my $size = shift;

	my @valid_sizes = $subscription->sizes_for_licensing;

	if(!$size && @valid_sizes == 1){
		$size = $valid_sizes[0];
	}
	croak "Must specify size of video to license" if !$size;

	if ( !grep { $_ eq $size } @valid_sizes ) {
		my %uniq_sizes = map {$_ => 1} @valid_sizes;
		croak "Invalid size '$size', please specify a valid size: " . join(", ", keys %uniq_sizes);
	}
	return $size;
}

sub _valid_metadata {
	my $self = shift;
	my $metadata = shift;
	my $valid;
	if(my $metadata_definitions = $self->metadata_field_definitions){
		$valid = $metadata || {};
		my @missing;
		foreach my $md(@{ $metadata_definitions }){
			$valid->{$md->{name_api}} = '' if !defined $valid->{$md->{name_api}};
			if($md->{is_required} && $valid->{$md->{name_api}} eq ''){
				push @missing, $md->{name_api};
			}
		}
		if(@missing){
		croak
			sprintf(
			'Missing required metadata field%s for licensing image: %s',
			@missing == 1 ? '' : 's', join ', ', @missing );
		}
	}
	return $valid;
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::Customer - Class allowing API operations in the context of a specific customer

=head1 VERSION

version 0.006

=head1 SYNOPSIS

	my $customer = $shutterstock->auth("my-user" => "my-password");

	# retrieve list of lightboxes
	my $lightboxes = $customer->ligthboxes;

	# retrieve a specific lightbox for this user
	my $lightbox = $customer->lightbox(123);

	my $subscriptions = $customer->subscriptions;
	my $enhanced_subscription = $customer->subscription(license => 'enhanced');

	my $download_history = $customer->downloads;

	# license an image (if you only have a single active subscription)
	my $licensed_image = $customer->license_image(
		image_id => 59915404,
		size     => 'huge'
	);

	# license an image (if you have more than one active subscription)
	my $licensed_image = $customer->license_image(
		image_id     => 59915404,
		size         => 'huge',
		subscription => { license => 'standard' }
	);

=head1 DESCRIPTION

This class provides access to API operations (download history, lightbox interaction, subscriptions, etc) that require an authenticated
customer (via L<WebService::Shutterstock/"auth">).

=head1 METHODS

=head2 account_id

Retrieves the account ID for this account.

=head2 metadata_field_definitions

Retrieves the set of metadata fields for your account (if so configured
by Shutterstock).  Returns an ArrayRef of HashRefs (or C<undef> if
this feature doesn't apply to your account).  When
L<licensing an image|/license_image> you should provide the required
metadata values using the C<name_api> values specified for each
metadata field returned by this method.

=head2 subscriptions

Returns an ArrayRef of L<WebService::Shutterstock::Subscription> objects for this customer account.

=head2 subscription

Convenience wrapper around the C<find_subscriptions> method that always
returns the first match (useful when you're matching on a field that is
unique like C<id> or C<license>).

	# find the (single) subscription providing an enhanced license
	my $media_digital_subscription = $customer->subscription(license => 'enhanced');

=head2 find_subscriptions

Retrieve a list of L<WebService::Shutterstock::Subscription> objects, based
on the criteria passed in to the method. Filter criteria should have
L<WebService::Shutterstock::Subscription> attribute names as keys with the value
to be matched as the value.  Subscriptions that match ALL the provided
criteria are returned as a list.  Some examples:

	# simple equality filters
	my @active_subscriptions = $customer->find_subscriptions( is_active => 1 );
	my @active_subscriptions = $customer->find_subscriptions( is_active => 1 );

	# regular expressions work too
	my @all_media_subscriptions = $customer->find_subscriptions( license => qr{^media} );

	# use an anonymous sub for more detailed filters (i.e. subscriptions expiring in the 
	my @soon_to_expire = $customer->find_subscriptions(
		is_active            => 1,
		unix_expiration_time => sub { shift < time + ( 60 * 60 * 24 * 30 ) }
	);

=head2 lightboxes($get_extended_info)

Returns an ArrayRef of L<WebService::Shutterstock::Lightbox> objects for this
customer acount.  By default, it gets only the lightbox information and
the list of image IDs in the lightbox.  If you would like to retrieve
more details about those images (specifically sizes and thumbnail URLs)
in a single HTTP request, just pass a true value as the only argument
to this method.

=head2 lightbox($id)

Returns a specific lightbox (as a L<WebService::Shutterstock::Lightbox> object)
for the given C<$id> (it must belong to this user).  If that lightbox
doesn't exist, C<undef> will be returned.  Unfortunately, Shutterstock's
API currently returns an HTTP status of C<500> on an unknown lightbox ID
(which could mask other error situations).

=head2 downloads

Retrieve the download history for this customer account.  You can
specify a C<page_number> argument if you prefer to retrieve a single
page of results (starting with page C<0>).

The data returned will be a HashRef keyed by the subscription ID used
to download the images and will look something like this:

	{ "123456" =>            # subscription ID
		[
			{
				image_id => 1,
				license  => 'standard',
				time     => '2012-11-01 14:16:08',
			},
			{
				image_id => 2,
				license  => 'premier',
				metadata => { purchase_order => 'XYZ', client => 'My Client' },
				time     => '2012-11-01 14:18:39',
			},
			# etc...
		]
	}

You can fetch the C<redownloadable_state> of a particular image (C<image_id> must also be specified):

	my $redownloadable_state = $customer->downloads(
		image_id => 11024440,
		field    => "redownloadable_state"
	);

In this call, you should see an extra field inside the image block indicating whether
the image qualifies as a redownload under that subscription:

	{ "123456" =>            # subscription ID
		[
			{
				image_id => 1,
				license  => 'standard',
				time     => '2012-11-01 14:16:08',
				redownloadable_state => 1          # boolean
			}
		]
	}

=head2 license_image(image_id => $image_id, size => $size)

Licenses a specific image in the requested size.  Returns a
L<WebService::Shutterstock::LicensedImage> object.

If you have more than one active subscription, you will need to specify
which subscription you would like to use for licensing with a C<subscription>
argument.  You can pass in a L<WebService::Shutterstock::Subscription> object or
any criteria that can be passed to L</find_subscriptions> that will identify
a single subscription.  For instance:

	# by "license"
	my $licensed_image = $customer->license_image(
		image_id     => $image_id,
		size         => $size,
		subscription => { license => 'standard' }
	);

	# by "id"
	my $licensed_image = $customer->license_image(
		image_id     => $image_id,
		size         => $size,
		subscription => { id => 63746273 }
	);

	# or explicitly, with a subscription object
	my $enhanced = $customer->subscription( license => 'enhanced' );
	my $licensed_image = $customer->license_image(
		image_id     => $image_id,
		size         => $size,
		subscription => $enhanced
	);

If your account is configured by Shutterstock to require custom
metadata values to be provided when licensing images (see
L</metadata_field_definitions>), you can provide those values
using the C<metadata> parameter.  For instance:

	my $licensed_image = $customer->license_image(
		image_id     => $image_id,
		size         => $size,
		subscription => $subscription,
		metadata     => { purchase_order => '<value here>', }
	);

If the image requires an acknowledgment that it will only be used in an
editorial context, you must pass the C<editorial_acknowledgement =&gt; 1>
argument to the method.

=for Pod::Coverage license_video

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
