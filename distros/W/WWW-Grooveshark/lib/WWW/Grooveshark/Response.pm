package WWW::Grooveshark::Response;

use 5.006;
use strict;
use warnings;

=head1 NAME

WWW::Grooveshark::Response - Grooveshark API response message

=head1 VERSION

This document describes C<WWW::Grooveshark::Response> version 0.02 (July 22,
2009).

This module is distributed with L<WWW::Grooveshark> and therefore takes its
version from that module.  The latest version of both components is hosted on
Google Code as part of <http://elementsofpuzzle.googlecode.com/>.  Significant
changes are also contributed to CPAN:
http://search.cpan.org/dist/WWW-Grooveshark/.

=cut

our $VERSION = '0.02';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

Response objects are returned by the API methods of L<WWW::Grooveshark>:

  # some code to prepare $gs
  
  my $response = $gs->search_songs(query => "The Beatles");
  
  if($response->is_fault) {
      print STDERR $response->fault_line;
  }
  else {
      for($response->songs) {
          # do something interesting
      }
  }

=head1 DESCRIPTION

C<WWW::Grooveshark::Response> encapsulates a response message from the
Grooveshark API.  A response consists of a header (sessionID, hostname,
etc.) and either a result (in the case of "success" responses) or a fault code
and message (in case of errors).

Internally, this class is just a C<bless>ed decoding of the JSON response, so
if you're too lazy or stubborn to familiarize yourself with this interface,
you may access the data structure directly like any hashref.

=cut

use Carp;
use Exporter;
use NEXT 0.61; # earlier versions seem to have a NEXT::AUTOLOAD bug

=head1 EXPORTS

None by default.  The ":fault" tag can bring the integer fault constants in
your namespace with: C<use WWW::Grooveshark::Response qw(:fault)>.  The
constants are listed as part of the documentation of the C<fault_code>
method below.

=cut

my %fault = (
	MALFORMED_REQUEST_FAULT             => 1,
	NO_METHOD_FAULT                     => 2,
	MISSING_OR_INVALID_PARAMETERS_FAULT => 4,
	SESSION_FAULT                       => 8,
	AUTHENTICATION_FAULT                => 16,
	AUTHENTICATION_FAILED_FAULT         => 32,
	STREAM_FAULT                        => 64,
	API_KEY_FAULT                       => 128,
	USER_BLOCKED_FAULT                  => 256,
	INTERNAL_FAULT                      => 512,
	SSL_FAULT                           => 1024,
 	ACCESS_RIGHTS_FAULT                 => 2048,
	NO_RESOURCE_FAULT                   => 4096,
	OFFLINE_FAULT                       => 8192,
);
while(my($key, $val) = each %fault) {
	eval "use constant $key => $val;";
}

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (fault => [keys %fault]);
our @EXPORT_OK   = @{$EXPORT_TAGS{fault}};

our $AUTOLOAD;

=head1 CONSTRUCTOR

If you need to "manually" craft an object of this class, this is how.

=over 4

=item WWW::Grooveshark::Response->new( \%OBJECT | %OBJECT )

Builds a L<WWW::Grooveshark::Response> object from the given hashref or hash.

=cut

sub new {
	my $pkg = shift;
	my $self;
	if(1 == scalar(@_)) {
		$self = shift;
		my $ref = ref($self);
		croak "Non-hashref argument passed to one-arg $pkg constructor"
			unless $ref && ($ref eq 'HASH');
	}
	else {
		$self = {@_};
	}
	return bless($self, $pkg);
}

=back

=head1 METHOD AUTOLOADING

More often than not, you will probably be accessing the result element of a
response object.  Because C<$response-E<gt>result('key')> is only marginally
better than C<$response-E<gt>{result}-E<gt>{key}>, this class uses
C<AUTOLOAD>ing to support the terser C<$response-E<gt>key> syntax, as with the
C<songs> "method" in the L</SYNOPSIS>.  This will only work with success
responses, so ask each object if it C<is_fault>.  If the result does not
contain the given key, the usual unknown method handling mechanism will take
over.

=cut

sub AUTOLOAD {
	my $self = shift;
	
	croak 'Not a reference' unless ref($self);

	my($method) = ($AUTOLOAD =~ /(\w*)$/);

	if($self->is_fault) {
		carp $self->fault_line;
		carp 'Uh oh, autoloading on a fault response, this could end badly';
	}
	else {
		my $res = $self->{result};
		if(ref($res)) {
			my %res = %$res;
			return $self->result($method) if exists($res{$method});
		}	
	}

	eval { return $self->NEXT::ACTUAL::AUTOLOAD(@_); };
	croak "Problem while autoloading $AUTOLOAD: $@" if $@;
}

# provided to appease AUTOLOAD
sub DESTROY {}

#=head1 OVERLOADED OPERATIONS
#
#=cut
use overload
	'bool' => sub { return !shift->is_fault; },
;

=head1 METHODS

The following methods exist for all class instances:

=over 4

=item $response->header( $KEY )

Returns the header element corresponding to $KEY.

=cut

sub header {
	return shift->{header}->{shift()};
}

=item $response->sessionID( )

Returns the ID of the session that created this response object.  This is a
shortcut for C<$response-E<gt>header('sessionID')>.

=cut

sub sessionID {
	return shift->header('sessionID');
}

=item $response->is_fault( )

Checks whether this response object represents a fault.

=cut

sub is_fault {
	return exists(shift->{fault});
}

=item $response->result( [ $KEY ] )

Returns the result element corresponding to $KEY, or the whole result part of
the response if no $KEY is specified.  This will probably only give a
meaningful result if C<is_fault> is false.  In C<scalar> context, this method
will return references where applicable.  In list context, it will
dereference arrayrefs and hashrefs before returning them.

=cut

sub result {
	my $res = shift->{result};
	
	# is there an argument? grab the proper key, otherwise the whole result
	my $ret = scalar(@_) ? (ref($res) ? $res->{shift()} : undef) : $res;
	
	# take care of list context
	if(wantarray) {
		my $ref = ref($ret);
		if($ref) {
			return @$ret if $ref eq 'ARRAY';
			return %$ret if $ref eq 'HASH';
		}
	}
	
	return $ret;
}

=item $response->fault( $KEY )

Returns the fault element corresponding to $KEY.  This will only give a
meaningful result if C<is_fault> is true.

=cut

sub fault {
	return shift->{fault}->{shift()};
}

=item $response->fault_code( )

Returns the integer code of the fault represented by this response object.
This is a shortcut for C<$response-E<gt>fault('code')>.  Check Grooveshark's
API for the most up-to-date information about fault codes.  The standard set
at the time of this writing is listed below, along with the corresponding
names for the constants that may be exported by this module (in parentheses).

=over 4

=item 1 Malformed request (C<MALFORMED_REQUEST_FAULT>)

Some part of the request, most likely the parameters, was malformed.

=item 2 No method (C<NO_METHOD_FAULT>)

The requested method does not exist.

=item 4 Missing or invalid parameters (C<MISSING_OR_INVALID_PARAMETERS_FAULT>)

Method parameters were missing or incorrectly formatted.

=item 8 Session (C<SESSION_FAULT>)

Most likely the session has expired, or it failed to start.

=item 16 Authentication (C<AUTHENTICATION_FAULT>)

Authentication is required to access the invoked method.

=item 32 Authentication failed (C<AUTHENTICATION_FAILED_FAULT>)

The supplied user credentials were incorrect.

=item 64 Stream (C<STREAM_FAULT>)

There was an error creating a stream key, or returning a stream server URL.

=item 128 API key (C<API_KEY_FAULT>)

The supplied API key is invalid, or is no longer active.

=item 256 User blocked (C<USER_BLOCKED_FAULT>)

A user's privacy restrictions have blocked access to their account through the API.

=item 512 Internal (C<INTERNAL_FAULT>)

There was an error internal to the API while fulfilling the request.

=item 1024 SSL (C<SSL_FAULT>)

SSL is required to access the requested method.

=item 2048 Access rights (C<ACCESS_RIGHTS_FAULT>)

Your API key does not have the proper access rights to invoke the requested method.

=item 4096 No resource (C<NO_RESOURCE_FAULT>)

Something doesn't exist, perhaps a userID, artistID, etc.

=item 8192 Offline (C<OFFLINE_FAULT>)

The requested method is offline and is temporarily unavailable.

=back

=cut

sub fault_code {
	return shift->fault('code');
}

=item $response->fault_message( )

Returns the contextually customized message of the fault represented by this
response object.  This is a shortcut for C<$response-E<gt>fault('message')>.

=cut

sub fault_message {
	return shift->fault('message');
}

=item $response->fault_details( )

Returns the (possibly undefined) details of the fault represented by this
response object.  This is a shortcut for C<$response-E<gt>fault('details')>.

=cut

sub fault_details {
	return shift->fault('details');
}

=item $response->fault_line( )

Returns an HTTP style status line, containing the fault code and message.

=cut

sub fault_line {
	my $self = shift;
	my $ret = sprintf("%s %s\n", $self->fault_code, $self->fault_message);
	# add details here perhaps?
	return $ret;
}

=back

=cut

1;

__END__

=head1 SEE ALSO

L<WWW::Grooveshark>

=head1 BUGS

Please report them!  The preferred way to submit a bug report for this module
is through CPAN's bug tracker:
http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Grooveshark.  You may
also create an issue at http://elementsofpuzzle.googlecode.com/ or drop me an
e-mail.

=head1 AUTHOR

Miorel-Lucian Palii E<lt>mlpalii@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Miorel-Lucian Palii

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.  See
L<perlartistic>.

=cut
