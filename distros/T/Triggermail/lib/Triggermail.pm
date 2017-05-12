package Triggermail;

use strict;
use warnings;

our $VERSION = '1.005';

use constant API_URI => 'https://api.sailthru.com';

use LWP;
use JSON::XS;
use URI::Escape;
use HTTP::Request;
use Digest::MD5 qw( md5_hex);
use Params::Validate qw( :all );
use warnings::register;

sub new {
	my $class = shift;
	my $self  = {
		api_key => shift,
		secret  => shift,
		timeout => shift,
	};
	warnings::warnif( 'deprecated', 'The module Triggermail is now deprecated. Use Sailthru::Client instead.' );
	return bless $self, $class;
}

sub getEmail {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR } );
	my ( $self, $email ) = @_;
	my %data = ( email => $email );
	return $self->_apiCall( 'email', \%data, 'GET' );
}

sub setEmail {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR }, 0, 0, 0 );
	my ( $self, $email, $vars_ref, $lists_ref, $templates_ref ) = @_;
	my %data;
	$data{'email'} = $email;
	$self->_flatten_hash( 'vars',  $vars_ref,  \%data ) if $vars_ref;
	$self->_flatten_hash( 'lists', $lists_ref, \%data ) if $lists_ref;
	$self->_flatten_hash( 'templates', $templates_ref, \%data )
	  if $templates_ref;
	return $self->_apiCall( 'email', \%data, 'POST' );
}

sub send {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR }, { type => SCALAR }, 0, 0, 0 );
	my %data;
	my ( $self, $template, $email, $vars_hash, $options_hash, $schedule_time ) = @_;
	$data{'template'}      = $template;
	$data{'email'}         = $email;
	$data{'schedule_time'} = $schedule_time;
	$self->_flatten_hash( 'vars',    $vars_hash,    \%data ) if $vars_hash;
	$self->_flatten_hash( 'options', $options_hash, \%data ) if $options_hash;
	return $self->_apiCall( 'send', \%data, 'POST' );
}

sub getSend {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR } );
	my ( $self, $send_id ) = @_;
	my %data = ( send_id => $send_id );
	return $self->_apiCall( 'send', \%data, 'GET' );
}

sub scheduleBlast {
	validate_pos(
		@_,
		{ type => HASHREF },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		0
	);
	my ( $self, $name, $list, $schedule_time, $from_name, $from_email, $subject, $content_html, $content_text,
		$options ) = @_;
	my %data = (
		name          => $name,
		list          => $list,
		schedule_time => $schedule_time,
		from_name     => $from_name,
		from_email    => $from_email,
		subject       => $subject,
		content_html  => $content_html,
		content_text  => $content_text
	);
	if ($options) {
		my %merged_hash = ( %data, %{$options} );    #merge in the options hash
		%data = %merged_hash;
	}
	return $self->_apiCall( 'blast', \%data, 'POST' );
}

sub getBlast {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR } );
	my ( $self, $blast_id ) = @_;
	my %data = ( blast_id => $blast_id );
	return $self->_apiCall( 'blast', \%data, 'GET' );
}

sub copyTemplate {
	validate_pos(
		@_,
		{ type => HASHREF },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		{ type => SCALAR },
		0
	);
	my ( $self, $template, $data_feed, $setup, $subject_line, $schedule_time, $list, $options ) = @_;
	my %data = (
		copy_template => $template,
		data_feed_url => $data_feed,
		setup         => $setup,
		name          => $subject_line,
		schedule_time => $schedule_time,
		list          => $list,
	);
	# $self->_flatten_hash( 'options', $options, \%data ) if $options;
	if ($options) {
		# merge in the options hash
		my %merged_hash = ( %data, %{$options} );
		%data = %merged_hash;
	}
	return $self->_apiCall( 'blast', \%data, 'POST' );
}

sub getTemplate {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR } );
	my ( $self, $template ) = @_;
	my %data = ( template => $template );
	return $self->_apiCall( 'template', \%data, 'GET' );
}

sub importContacts {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR }, 0 );
	my ( $self, $email, $password, $include_names ) = @_;
	$include_names = 0 if ( !$include_names );
	my %data = (
		email         => $email,
		password      => $password,
		include_names => $include_names
	);
	return $self->_apiCall( 'contacts', \%data, 'POST' );
}

sub _apiCall {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR }, { type => HASHREF }, { type => SCALAR } );
	my ( $self, $action, $data, $method ) = @_;
	$data->{'api_key'} = $self->{api_key};
	$data->{'format'}  = 'json';
	$data->{'sig'}     = $self->_getSignatureHash($data);
	my $result = $self->_httpRequest( API_URI . "/" . $action, $data, $method );

	my $json    = JSON::XS->new->ascii->pretty->allow_nonref;
	my $decoded = $json->decode( $result->content );
	return $decoded ? $decoded : $result;
}

sub _httpRequest {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR }, { type => HASHREF }, { type => SCALAR } );
	my ( $self, $url, $data, $method ) = @_;
	my $browser = LWP::UserAgent->new;
	$browser->timeout( $self->{timeout} ) if $self->{timeout};
	my $response;
	if ( $method eq 'POST' ) {
		$response = $browser->post( $url, $data );
	}
	else {    #GET
		use URI;
		$url = URI->new($url);
		$url->query_form( %{$data} );
		$response = $browser->get($url);
	}
	if ($response) {
		return $response;
	}
	return;
}

sub _getSignatureHash {
	validate_pos( @_, { type => HASHREF }, { type => HASHREF } );
	my ( $self, $params ) = @_;
	my @values;
	$self->_extractValues( $params, \@values );
	@values = sort @values;
	my $string = $self->{secret} . join( '', @values );
	return md5_hex($string);
}

sub _flatten_hash {
	validate_pos( @_, { type => HASHREF }, { type => SCALAR }, { type => HASHREF }, { type => HASHREF } );
	my ( $self, $name, $nested_hash, $mother_hash ) = @_;
	while ( ( my $key, my $value ) = each %{$nested_hash} ) {
		if (   ref( $nested_hash->{$key} ) eq 'HASH'
			|| ref( $nested_hash->{$key} ) eq 'REF' ) {
			$self->_flatten_hash( $key, $nested_hash->{$key}, $mother_hash );
		}
		else {
			$mother_hash->{ $name . "[" . $key . "]" } = $value;
		}
	}
	return;
}

sub _extractValues {
	validate_pos( @_, { type => HASHREF }, { type => HASHREF }, { type => ARRAYREF } );
	my ( $self, $hash, $array ) = @_;
	while ( ( my $key, my $value ) = each %{$hash} ) {
		if ( ref($value) eq 'HASH' || ref($value) eq 'REF' ) {
			$self->_extractValues( $value, $array );
		}
		else {
			push @{$array}, $value;
		}
	}
	return;
}

1;
__END__

=head1 NAME

Triggermail - Perl module for accessing Sailthru's platform

XXX THIS MODULE IS NOW DEPRECATED. Use Sailthru::Client instead.

=head1 SYNOPSIS

 use Triggermail;
 # You can optionally include a timeout in seconds as a third parameter.
 my $tm = Triggermail->new( 'api_key', 'secret' );
 %vars = (
     name          => "Joe Example",
     from_email    => "approved_email@your_domain.com",
     your_variable => "some_value"
 );
 %options = ( reply_to => "your reply_to header" );
 $tm->send( "template_name", 'example@example.com', \%vars, \%options );

=head1 DESCRIPTION

Triggermail is a Perl module for accessing the Sailthru platform.

XXX THIS MODULE IS NOW DEPRECATED. Use Sailthru::Client instead.

All methods return a hash with return values. Dump the hash or explore the Sailthru API documentation page for what might be returned.

L<http://docs.sailthru.com/api>

Some options might change. Always consult the Sailthru API documentation for the best information.

=head2 METHODS

=over 4

=item C<getEmail( $email )>

=item C<setEmail( $email, \%vars, \%lists, \%templates )>

Takes email as string. vars, lists, templates as hash references.
The vars hash you choose your own key/values for later substitution.
The lists hash should be of format list_name => 1 for subscribed, 0 for unsubscribed.
The templates hash is a list of templates user has opted out, use the key as the template name to signal opt-out.
As always, see the Sailthru documentation for more information.

=item C<send( $template, $email, \%vars, \%options, $schedule_time )>

Send an email to a single address.
Takes template, email and schedule_time as strings. vars, options as hash references.

Options:

=over

=item C<replyto>

override Reply-To header

=item C<test>

send as test email (subject line will be marked, will not count towards stats)

=back

=item C<getSend( $send_id )>

Check if send worked, using send_id returned in the hash from send()

=item C<scheduleBlast( $name, $list, $schedule_time, $from_name, $from_email, $subject, $content_html, $content_text, \%options )>

Schedule an email blast. See the API documentation for more details on what should be passed.

L<http://docs.sailthru.com/api/blast>

=item C<getBlast( $blast_id )>

Check if blast worked, using blast_id returned in the hash from scheduleBlast()
Takes blast_id.

=item C<copyTemplate( $template_name, $data_feed, $setup, $subject_line, $schedule_time, $list, \%options )>

Allows you to use an existing template to send out a blast.

=item C<getTemplate( $template_name )>

Retrieves information about the template

=item C<importContacts( $email, $password )>

Import contacts from major providers.
Takes email, password as strings. By default does not include names. Pass 1 as third argument to include names.

=back

=head1 SEE ALSO

See the Sailthru API documentation for more details on their API.

L<http://docs.sailthru.com/api>

=head1 AUTHOR

Sam Gerstenzang

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sam Gerstenzang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
