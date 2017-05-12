package WebService::Pushwoosh;

use 5.006;
use strict;
use warnings;

=head1 NAME

WebService::Pushwoosh - An interface to the Pushwoosh Remote API v1.3

=head1 SYNOPSIS

	# Create a WebService::Pushwoosh instance
	my $pw = WebService::Pushwoosh->new(
		app_code  => '00000-00000',
		api_token => 'YOUR_APP_TOKEN'
	);
  
	# Send a message to all your app's subscribers
	$pw->create_message(content => "Hello, world!");
	
	# Limit to one device
	$pw->create_message(
		content => 'Pssst',
		devices =>
			['dec301908b9ba8df85e57a58e40f96f523f4c2068674f5fe2ba25cdc250a2a41']
	);

See below for further examples.

=head1 DESCRIPTION

L<Pushwoosh|http://www.pushwoosh.com/> is a push notification service which
provides a JSON API for users of its premium account. This module provides a
simple Perl wrapper around that API.

For information on integrating the Pushwoosh service into your mobile apps, see
L<http://www.pushwoosh.com/programming-push-notification/>.

To obtain an API token, log in to your Pushwoosh account and visit
L<https://cp.pushwoosh.com/api_access>.

=head1 VERSION

Version 0.02

=head1 CONSTRUCTOR

=head2 new

	my $pw = WebService::Pushwoosh->new(
		app_code  => '00000-00000',
		api_token => 'YOUR_APP_TOKEN'
	);

Creates a WebService::Pushwoosh instance.

Parameters:

=over

=item app_code

Your Pushwoosh application code (required)

=item api_token

Your API token from Pushwoosh (required)

=item api_url

The API url for Pushwoosh (optional).

It is not recommended to change this from the default.

=item furl

A custom L<Furl> object to use for the requests (optional).

It is not recommended to change this.

=item error_mode

Set this to either C<'croak'> or C<'manual'>. C<'croak'> is the default and
will generate an error string if an error is detected from in the Pushwoosh
response. C<'manual'> will simply return the API status response when a method
errors, if you want more control over the error handling. See the Pushwoosh
documentation for the possible error codes.

=back

=cut

our $VERSION = '0.02';

use Carp;
use Furl;
use JSON qw(from_json to_json);
use Params::Validate qw(validate validate_with validate_pos :types);
use Try::Tiny;

sub new {
	my $class = shift;
	my %args  = validate(
		@_,
		{ app_code  => 1,
			api_token => 1,
			api_url   => { default => 'https://cp.pushwoosh.com/json/1.3' },
			furl      => 0,
			error_mode => { default => 'croak' },
		}
	);
	$args{furl} ||= Furl->new;
	my $self = bless {%args}, $class;
	return $self;
}

=head1 METHODS

=cut

my %Errors = (
	createMessage => {
		200 => { 210   => 'Argument error' },
		400 => { 'n/a' => 'Malformed request string' },
		500 => { 500   => 'Internal error' }
	},
);

$Errors{$_} = $Errors{createMessage}
	for (qw(deleteMessage registerDevice unregisterDevice));

my %Message_spec = (

	# Content params
	send_date => { default => 'now',    type     => SCALAR },
	page_id   => { type    => SCALAR,   optional => 1 },
	link      => { type    => SCALAR,   optional => 1 },
	data      => { type    => HASHREF,  optional => 1 },
	platforms => { type    => ARRAYREF, optional => 1 }
	,    # 1 - iOS; 2 - BB; 3 - Android; 4 - Nokia; 5 - Windows Phone; 7 - OS X
	     # Windows Phone 7 params
	wp_type           => { type => SCALAR, optional => 1 },
	wp_backbackground => { type => SCALAR, optional => 1 },
	wp_background     => { type => SCALAR, optional => 1 },
	wp_backtitle      => { type => SCALAR, optional => 1 },
	wp_count          => { type => SCALAR, optional => 1 },

	# Android
	android_icon        => { type => SCALAR,  optional => 1 },
	android_custom_icon => { type => SCALAR,  optional => 1 },
	android_banner      => { type => SCALAR,  optional => 1 },
	android_root_params => { type => HASHREF, optional => 1 },
	android_sound       => { type => SCALAR,  optional => 1 },

	# iOS
	ios_badges      => { type => SCALAR,  optional => 1 },
	ios_root_params => { type => HASHREF, optional => 1 },
	ios_sound       => { type => SCALAR,  optional => 1 },

	# Recipients
	conditions => { type => ARRAYREF, optional => 1 },
	devices    => { type => ARRAYREF, optional => 1 },
	filter     => { type => SCALAR,   optional => 1 },
);

my %Notify_all_spec = (%Message_spec, message => { type => SCALAR },);

my %Notification_spec
	= (%Message_spec, content => { type => SCALAR | HASHREF },);

sub _auth_and_app {
	my $self = shift;
	return ($self->_app, $self->_auth);
}

sub _auth {
	my $self = shift;
	return (auth => $self->{api_token});
}

sub _app {
	my $self = shift;
	return (application => $self->{app_code});
}

=head2 create_message

	my $message_id = $pw->create_message(
		# Content settings
		"send_date" => "now", # YYYY-MM-DD HH => mm  OR 'now'
		"content" =>
			{ # Object( language1 =>  'content1', language2 =>  'content2' ) OR string
			"en" => "English",
			"de" => "Deutsch"
			},
		"page_id" => 39, # Optional. int
		"link" => "http://google.com", # Optional. string
		"data" =>
			{ # HashRef. Will be passed as "u" parameter in the payload
				'foo' => 1,
				'favo_bludd' => 'axlotl_tanks',
				'tleilaxu_master' => 'glossu_rabban',
			},
		"platforms" => [1, 2, 3, 4, 5, 6, 7],   # 1 - iOS; 2 - BB; 3 - Android; 4 - Nokia; 5 - Windows Phone; 7 - OS X

		# WP7 related
		"wp_type" => "Tile", # WP7 notification type. 'Tile' or 'Toast'. Raw notifications are not supported. 'Tile' is default
		"wp_background" => "/Resources/Red.jpg", # WP7 Tile image
		"wp_backbackground" => "/Resources/Green.jpg", # WP7 Back tile image
		"wp_backtitle" => "back title", # WP7 Back tile title
		"wp_count" => 3, # Optional. Integer. Badge for WP7

		# Android related
		"android_banner" => "http://example.com/banner.png",
		"android_custom_icon" => "http://example.com/image.png",
		"android_icon" => "icon.png",
		"android_root_params" => { "key" => "value" }, # custom key-value object. root level parameters for the android payload
		"android_sound" => "soundfile", # Optional. Sound file name in the "res/raw" folder, do not include the extension

		#iOS related
		"ios_badges" => 5, # Optional. Integer. This value will be sent to ALL devices given in "devices"
		"ios_sound" => "soundfile", # Optional. Sound file name in the main bundle of application
		"ios_root_params" => { "content-available" => 1 }, # Optional - root level parameters to the aps dictionary
		
		# Mac related
		"mac_badges" => 3,
		"mac_sound" => "sound.caf",
		"mac_root_params" => { "content-available" => 1 },

		 # Recipients
		"devices" =>
			[ # Optional. If set, message will only be delivered to the devices in the list. Ignored if the applications group is used
			"dec301908b9ba8df85e57a58e40f96f523f4c2068674f5fe2ba25cdc250a2a41"
			],
		"filter" => "FILTER_NAME" # Optional
		"conditions" => [TAG_CONDITION1, TAG_CONDITION2, ..., TAG_CONDITIONN] # Optional
	);

Sends a push notification using the C<createMessage> API call. Croaks on errors.

Parameters:

=over

=item content

The message text to be delivered to the application

=item data

Use only to pass custom data to the application. B<Note> that iOS push
is limited to 256 bytes

=item page_id

HTML page id (created from Application's HTML Pages). Use this if you want to
deliver additional HTML content

=item send_date 

The time at which the message should be sent (UTC) or 'now' to send immediately
(the default)

=item wp_count

Sets the badge for the WP7 platform

=item ios_badges

Sets the badge on the icon for iOS

=item devices (ArrayRef)

Limit only to the specified device IDs

=item ios_root_params

Root level parameters to the aps direction, for example to use with NewsStand
apps

=item conditions

TAG_CONDITION is an array like: [tagName, operator, operand] where

=over 8

=item * C<tagName> String

=item * C<operator> "LTE"|"GTE"|"EQ"|"BETWEEN"|"IN"

=item * C<operand> String|Integer|ArrayRef

=back

Valid operators for String tags:

=over 8

=item * EQ: tag value equals operand. Operand must be a string

=back

Valid operators for Integer tags:

=over 8

=item * GTE: tag value greater than or equal to operand. Operand must be an integer.

=item * LTE: tag value less than or equal to operand. Operand must be an integer.

=item * EQ: tag value equals operand. Operand must be an integer.

=item * BETWEEN: tag value greater than or equal to min value, and tag value is less than or equal to max value. Operand must be an array like: C<[min_value, max_value]>.

=back

Valid operators for ArrayRef tags:

=over 8

=item * IN: Intersect user values and operand. Operand must be an arrayref of strings like: ["value 1", "value 2", "value N"].

=back

B<You cannot use 'filter' and 'conditions' parameters together.>

=back

Returns:

=over

=item The message ID

=back

=cut

sub create_message {
	my $self = shift;
	my %args = validate_with(
		params => \@_,
		spec   => \%Notification_spec,
	);
	my %options = ($self->_auth_and_app, notifications => [\%args]);
	my $res = $self->_post_data(data => \%options, api_method => 'createMessage');
	return $res if !$res->{response}{Messages}[0];
	return $res->{response}{Messages}[0];
}

=head2 delete_message

	$pw->delete_message(message => '78EA-F351D565-9CCA7EED');

Deletes a scheduled message

Parameters:

=over

=item message

The message code obtained from create_message

=back

=cut

sub delete_message {
	my $self    = shift;
	my %args    = validate(@_, { message => { type => SCALAR }, });
	my %options = ($self->_auth, %args);
	$self->_post_data(data => \%options, api_method => 'deleteMessage');
}

=head2 register_device

	$pw->register_device(
		application => 'APPLICATION_CODE',
		push_token => 'DEVICE_PUSH_TOKEN',
		language => 'en', # optional
		hwid => 'hardware id',
		timezone => 3600, # offset in seconds
		device_type => 1,
	);

Registers device for the application

Parameters:

=over

=item push_token

Push token for the device

=item language

Language locale of the device (optional)

=item hwid

Unique string to identify the device (Please note that accessing UDID on iOS is
deprecated and not allowed, one of the alternative ways now is to use MAC
address)

=item timezone

Timezone offset in seconds for the device (optional)

=item device_type

1 - iphone, 2 - blackberry, 3 - android, 4 - nokia, 5 - WP7, 7 - mac

=back

=cut

sub register_device {
	my $self = shift;
	my %args = validate(
		@_,
		{ push_token  => { type => SCALAR },
			hwid        => { type => SCALAR },
			language    => { type => SCALAR, optional => 1 },
			timezone    => { type => SCALAR, optional => 1 },
			device_type => { type => SCALAR },
		}
	);
	my %options = ($self->_app, %args);
	$self->_post_data(data => \%options, api_method => 'registerDevice');
}

=head2 unregister_device

	$pw->unregister_device(hwid => 'hardware device id');

Remove device from the application

Parameters:

=over

=item hwid

Hardware device id used in L</register_device> function call

=back

=cut

sub unregister_device {
	my $self    = shift;
	my %args    = validate(@_, { hwid => { type => SCALAR }, });
	my %options = ($self->_app, %args);
	$self->_post_data(data => \%options, api_method => 'unregisterDevice');
}

=head2 set_tags

	$pw->set_tags(
		hwid => 'device id',
		tags => {
			tag1 => 'konstantinos_atreides',
			tag2 => 42,
			tag3 => 'spice_mining',
			tag4 => 3.14
		}
	);

Sets tags for the device

Parameters:

=over 

=item hwid 

Hardware device id used in L</register_device> function call

=item tags

Tags to set against the device

=back

=cut

sub set_tags {
	my $self = shift;
	my %args = validate(
		@_,
		{ hwid => { type => SCALAR },
			tags => { type => HASHREF },
		}
	);
	my %options = ($self->_app, %args);
	$self->_post_data(data => \%options, api_method => 'setTags');
}

=head2 set_badge

	$pw->set_badge(
		hwid => 'device id',
		badge => 5
	);

B<Note>: Only works on iOS devices

Set current badge value for the device to let auto-incrementing badges work
properly.

Parameters:

=over

=item hwid

Hardware device id used in L</register_device> function call 

=item badge

Current badge on the application to use with auto-incrementing badges

=back

=cut

sub set_badge {
	my $self = shift;
	my %args = validate(
		@_,
		{ hwid  => { type => SCALAR },
			badge => { type => SCALAR },
		}
	);
	my %options = ($self->_app, %args);
	$self->_post_data(data => \%options, api_method => 'setBadge');
}

=head2 push_stat

	$pw->push_stat(
		hwid => 'device id',
		hash => 'hash'
	);

Register push open event.

Parameters:

=over

=item hwid

Hardware device id used in L</register_device> function call 

=item hash

Hash tag received in push notification

=back

=cut

sub push_stat {
	my $self = shift;
	my %args = validate(
		@_,
		{ hwid => { type => SCALAR },
			hash => { type => SCALAR },
		}
	);
	my %options = ($self->_app, %args);
	$self->_post_data(data => \%options, api_method => 'pushStat');
}

=head2 get_nearest_zone

	$pw->get_nearest_zone(
		hwid => 'device id',
		lat => 10.12345,
		lng => 28.12345,
	);

Records device location for geo push notifications

Parameters:

=over

=item hwid 

Hardware device id used in L</register_device> function call 

=item lat

Latitude of the device

=item lng 

Longitude of the device

=back

=cut

sub get_nearest_zone {
	my $self = shift;
	my %args = validate(
		@_,
		{ hwid => { type => SCALAR },
			lat  => { type => SCALAR },
			lng  => { type => SCALAR }
		}
	);
	my %options = ($self->_app, %args);
	$self->_post_data(data => \%options, api_method => 'getNearestZone');
}

sub _url {
	my $self = shift;
	my ($method) = validate_pos(@_, 1);
	return "$self->{api_url}/$method";
}

sub _post_data {
	my $self = shift;
	my %args = validate(
		@_,
		{ data       => 1,
			api_method => 1
		}
	);
	my $data      = shift;
	my $post_body = to_json({ request => $args{data} });
	my $furl      = $self->{furl};
	my $res       = $furl->post($self->_url($args{api_method}),
		['Content-Type' => 'application/json'], $post_body);
	my $json = $res->content;
	my $status = try { from_json($json) }
	catch { croak "Couldn't parse response from api as json: " . $_ };

	my $code = $res->code;
	my $api_code = $status ? $status->{status_code} : undef;

	if ($code == 200 && $api_code == 200) {
		return $status;
	}
	else {
		# error
		return $status if ($self->{error_mode} eq 'manual');
		my $error_msg = $Errors{ $args{api_method} }{$code}{ $api_code || 'n/a' };
		croak "Got error "
			. ($api_code ? "$api_code " : '')
			. qq[from Pushwoosh API method '$args{api_method}']
			. ($error_msg ? ": $error_msg" : '');
	}
}

=head1 TESTING

Since the Pushwoosh API is only available for users of its premium service, the
tests will not run without a valid application code and API token. If you want
to run the tests, you must set two environment variables with your credentials,
eg:

	PUSHWOOSH_APP_CODE=12345-12345 PUSHWOOSH_API_TOKEN=your_api_key perl t/01-simple.t

=head1 AUTHOR

Mike Cartmell, C<< <mike at mikec.me> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mike Cartmell.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
