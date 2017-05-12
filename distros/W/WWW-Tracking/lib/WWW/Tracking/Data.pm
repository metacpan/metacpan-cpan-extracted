package WWW::Tracking::Data;

use warnings;
use strict;

our $VERSION = '0.05';

use base 'Class::Accessor::Fast';

use Digest::MD5 qw(md5_hex);
use Math::BaseCnv 'dec';

our @TRACKING_PROPERTIES = qw(
	hostname
	request_uri
	remote_ip
	user_agent
	referer
	browser_language
	timestamp
	encoding
	screen_color_depth
	screen_resolution
	visitor_id

	pdf_support
	cookie_support

	flash_version
	java_version
	quicktime_version
	realplayer_version
	mediaplayer_version
	gears_version
	silverlight_version
);

__PACKAGE__->mk_accessors(
	@TRACKING_PROPERTIES,
	'_tracking',
	'_gen_new_visitor_id',
);

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new({
		'timestamp' => time(),
		@_
	});
	
	return $self;
}

sub as_hash {
	my $self = shift;
	
	return {
		map  { $_ => $self->$_ }
		grep { defined $self->$_ }
		@TRACKING_PROPERTIES
	};
}

sub from_hash {
	my $class = shift;
	my $data = shift;
	
	my $self = $class->new;
	foreach my $property_name (@TRACKING_PROPERTIES) {
		$self->{$property_name} = $data->{$property_name}
			if (exists $data->{$property_name});
	}
	$self->{'timestamp'} ||= time();
	
	return $self;
}

sub new_visitor_id {
	my $self = shift;
	
	my $gen_new_visitor_id = $self->_gen_new_visitor_id;
	return $gen_new_visitor_id->()
		if $gen_new_visitor_id;
	
	$self->visitor_id(substr(dec(md5_hex($self->user_agent.int(rand(0x7fffffff)))),0,32));
	
	return $self;
}

sub full_request_url {
	my $self = shift;
	return 'http://'.$self->hostname.$self->request_uri;
}

1;


__END__

=head1 NAME

WWW::Tracking::Data - web tracking data object

=head1 SYNOPSIS

	my $tracking_data = WWW::Tracking::Data->new(
		hostname           => 'example.com',
		request_uri        => '/path',
		remote_ip          => '1.2.3.4',
		user_agent         => 'SomeWebBrowser',
		referer            => 'http://search/?q=example',
		browser_language   => 'de-AT',
		timestamp          => 1314712280,
		java_version       => undef,
		encoding           => 'UTF-8',
		screen_color_depth => '24'
		screen_resolution  => '1024x768',
		flash_version      => '9.0',
		visitor_id         => '202cb962ac59075b964b07152d234b70',
	);

=head1 DESCRIPTION

Simple data object for web tracking that allows plugins to add different
serialization and deserialization methods.
See C<WWW::Tracking::Data::Plugin::*> namespace.

=head1 PROPERTIES

	hostname
	request_uri
	remote_ip
	user_agent
	referer
	browser_language
	timestamp
	encoding
	screen_color_depth
	screen_resolution
	visitor_id

	pdf_support
	cookie_support

	flash_version
	java_version
	quicktime_version
	realplayer_version
	mediaplayer_version
	gears_version
	silverlight_version

=head1 METHODS

=head2 new()

Object constructor.

=head2 as_hash()

Clone the data and return as hash.

=head2 from_hash($data)

Create new L<WWW::Tracking::Data> object from has hash. Adds current
C<timestamp> if not provided

=head2 as_*() and from_*()

These functions are injected into L<WWW::Tracking::Data> namespace
via plugins.

=head2 new_visitor_id()

Will generate new random visitor id and store it in C<visitor_id> object
property.

=head2 full_request_url()

Returns string with request URL that includes protocol, hostname and path.

=head1 SEE ALSO

L<WWW::Tracking::Data::Plugin::*> namespace.

=head1 AUTHOR

Jozef Kutej

=cut
