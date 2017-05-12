# ==============================================================================
#
# Copyright (C) 2000-2008 University of Manchester 
# WSRF::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# version 0.8.2.7
# Author:         Mark Mc Keown (mark.mckeown@manchester.ac.uk)
#
# Stefan Zasada (sjzasada@lycos.co.uk) did most of the work implementing
# WS-Security - a big thanks goes to Savas Parastatidis
# (http://savas.parastatidis.name/) for helping to get it working with
# .NET.
#
# Contributors:   Andrew Porter, Stephen Pickles,
#                 Sven van den Berghe, Jonathan Chin
#                 Jamie Vicary, Bruno Harbulot
#                 Ivan Porro, Ross Nicoll, Luke @ yahoo
#                 Mary Thompson,  Alex Peeters, Bjoern A. Zeeb
#                 Glen Fu, John Newman, Doug Claar, Edward Kawas
#
# Some parts of the this module are taken from SOAP::Lite -
# here is the required copyright
#
# Copyright (C) 2000-2005 Paul Kulchenko (paulclinger@yahoo.com)
#
#===============================================================================

=pod

=head1 NAME

WSRF::Lite - Implementation of the Web Service Resource Framework

=head1 VERSION

This document refers to version 0.8.3.0 of WSRF::Lite released March, 2011

=head1 SYNOPSIS

This is an implementation of the Web Service Resource Framework (WSRF), 
which is built on SOAP::Lite. It provides support for WSRF, WS-Addressing 
and for digitally signing a SOAP messages using an X.509 certificate 
according to the OASIS WS-Security standard.

=head1 DESCRIPTION

WSRF::Lite consists of a number of classes for developing WS-Resources. 
A WS-Resource is an entity that has a Web service interface defined by
the WSRF family of specifications that maintains state between calls
to the service. 

WSRF::Lite provides a number of ways of implementing 
WS-Resources: one approach uses a process to store the state of the 
WS-Resource, another approach uses a process to store the state of many 
WS-Resources and the last approach uses files to store the state of the
WS-Resources between calls to the WS-Resource. The different approachs have
different benifits, using one process per WS-Resource does not scale very
well and isn't very fault tolerant (eg a machine reboot) but is quite
easy to develop. The approachs are just examples of how to implement a 
WS-Resource, it should be possible to use them as a basis to develop 
tailored solutions for particular applications. For example you could use a 
relational database to store the state of the WS-Resources.

=cut

package WSRF::Lite;

use SOAP::Lite;
use strict;

use vars qw{ $VERSION };

BEGIN {
	$VERSION = '0.8.3.0';
}

# WSRF uses WS-Address headers in the SOAP Header - by default
# SOAP::Lite will croak on these so we change the default in
# SOAP::Lite. The SOAP spec defines the mustUnderstand attribute -
# if an element has this attribute then the service must understand
# what to do with this element. See
# http://www.w3.org/TR/soap12-part1/#soapmu
#
# BUG - should ony accept headers we really do understand
$SOAP::Constants::DO_NOT_CHECK_MUSTUNDERSTAND = 1;

# A singleton class to hold the external socket if there is one.
package WSRF::SocketHolder;

my $oneTrueSelf;

sub instance {
	unless ( defined $oneTrueSelf ) {
		my ( $type, $extern_socket ) = @_;
		my $this = { _socket => $extern_socket };
		$oneTrueSelf = bless $this, $type;
	}
	return $oneTrueSelf;
}

sub close {
	my $self = shift;
	if ( defined $oneTrueSelf ) {
		my $foo =
		  defined( $ENV{SSL} )
		  ? $self->{_socket}->close( SSL_no_shutdown => 1 )
		  : $self->{_socket}->close;
	}
	undef $oneTrueSelf;
}

#===============================================================================
package WSRF::Constants;

=pod

=head1 WSRF::Constants

Defines the set of namespaces used in WSRF::Lite and the directories used to store
the named sockets and data files.

=over 

=item $WSRF::Constants::SOCKETS_DIRECTORY 

Directory to contain the named sockets of the process based WS-Resources.

=item $WSRF::Constants::Data 

Directory used to store files that hold state of WS-Resoures that use file based storage

=item $WSRF::Constants::WSA 

WS-Addressing namespace.

=item $WSRF::Constants::WSRL 

WS-ResourceLifetimes namespace.

=item $WSRF::Constants::WSRP 

WS-ResourceProperties namespace.

=item $WSRF::Constants::WSSG 

WS-ServiceGroup namespace.

=item $WSRF::Constants::WSBF 

WS-BaseFaults namespace.  

=item $WSRF::Constants::WSU 

WS-Security untility namespace.

=item $WSRF::Constants::WSSE 

WS-Security extension namespace.

=item $WSRF::Constants::WSA_ANON 

From the WS-Addressing specification, it is used to indicate
an anonymous return address. If you are using a request-response protocol like HTTP
which uses the same connection for the request and response you use this as the 
ReplyTo address in SOAP WS-Addressing header of the request.  

=back

=cut

#
# Where the named Sockets and ResourceProperty files are stored.
# User can overide these in the Container script.
$WSRF::Constants::SOCKETS_DIRECTORY = "/tmp/wsrf";
$WSRF::Constants::Data         = $WSRF::Constants::SOCKETS_DIRECTORY . "/data/";
$WSRF::Constants::ExternSocket = undef;
%WSRF::Constants::ModuleNamespaceMap = ();

#The set of namespaces used throughout.
#$WSRF::Constants::WSA  = 'http://www.w3.org/2005/03/addressing';
$WSRF::Constants::WSA = 'http://www.w3.org/2005/08/addressing';

#$WSRF::Constants::WSRL = 'http://www.ibm.com/xmlns/stdwip/web-services/WS-ResourceLifetime';
$WSRF::Constants::WSRL = 'http://docs.oasis-open.org/wsrf/rl-2';

#$WSRF::Constants::WSRP = 'http://www.ibm.com/xmlns/stdwip/web-services/WS-ResourceProperties';
$WSRF::Constants::WSRP = 'http://docs.oasis-open.org/wsrf/rp-2';

#$WSRF::Constants::WSSG = 'http://www.ibm.com/xmlns/stdwip/web-services/WS-ServiceGroup';
$WSRF::Constants::WSSG = 'http://docs.oasis-open.org/wsrf/sg-2';

#$WSRF::Constants::WSBF = 'http://www.ibm.com/xmlns/stdwip/web-services/WS-BaseFaults';
$WSRF::Constants::WSBF = 'http://docs.oasis-open.org/wsrf/bf-2';

$WSRF::Constants::WSU =
'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd';
$WSRF::Constants::WSSE =
'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd';

#$WSRF::Constants::WSA_ANON = $WSRF::Constants::WSA.'/role/anonymous';
$WSRF::Constants::WSA_ANON = $WSRF::Constants::WSA . '/anonymous';

$WSRF::Constants::DS = 'http://www.w3.org/2000/09/xmldsig#';

#===============================================================================
# We override SOAP::SOM to store the raw XML from a SOAP message - this class is
# used by the WSRF::Deserializer below. SOAP::Lite does not provide you with
# access to the raw XML of a SOAP message (It was on the SOAP::Lite TODO list)
# - here we override the SOAP::SOM module to provide access to the raw XML -
# we override the SOAP::Deserializer which returns the SOAP::SOM object to
# make sure that it actually keeps the XML

package WSRF::SOM;

=pod

=head1 WSRF::SOM

Extends SOAP::SOM with one extra method "raw_xml".

=head2 METHODS

=over

=item raw_xml

Returns the raw XML of a message, useful if you want to parse the message using some
other tool than provided with SOAP::Lite: 

  my $xml = $som->raw_xml;

=back

=cut

use strict;
use vars qw(@ISA);

@ISA = qw(SOAP::SOM);

# function to return raw XML
sub raw_xml {
	my $self = shift;
	return $self->{_xml};
}

#===============================================================================
# We override the SOAP::Serializer to store the raw XML of the SOAP message.
# Normally a SOAP::Lite service cannot access the raw XML of a request - this
# is sometimes useful for the Service developer who might want to use
# XML DOM instead of SOM. The Deserializer returns a WSRF::SOM object - wich
# we have defined above.
package WSRF::Deserializer;

=pod

=head1 WSRF::Deserializer

Overrides SOAP::Deserializer to return a WSRF::SOM object, which includes the raw XML 
of the message, from the deserialize method.

=head2 METHODS

The methods are the same as SOAP::Deserializer. 

=cut

use strict;

use vars qw(@ISA);

@ISA = qw(SOAP::Deserializer);

#This is very similar to the SOAP::Deserializer only a couple of lines are added
# Copyright (C) 2000-2005 Paul Kulchenko (paulclinger@yahoo.com)
sub deserialize {
	SOAP::Trace::trace('()');
	my $self = shift->new;

	# initialize
	$self->hrefs( {} );
	$self->ids(   {} );

	# TBD: find better way to signal parsing errors
	# This is returning a parsed body, however, if the message was mime
	# formatted, then the self->ids hash should be populated with mime parts
	# as will the self->mimeparser->parts array
	my $parsed =
	  $self->decode( $_[0] );    # TBD: die on possible errors in Parser?
	  # Thought - decode should return an ARRAY which may contain MIME::Entities
	  # then the SOM object that is created and returned from this will know how
	  # to parse them out

	# Having this code here makes multirefs in the Body work, but multirefs
	# that reference XML fragments in a MIME part do not work.
	if ( keys %{ $self->ids() } ) {
		$self->traverse_ids($parsed);
	} else {
		$self->ids($parsed);
	}
	$self->decode_object($parsed);

	# these are the changes from SOAP::Deserializer
	# otherwise the code is the same. We simply add the raw XML to
	# the som hash
	my $som = WSRF::SOM->new($parsed);
	$som->{'_xml'} = $_[0];

	# first check if MIME parser has been initialized
	# simple $self->mimeparser() call doesn't work because of
	# "lazy initialization" --PK
	if ( defined $self->{'_mimeparser'} && $self->mimeparser->parts ) {

		# This seems like an unnecessary copy... does SOAP::SOM have a handle on
		# the SOAP::Lite->mimeparser instance so that I can skip this?
		$som->{'_parts'} = $self->mimeparser->parts;
	}
	return $som;
}

#===============================================================================
# We override the SOAP::Serializer to add extra namespaces to the SOAP element
# - these are namesapace we will use a lot wsrl, wsrp, wsa. These are placed
# in any SOAP message we return from the service. The user can use the
# prefixs wsrl, wsrp and wsa and not have to worry about defining the
# namespaces
#
# WSRF::WSRFSerializer is were the message is signed - signing is tricky
# because we have to create the XML before we sign it, so the process of
# signing a SOAP message requires two passes through the serializer. The
# first pass (std_envelope) creates the SOAP message, the second actually
# signs it. THIS IS NOT EFFICIENT BUT WHO CARES?!
package WSRF::WSRFSerializer;

=pod

=head1 WSRF::WSRFSerializer

Overrides SOAP::Serializer. This class extends the SOAP::Serializer class which creates
the XML SOAP Enevlope. WSRF::WSRFSerializer overrides the "envelope" method so that it
adds the WSRF, WS-Addressing and WS-Security namespaces to the SOAP Envelope, it also
where the message signing happens. The XML SOAP message has to be created before it
can be signed.

=head2 METHODS

The methods are the same as SOAP::Serializer, the "envelope" method is overridden to 
include the extra namespaces and to digitally sign the SOAP message if required.

=cut

use vars qw(@ISA);

@ISA = qw(SOAP::Serializer);

# This function is the same as SOAP::Serializer::envelope except that
# it adds an extra attribute (wsu:Id="myBody") into the Body element -
# this is used by WS-Security to identify the bits of a message that
# have been signed.
#
# We also add extra namespaces for WSRF and WSA into the SOAP Envelope
# element so we do not need to declare them in the message itself
# Copyright (C) 2000-2005 Paul Kulchenko (paulclinger@yahoo.com)
sub old_envelope {
	SOAP::Trace::trace('()');
	my $self = shift->new;

	$self->autotype(0);
	$self->attr(
				 {
				   'xmlns:wsa'  => $WSRF::Constants::WSA,
				   'xmlns:wsrl' => $WSRF::Constants::WSRL,
				   'xmlns:wsrp' => $WSRF::Constants::WSRP,
				   'xmlns:wsu'  => $WSRF::Constants::WSU,
				   'xmlns:wsse' => $WSRF::Constants::WSSE
				 }
	);

	my $type = shift;
	my ( @parameters, @header );
	for (@_) {

		# Find all the SOAP Headers
		if ( defined($_) && ref($_) && UNIVERSAL::isa( $_ => 'SOAP::Header' ) )
		{
			push( @header, $_ );

			# Find all the SOAP Message Parts (attachments)
		} elsif (    defined($_)
				  && ref($_)
				  && $self->context
				  && $self->context->packager->is_supported_part($_) )
		{
			$self->context->packager->push_part($_);

			# Find all the SOAP Body elements
		} else {
			push( @parameters, $_ );
		}
	}
	my $header = @header ? SOAP::Data->set_value(@header) : undef;
	my ( $body, $parameters );
	if ( $type eq 'method' || $type eq 'response' ) {
		SOAP::Trace::method(@parameters);

		my $method = shift(@parameters);

		#         or die "Unspecified method for SOAP call\n";

		$parameters = @parameters ? SOAP::Data->set_value(@parameters) : undef;
		if ( !defined($method) ) {
		} elsif ( UNIVERSAL::isa( $method => 'SOAP::Data' ) ) {
			$body = $method;
		} elsif ( $self->use_prefix ) {
			$body = SOAP::Data->name($method)->uri( $self->uri );
		} else {
			$body =
			  SOAP::Data->name($method)->attr( { 'xmlns' => $self->uri } );

#$body = SOAP::Data->name($method)->uri($self->uri); # original return before use_prefix
		}

		# This is breaking a unit test right now...
		$body->set_value(
				   SOAP::Utils::encode_data( $parameters ? \$parameters : () ) )
		  if $body;
	} elsif ( $type eq 'fault' ) {
		SOAP::Trace::fault(@parameters);
		$body =
		  SOAP::Data->name(
						   SOAP::Utils::qualify( $self->envprefix => 'Fault' ) )

		  # parameters[1] needs to be escaped - thanks to aka_hct at gmx dot de
		  # commented on 2001/03/28 because of failing in ApacheSOAP
		  # need to find out more about it
		  # -> attr({'xmlns' => ''})
		  ->value(
			\SOAP::Data->set_value(
				SOAP::Data->name(
								  faultcode => SOAP::Utils::qualify(
											  $self->envprefix => $parameters[0]
								  )
				  )->type(""),
				SOAP::Data->name(
					   faultstring => SOAP::Utils::encode_data( $parameters[1] )
				  )->type(""),
				defined( $parameters[2] )
				? SOAP::Data->name(
					detail => do {
						my $detail = $parameters[2];
						ref $detail ? \$detail : $detail;
					  }
				  )
				: (),
				defined( $parameters[3] )
				? SOAP::Data->name( faultactor => $parameters[3] )->type("")
				: (),
			)
		  );
	} elsif ( $type eq 'freeform' ) {
		SOAP::Trace::freeform(@parameters);
		$body = SOAP::Data->set_value(@parameters);
	} elsif ( !defined($type) ) {

	 # This occurs when the Body is intended to be null. When no method has been
	 #  passed in of any kind.
	} else {
		die "Wrong type of envelope ($type) for SOAP call\n";
	}

	$self->seen( {} );    # reinitialize multiref table
	                      # Build the envelope
	  # Right now it is possible for $body to be a SOAP::Data element that has not
	  # XML escaped any values. How do you remedy this?
	my ($encoded) = $self->encode_object(
		  SOAP::Data->name(
			  SOAP::Utils::qualify( $self->envprefix => 'Envelope' ) =>
				\SOAP::Data->value(
				  (
					$header ? SOAP::Data->name(
						 SOAP::Utils::qualify( $self->envprefix => 'Header' ) =>
						   \$header
					  ) : ()
				  ),
				  (
					$body
					? SOAP::Data->name(
						   SOAP::Utils::qualify( $self->envprefix => 'Body' ) =>
							 \$body
					  )->attr( { 'wsu:Id' => $WSRF::WSS::ID{myBody}  } )
					: SOAP::Data->name(
							  SOAP::Utils::qualify( $self->envprefix => 'Body' )
					  )->attr( { 'wsu:Id' => $WSRF::WSS::ID{myBody}  } )
				  ),
				)
			)->attr( $self->attr )
	);
	$self->signature( $parameters->signature ) if ref $parameters;

	# IMHO multirefs should be encoded after Body, but only some
	# toolkits understand this encoding, so we'll keep them for now (04/15/2001)
	# as the last element inside the Body
	#      v -------------- subelements of Envelope
	#          vv -------- last of them (Body)
	#                v --- subelements
	push( @{ $encoded->[2]->[-1]->[2] }, $self->encode_multirefs )
	  if ref $encoded->[2]->[-1]->[2];

	# Sometimes SOAP::Serializer is invoked statically when there is no context.
	# So first check to see if a context exists.
	# TODO - a context needs to be initialized by a constructor?
	if ( $self->context && $self->context->packager->parts ) {

	# TODO - this needs to be called! Calling it though wraps the payload twice!
	# return $self->context->packager->package($self->xmlize($encoded));
	}
	return $self->xmlize($encoded);
}

sub std_envelope {
	SOAP::Trace::trace('()');
	my $self = shift->new;
	my $type = shift;

	$self->autotype(0);
	$self->attr(
				 {
				   'xmlns:wsa'  => $WSRF::Constants::WSA,
				   'xmlns:wsrl' => $WSRF::Constants::WSRL,
				   'xmlns:wsrp' => $WSRF::Constants::WSRP,
				   'xmlns:wsu'  => $WSRF::Constants::WSU,
				   'xmlns:ds'   => $WSRF::Constants::DS,
				   'xmlns:wsse' => $WSRF::Constants::WSSE
				 }
	);

	my ( @parameters, @header );
	for (@_) {

		# Find all the SOAP Headers
		if ( defined($_) && ref($_) && UNIVERSAL::isa( $_ => 'SOAP::Header' ) )
		{
			push( @header, $_ );

			# Find all the SOAP Message Parts (attachments)
		} elsif (    defined($_)
				  && ref($_)
				  && $self->context
				  && $self->context->packager->is_supported_part($_) )
		{
			$self->context->packager->push_part($_);

			# Find all the SOAP Body elements
		} else {
			push( @parameters, SOAP::Utils::encode_data($_) );
		}
	}
	my $header = @header ? SOAP::Data->set_value(@header) : undef;
	my ( $body, $parameters );
	if ( $type eq 'method' || $type eq 'response' ) {
		SOAP::Trace::method(@parameters);

		my $method = shift(@parameters);

		#	  or die "Unspecified method for SOAP call\n";

		$parameters = @parameters ? SOAP::Data->set_value(@parameters) : undef;
		if ( !defined($method) ) {
		} elsif ( UNIVERSAL::isa( $method => 'SOAP::Data' ) ) {
			$body = $method;
		} elsif ( $self->use_default_ns ) {
			if ( $self->{'_ns_uri'} ) {
				$body =
				  SOAP::Data->name($method)
				  ->attr( { 'xmlns' => $self->{'_ns_uri'}, } );    
			} else {
				$body = SOAP::Data->name($method);
			}
		} else {

 # Commented out by Byrne on 1/4/2006 - to address default namespace problems
 #      $body = SOAP::Data->name($method)->uri($self->{'_ns_uri'});
 #      $body = $body->prefix($self->{'_ns_prefix'}) if ($self->{'_ns_prefix'});

	   # Added by Byrne on 1/4/2006 - to avoid the unnecessary creation of a new
	   # namespace
	   # Begin New Code (replaces code commented out above)
			$body = SOAP::Data->name($method);
			my $pre = $self->find_prefix( $self->{'_ns_uri'} );
			$body = $body->prefix($pre) if ( $self->{'_ns_prefix'} );

			# End new code

		}

# This is breaking a unit test right now...
#$body->set_value(SOAP::Utils::encode_data($parameters ? \$parameters : ())) if $body;
		$body->set_value( $parameters ? \$parameters : () ) if $body;
	} elsif ( $type eq 'fault' ) {
		SOAP::Trace::fault(@parameters);
		$body =
		  SOAP::Data->name(
						   SOAP::Utils::qualify( $self->envprefix => 'Fault' ) )

		  # parameters[1] needs to be escaped - thanks to aka_hct at gmx dot de
		  # commented on 2001/03/28 because of failing in ApacheSOAP
		  # need to find out more about it
		  # -> attr({'xmlns' => ''})
		  ->value(
			\SOAP::Data->set_value(
				SOAP::Data->name(
								  faultcode => SOAP::Utils::qualify(
											  $self->envprefix => $parameters[0]
								  )
				  )->type(""),
				SOAP::Data->name(
					   faultstring => SOAP::Utils::encode_data( $parameters[1] )
				  )->type(""),
				defined( $parameters[2] )
				? SOAP::Data->name(
					detail => do {
						my $detail = $parameters[2];
						ref $detail ? \$detail : $detail;
					  }
				  )
				: (),
				defined( $parameters[3] )
				? SOAP::Data->name( faultactor => $parameters[3] )->type("")
				: (),
			)
		  );
	} elsif ( $type eq 'freeform' ) {
		SOAP::Trace::freeform(@parameters);
		$body = SOAP::Data->set_value(@parameters);
	} elsif ( !defined($type) ) {

	 # This occurs when the Body is intended to be null. When no method has been
	 # passed in of any kind.
	} else {
		die "Wrong type of envelope ($type) for SOAP call\n";
	}

	$self->seen( {} );    # reinitialize multiref table
	                      # Build the envelope
	  # Right now it is possible for $body to be a SOAP::Data element that has not
	  # XML escaped any values. How do you remedy this?
	my ($encoded) = $self->encode_object(
		  SOAP::Data->name(
			  SOAP::Utils::qualify( $self->envprefix => 'Envelope' ) =>
				\SOAP::Data->value(
				  (
					$header ? SOAP::Data->name(
						 SOAP::Utils::qualify( $self->envprefix => 'Header' ) =>
						   \$header
					  ) : ()
				  ),
				  (
					$body
					? SOAP::Data->name(
						   SOAP::Utils::qualify( $self->envprefix => 'Body' ) =>
							 \$body
					  )->attr( { 'wsu:Id' => $WSRF::WSS::ID{myBody}  } )
					: SOAP::Data->name(
							  SOAP::Utils::qualify( $self->envprefix => 'Body' )
					  )->attr( { 'wsu:Id' => $WSRF::WSS::ID{myBody}  } )
				  ),
				)
			)->attr( $self->attr )
	);
	$self->signature( $parameters->signature ) if ref $parameters;

	# IMHO multirefs should be encoded after Body, but only some
	# toolkits understand this encoding, so we'll keep them for now (04/15/2001)
	# as the last element inside the Body
	#                 v -------------- subelements of Envelope
	#                      vv -------- last of them (Body)
	#                            v --- subelements
	push( @{ $encoded->[2]->[-1]->[2] }, $self->encode_multirefs )
	  if ref $encoded->[2]->[-1]->[2];

	# Sometimes SOAP::Serializer is invoked statically when there is no context.
	# So first check to see if a context exists.
	# TODO - a context needs to be initialized by a constructor?
	if ( $self->context && $self->context->packager->parts ) {

	# TODO - this needs to be called! Calling it though wraps the payload twice!
	#  return $self->context->packager->package($self->xmlize($encoded));
	}
	return $self->xmlize($encoded);
}

# This function is called whenever a SOAP message is created using the
# WSRF::Serializer. First it calls std_envelope to create the SOAP message,
# then it takes this message and signs the bits of the message that should
# be signed and adds the extra signing information into the message
sub envelope {
	my $self = shift @_;

	#create an envelope - this returns raw XML
	my $envelope = $self->std_envelope(@_);

	#if the user has defined these env then he wants the envlope signed -
	#we take the envelope  in the above step and do the necessary
	if ( defined( $ENV{WSS_SIGN} ) ) {

		#call the function to sign the envlope - returns the Header and Body
		#as raw XML
		my ( $header, $Body ) = WSRF::WSS::sign($envelope);

		#returns the body and header as XMl - the header does not have its top
		#and tail ie. the <soap:Header> and </soap:Header> are missing so we
		#add them
		my ($encoded) = $self->encode_object(
			 SOAP::Data->name(
				 SOAP::Utils::qualify( $self->envprefix => 'Envelope' ) =>
				   \SOAP::Data->value(
					 SOAP::Data->name(
						 SOAP::Utils::qualify( $self->envprefix => 'Header' ) =>
						   \SOAP::Data->value($header)->type('xml')
					 ),
					 SOAP::Data->value($Body)->type('xml')
				   )
			   )->attr( $self->attr )
		);

		#$encoded is a SOAP::data - we convert it to XML
		$envelope = $self->xmlize($encoded);
	}

	return $envelope;
}

#===============================================================================
# Take a SOAP::Data object and serialise it - if we are given a SOAP::SOM or
# SOAP::Data object and we want to get simple XML without all the SOAP stuff
# added we use this class. Useful if the user wants to use DOM instead of
# SOM to handle the object.
#
# This is useful if we have a SOAP::Data or SOAP::SOM object which we want to
# convert to XML (e.g. to write to a file) without all the SOAP crap.
# Other Perl packages will do this for you (convert a Perl object to XML)
# but I want to reuse the SOAP::Lite stuff.
#
package WSRF::SimpleSerializer;

=pod

=head1 WSRF::SimpleSerializer

Overrides SOAP::Serializer. This is helper class that is based in SOAP::Serializer,
it will serialize a SOAP::Data object into XML but without adding the SOAP namespaces
etc. It is useful if you want to extra some simple XML from a SOM object, retrieve
a SOAP::Data object from the SOM then serialize it to simple XML.

 my $serializer = WSRF::SimpleSerializer->new();
 my $xml = $seriaizer->serialize( $som->dataof('/Envelope/Body/[1]') );

=head2 METHODS

All methods are the same as SOAP::Serializer except "serialize".

=over

=item serialize

This method from SOAP::Serializer is overridden so that it does not add the SOAP namepaces
to the XML or set the types of the elements in the XML.

  sub serialize {
     my $self = shift @_;
     $self->autotype(0);
     $self->namespaces({});
     $self->encoding(undef);
     $self->SUPER::serialize(@_);
  }

=back

=cut

use strict;
use vars qw(@ISA);

@ISA = qw(SOAP::Serializer);    # derived from the SOAP::Serializer

sub typecast { return; }

#we override the serialize funtion, switching of lots of stuff
sub serialize {
	my $self = shift @_;
	$self->autotype(0);
	$self->namespaces( {} );
	$self->encoding(undef);
	$self->SUPER::serialize(@_);
}

#===============================================================================
# The Container that handles all the connections for us.
#
# All incoming messages arrive at the handle function -
# in previous versions of WSRF::Lite function that was
# way too big. Now we have a hash which allows use to
# map messages to functions depending on the destination
# URI. This makes it easy to add handlers for messages.
#
# BUG - should be Object Orientated
#
package WSRF::Container;

=pod

=head1 WSRF::Container

WSRF::Container handles incoming messages and dispatchs them to the appropriate 
WS-Resource.  

=head2 METHODS

=over

=item handle

Takes a HTTP Request object and dispatchs it to the appropriate WS-Resource,  
handle returns a HTTP Response object from the WS-Resource which should be 
returned to the client.

=back

=cut

use IO::Socket;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;

# This hash maps incoming messages to functions - the mapping is done
# using the RequestURI in the HTTP Header. It should be very easy to
# add a custom handler!
# The key in this hash is used in a regular expression - it is matched
# to the start of the RequestURI - eg
# http://vermont.mvc.mcc.ac.uk/WSRF/foobar  -> WSRF
# (/WSRF/foobar is the RequestURI)
%WSRF::Container::HandlerMap = (
						'WSRF'         => \&WSRF::Container::WSRFHandler,
						'Session'      => \&WSRF::Container::SessionHandler,
						'MultiSession' => \&WSRF::Container::MultiSessionHandler
);

# All messages should pass through this handle function - $r is a
# HTTP::Request Object
sub handle {
	my ( $r, $socket ) = @_;

	#need to record if this process has an open socket with the world
	#- if we fork we might need to close it
	$WSRF::Constants::ExternSocket = WSRF::SocketHolder->instance($socket);

	if ( !$r ) {
		print STDERR "$$ WSRF::Container HTTP::Request not defined!";
		return;
	}

	my $Path = $r->uri->path;
	if ( $Path =~ m/\.{2,}/og ) {
		print STDERR
		  "$$ WSRF::Container Path $Path contains unacceptable charactors.\n";
		my $fail = new HTTP::Response(RC_NOT_FOUND);
		$fail->header( 'Content-Type' => 'text/xml' );
		$fail->content("Path $Path contains unacceptable charactors.\n");
		return $fail;
	}

	my ($response);

	#walk through the hash until we find a handler for this function - we put
	#the key between / and / and do a reg expression match
	my $found = undef;
  LINE: foreach my $key ( keys %WSRF::Container::HandlerMap ) {
		if ( $Path =~ m/^\/$key\// ) {
			$found = "TRUE";
			print STDERR "$$ WSRF::Container Using $key Handler\n";
			$response = $WSRF::Container::HandlerMap{$key}->($r);
			last LINE;
		}
	}

	#no handler found - return a 404 HTTP error message
	if ( !$found ) {
		$response = HTTP::Response->new(404);
	}

	return $response;
}

# handles messages with URI http://blah.com/WSRF/
# this maps to WS-Resources that use a process to manage the
# state of a WS-Resource, one process per WS-Resource. This
# functions sends the message down a UNIX socket to the process
sub WSRFHandler {
	my $request = shift @_;

	#Only Handle GET and POST
	return HTTP::Response->new(RC_FORBIDDEN)
	  if (    $request->method ne 'POST'
		   && $request->method ne 'GET'
		   && $request->method ne 'DELETE'
		   && $request->method ne 'PUT' );

	print STDERR "$$ WSRFHandler called\n";
	my $Path = $request->uri->path;

	#strip extra '/' at start of URL
	$Path =~ s/^\/+//o;

	#remeber the Path - we will put this in our responses so clients
	#will know who sent them the message - part of WS-Addressing
	$ENV{FROM} = $ENV{URL} . $Path;

	#split up Path part of URL - we multiplex on the first part (the base)
	#the module name is the last part
	my @PathArray  = split( /\//, $Path );
	my $ID         = pop @PathArray;
	my $base       = $PathArray[0];
	my $ModuleName = pop @PathArray;
	print "$$ ModuleName= $ModuleName\n";
	my $Directory = join '/', @PathArray;

	#this is the absolute path now
	$Directory = $ENV{WSRF_MODULES} . "/" . $Directory;
	print STDERR "Directory= $Directory\n";

	$Path = $ENV{WSRF_MODULES} . "/" . $Path;

	#check the ID is safe - we do not accept dots,
	#all paths will be relative to $ENV{WRF_MODULES}
	#only allow alphanumeric, underscore and hyphen
	if ( $ID !~ m/^([-\w]+)$/ && $ID !~ m/^$ModuleName\.(xsl|js|css|svg)$/ ) {
		print STDERR "$$ Bad ID $ID\n";
		my $fail = new HTTP::Response(RC_BAD_REQUEST);
		$fail->header( 'Content-Type' => 'text/xml' );
		$fail->content(
						SOAP::Serializer->fault(
								'Bad WS-Resource Identifier',
								"WS-Resource identifier contains bad charactors"
						)
		);

		return $fail;
	}

	my ($PUT);
	if ( $request->method eq 'PUT' ) {
		$PUT = 1;

		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $xml = $request->content;

		print STDERR "$$ Attempt to PUT\n";

		$xml =~ s/^<\?xml[\s\w\.\-].*\?>\n?//o;
		print STDERR "$$ >>>xml>>>\n$xml\n<<<xml<<<\n";

		my $data =
		  SOAP::Data->name('PutResourcePropertyDocument')->prefix('wsrp')
		  ->attr( { 'xmlns:wsrp' => $WSRF::Constants::WSRP } )
		  ->value( \SOAP::Data->value($xml)->type('xml') );

		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		print "$$ >>>envelope>>>\n$envelope\n<<<envelope<<<\n";
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" =>
						 "$WSRF::Constants::WSRP/PutResourcePropertyDocument" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	print "$$ ID= $ID\n";
	my ($GET);
	if ( $request->method eq 'GET' ) {

		#does the client just want the WSDL/XSL/CSS for service
		if ( $request->uri->query eq 'WSDL' ) {
			my $resp = GetWSDL($request);
			return $resp;
		} elsif ( $ID =~ m/^$ModuleName\.(xsl|css|js|svg)$/ )

		  #looking for xsl or css or js
		{
			print "$$ Getting $ID file\n";
			my $resp = HTTP::Response->new();
			my $file = $Directory . "/" . $ID;
			print "$$ File to open is $file\n";
			if ( !( -f $file ) || !( -r $file ) ) {
				$resp->code(404);
				return $resp;
			}
			open FILE, "< $file" or die "$$ Could not open $file";
			my $xsl = join "", <FILE>;
			close FILE or die "Could not close $file file";
			$resp->header( 'Content-Type' => 'text/xml' )
			  if ( $ID =~ m/\.xsl$/ );
			$resp->header( 'Content-Type' => 'text/css' )
			  if ( $ID =~ m/\.css$/ );
			$resp->header( 'Content-Type' => 'text/javascript' )
			  if ( $ID =~ m/\.js$/ );
			$resp->header( 'Content-Type' => 'text/xml' )
			  if ( $ID =~ m/\.svg$/ );

			$resp->content($xsl);
			return $resp;
		}

		#wants ResourceProperties
		$GET = 1;
		my $data =
		  SOAP::Data->name('GetResourcePropertyDocument')->prefix('wsrp')
		  ->attr( { 'xmlns:wsrp' => $WSRF::Constants::WSRP } );
		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" =>
						 "$WSRF::Constants::WSRP/GetResourcePropertyDocument" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	if ( $request->method eq 'DELETE' ) {
		my $data =
		  SOAP::Data->name('Destroy')->prefix('wsrl')
		  ->attr( { 'xmlns:wsrl' => $WSRF::Constants::WSRL } );
		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" => "$WSRF::Constants::WSRL/Destroy" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	my $rend = $WSRF::Constants::SOCKETS_DIRECTORY . "/" . $ID;

	#check that the Socket exists for the requested Grid Service
	if ( !-S $rend ) {
		print STDERR "$$ UNIX Socket $rend does not exist\n";
		my $fail = new HTTP::Response(RC_NOT_FOUND);
		$fail->header( 'Content-Type' => 'text/xml' );
		$fail->content(
						SOAP::Serializer->fault(
												 'No such WS-Resource type',
												 "Check Endpoint of service"
						)
		);

		return $fail;
	}

	print STDERR "$$ $Path Child $$ Starting Processing\n";
	print STDERR "$$ Client Rendezvous $rend\n";

	#open a socket to the GS
	my $MyFH = IO::Socket::UNIX->new(
									  Peer    => "$rend",
									  Type    => SOCK_STREAM,
									  Timeout => 10
	  )
	  or die SOAP::Fault->faultcode("Container Fault")
	  ->faultstring("Container Failure - Socket problem $!");
	print STDERR "$$ Client Socket $MyFH\n";

	#if using SSL add the extra information to the HTTP request
	# we stick it into the HTTP Header
	if ( defined( $ENV{SSL_CLIENT_DN} ) ) {
		$request->header( 'Client-SSL-Cert-Subject' => "$ENV{SSL_CLIENT_DN}" );
		$request->header(
						'Client-SSL-Cert-Issuer' => "$ENV{SSL_CLIENT_ISSUER}" );
	}

	#send down socket and wait for response
	my $out = print $MyFH ( $request->as_string() );

	if ( !defined($out) ) { print STDERR "$$ Could not write to $MyFH\n" }

	#read the response from the Socket and turn it into a
	#HTTP::Response
	my $resp = WSRF::Daemon::ResponseHandler($MyFH);
	$MyFH->close;
	print STDERR "$$ $Path Processing Finished\n";

	#   print STDERR "$$ >>>out>>>\n".$resp->content."\n<<<out<<<\n";

	if ( $GET || $PUT )    #Original Request was a GET
	{
		$resp =
		  WSRF::Container::getProperties( $resp, $Directory, $ModuleName );
		$resp->header( "Pragma" => "no-cache" );
		$resp->header(
					"Cache-Control" => "no-cache, max-age=1, must-revalidate" );
	}
	return $resp;
}

# This function handles messages that have a URI like
# http://blah.com/Session/stuff
# Session WS-Resources store their state in a DB/filesystem etc...
# this function loads the function that loads the code to access
# the state and process the message
sub SessionHandler {
	my $request = shift @_;
	print STDERR "$$ SessionHandler called\n";

	#Only Handle GET and POST
	return HTTP::Response->new(RC_FORBIDDEN)
	  if (    $request->method ne 'POST'
		   && $request->method ne 'GET'
		   && $request->method ne 'DELETE'
		   && $request->method ne 'PUT' );

	my $Path = $request->uri->path;

	#strip extra '/' at start of URL
	$Path =~ s/^\/+//o;

	#remeber the Path - we will put this in our responses so clients
	#will know who sent them the message - part of WS-Addressing
	$ENV{FROM} = $ENV{URL} . $Path;

	#split up Path part of URL - we multiplex on the first part (the base)
	#the module name is the last part
	my @PathArray = split( /\//, $Path );
	my $ID = pop @PathArray;
	my ($module);
	if (    $ID =~ /\d+-?d*/o
		 || $ID =~ /^\w+\.(js|xsl|css|svg)$/ )    #a resource identifier
	{
		$module = pop @PathArray;
	} else {
		$module = $ID;
	}
	$ENV{ID} = $ID;

	my $base              = $PathArray[0];
	my $RelativeDirectory = join '/', @PathArray;

	#this is the absolute path now

	my $Directory = $ENV{WSRF_MODULES} . "/" . $RelativeDirectory;
	print STDERR "$$ Directory to modules $Directory\n";

	my $tmpPath = $Directory . '/' . $module . ".pm";
	print STDERR "$$ Path to module $tmpPath\n";
	if ( !-f $tmpPath ) {
		print STDERR "$$ ERROR $tmpPath no such file\n";
		my $fail = new HTTP::Response(RC_OK);
		$fail->header( 'Content-Type' => 'text/xml' );

		#$fail->content("GS::$Path No Such service\n");
		$fail->content(
						SOAP::Serializer->fault(
									   'No Service', "Check Endpoint of Service"
						)
		);
		return $fail;
	}

	my ($PUT);
	if ( $request->method eq 'PUT' ) {
		$PUT = 1;

		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $xml = $request->content;

		print STDERR "$$ Attempt to PUT\n";

		$xml =~ s/^<\?xml[\s\w\.\-].*\?>\n?//o;
		print STDERR "$$ >>>xml>>>\n$xml\n<<<xml<<<\n";

		my $data =
		  SOAP::Data->name('PutResourcePropertyDocument')->prefix('wsrp')
		  ->attr( { 'xmlns:wsrp' => $WSRF::Constants::WSRP } )
		  ->value( \SOAP::Data->value($xml)->type('xml') );

		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		print "$$ >>>envelope>>>\n$envelope\n<<<envelope<<<\n";
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" =>
						 "$WSRF::Constants::WSRP/PutResourcePropertyDocument" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	my ($GET);
	if ( $request->method eq 'GET' ) {

		#does the client just want the WSDL for service
		if ( $request->uri->query eq 'WSDL' ) {
			my $resp = GetWSDL($request);
			return $resp;
		} elsif ( $ID =~ m/^$module\.(xsl|css|js|svg)$/ )

		  #looking for xsl or css or js
		{
			print "$$ Getting $ID file\n";
			my $resp = HTTP::Response->new();
			my $file = $Directory . "/" . $ID;
			print "$$ File to open is $file\n";
			if ( !( -f $file ) || !( -r $file ) ) {
				$resp->code(404);
				return $resp;
			}
			print "$$ File to open is $file\n";
			open FILE, "< $file" or die "$$ Could not open $file";
			my $xsl = join "", <FILE>;
			close FILE or die "Could not close WSDL file";
			$resp->header( 'Content-Type' => 'text/xml' )
			  if ( $ID =~ m/\.xsl$/ );
			$resp->header( 'Content-Type' => 'text/css' )
			  if ( $ID =~ m/\.css$/ );
			$resp->header( 'Content-Type' => 'text/javascript' )
			  if ( $ID =~ m/\.js$/ );
			$resp->header( 'Content-Type' => 'text/xml' )
			  if ( $ID =~ m/\.svg$/ );

			$resp->content($xsl);
			return $resp;
		}

		$GET = 1;
		my $data =
		  SOAP::Data->name('GetResourcePropertyDocument')->prefix('wsrp')
		  ->attr( { 'xmlns:wsrp' => $WSRF::Constants::WSRP } );
		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" =>
						 "$WSRF::Constants::WSRP/GetResourcePropertyDocument" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	if ( $request->method eq 'DELETE' ) {
		my $data =
		  SOAP::Data->name('Destroy')->prefix('wsrl')
		  ->attr( { 'xmlns:wsrl' => $WSRF::Constants::WSRL } );
		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" => "$WSRF::Constants::WSRL/Destroy" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	print STDERR "$$ Dispatch path $Directory\n";
	my %namespacemap = (
						 $WSRF::Constants::WSRL => "$module",
						 $WSRF::Constants::WSRP => "$module",
						 $WSRF::Constants::WSSG => "$module"
	);
	%namespacemap = ( %namespacemap, %WSRF::Constants::ModuleNamespaceMap );

	#this loads the module to handle this function, the module
	#will retrieve the state for the WS-Resource from a DB or
	#some other stable storage, process the message and return the
	#state to the stable storage
	my $resp =
	  WSRF::Session->dispatch_to($Directory)->dispatch_with( \%namespacemap )
	  ->serializer( WSRF::WSRFSerializer->new )
	  ->deserializer( WSRF::Deserializer->new )->handle($request);

	print STDERR "$$ >>>out>>>\n" . $resp->content . "\n<<<out<<<\n";
	if ( $GET || $PUT )    #Original Request was a GET
	{
		$resp = WSRF::Container::getProperties( $resp, $Directory, $module );
	}

	return $resp;
}

sub getProperties {
	my $resp   = shift @_;
	my $Dir    = shift @_;
	my $Module = shift @_;
	my $xml    = $resp->content;
	eval { require XML::LibXML };
	if ( !$@ )    #we have XML::LibXML, so we can strip the SOAP stuff
	{
		#my $xpath = '<XPath xmlns:wsrp="'
		# . $WSRF::Constants::WSRP
		# . '">(//. | //@* | //namespace::*)[ancestor-or-self::wsrp:ResourceProperties]</XPath>';
		my $xpath = '(//. | //@* | //namespace::*)[ancestor-or-self::wsrp:ResourceProperties]';
		 
		my $canon = '<?xml version="1.0" encoding="ISO-8859-1"?>' . "\n";
		$canon = $canon
		  . '<?xml-stylesheet type="text/xsl" href="'
		  . $Module
		  . '.xsl"?>' . "\n"
		  if ( -f $Dir . "/$Module.xsl" && -r $Dir . "/$Module.xsl" );
		my $parser = XML::LibXML->new();
		my $doc    = $parser->parse_string($xml);
		$canon .= $doc->toStringEC14N( 0, $xpath, [''] );
		$resp->header( "Content-Length" => length $canon );
		$resp->content($canon);
	}
	return $resp;
}

# This fuction handles message with URIs like
# http://blah.com/MultiSession/foe
# WS-Resources for this use a single process to store the state of multiple
# WS-Resources. The function passes the message onto the process that handles
# messages for all the WS-Resources of a particular type - if the process
# has not been created ie if this is the first call to this type of
# WS-Resource then this function will create the process
sub MultiSessionHandler {
	my $request = shift @_;
	print STDERR "$$ MultiSessionHandler called\n";

	#Only Handle GET and POST
	return HTTP::Response->new(RC_FORBIDDEN)
	  if (    $request->method ne 'POST'
		   && $request->method ne 'GET'
		   && $request->method ne 'DELETE'
		   && $request->method ne 'PUT' );

	my $Path = $request->uri->path;

	#strip extra '/' at start of URL
	$Path =~ s/^\/+//o;

	#remeber the Path - we will put this in our responses so clients
	#will know who sent them the message - part of WS-Addressing
	$ENV{FROM} = $ENV{URL} . $Path;

	#split up Path part of URL - we multiplex on the first part (the base)
	#the module name is the last part
	my @PathArray = split( /\//, $Path );
	my $ID = pop @PathArray;
	my ($module);

	if (    $ID =~ /\d+-?d*/o
		 || $ID =~ /^\w+\.(xsl|js|css|svg)$/o )    #a resource identifier
	{
		$module = pop @PathArray;
	} else {
		$module = $ID;
	}
	$ENV{ID} = $ID;
	my $base              = $PathArray[0];
	my $RelativeDirectory = join '/', @PathArray;

	#this is the absolute path now
	my $Directory = $ENV{WSRF_MODULES} . "/" . $RelativeDirectory;

	#check the message actually maps to a module
	my $tmpPath = $Directory . '/' . $module . ".pm";
	print STDERR "$$ Path to module $tmpPath\n";
	if ( !-f $tmpPath ) {
		print STDERR "$$ ERROR:: $tmpPath No Such File\n";
		my $fail = new HTTP::Response(RC_OK);
		$fail->header( 'Content-Type' => 'text/xml' );
		$fail->content(
						SOAP::Serializer->fault(
									   'No Service', "Check Endpoint of Service"
						)
		);
		return $fail;
	}

	my ($PUT);
	if ( $request->method eq 'PUT' ) {
		$PUT = 1;

		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $xml = $request->content;

		print STDERR "$$ Attempt to PUT\n";

		$xml =~ s/^<\?xml[\s\w\.\-].*\?>\n?//o;
		print STDERR "$$ >>>xml>>>\n$xml\n<<<xml<<<\n";

		my $data =
		  SOAP::Data->name('PutResourcePropertyDocument')->prefix('wsrp')
		  ->attr( { 'xmlns:wsrp' => $WSRF::Constants::WSRP } )
		  ->value( \SOAP::Data->value($xml)->type('xml') );

		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		print "$$ >>>envelope>>>\n$envelope\n<<<envelope<<<\n";
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" =>
						 "$WSRF::Constants::WSRP/PutResourcePropertyDocument" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	my ($GET);
	if ( $request->method eq 'GET' ) {

		#does the client just want the WSDL for service
		if ( $request->uri->query eq 'WSDL' ) {
			my $resp = GetWSDL($request);
			return $resp;
		} elsif ( $ID =~ m/^$module\.(xsl|css|js|svg)$/ )

		  #looking for xsl or css or js
		{
			print "$$ Getting $ID file\n";
			my $resp = HTTP::Response->new();
			my $file = $Directory . "/" . $ID;
			print "$$ File to open is $file\n";
			if ( !( -f $file ) || !( -r $file ) ) {
				$resp->code(404);
				return $resp;
			}
			open FILE, "< $file" or die "$$ Could not open $file";
			my $xsl = join "", <FILE>;
			close FILE or die "Could not close $file file";
			$resp->header( 'Content-Type' => 'text/xml' )
			  if ( $ID =~ m/\.xsl$/ );
			$resp->header( 'Content-Type' => 'text/css' )
			  if ( $ID =~ m/\.css$/ );
			$resp->header( 'Content-Type' => 'text/javascript' )
			  if ( $ID =~ m/\.js$/ );
			$resp->header( 'Content-Type' => 'text/xml' )
			  if ( $ID =~ m/\.svg$/ );

			$resp->content($xsl);
			return $resp;
		}

		$GET = 1;
		my $data =
		  SOAP::Data->name('GetResourcePropertyDocument')->prefix('wsrp')
		  ->attr( { 'xmlns:wsrp' => $WSRF::Constants::WSRP } );
		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" =>
						 "$WSRF::Constants::WSRP/GetResourcePropertyDocument" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	if ( $request->method eq 'DELETE' ) {
		my $data =
		  SOAP::Data->name('Destroy')->prefix('wsrl')
		  ->attr( { 'xmlns:wsrl' => $WSRF::Constants::WSRL } );
		my $To = $ENV{URL};
		chop $To;
		$To .= $request->uri;
		my $header =
		  SOAP::Header->value( "<wsa:To>" . $To . "</wsa:To>" )->type('xml');
		my $envelope = WSRF::WSRFSerializer->new()->freeform( $header, $data );
		$request = HTTP::Request->new();
		$request->method('POST');
		$request->header( "SOAPAction" => "$WSRF::Constants::WSRL/Destroy" );
		$request->header( "Content-Length" => length $envelope );
		$request->content($envelope);
	}

	#check if a process to handle this message has been created
	my $SockPath = $WSRF::Constants::SOCKETS_DIRECTORY . '/' . $module;
	my ($resp);
	if ( !-S $SockPath ) {

		#create the file and fork the process
		print STDERR "$$ Creating a new Service $module\n";
		my $service = WSRF::Resource->new(
										   module => $module,
										   path   => $RelativeDirectory,
										   ID     => $module
		);
		print STDERR "$$ Calling handle() on service\n";
		$service->handle("");
		print STDERR "$$ Connecting to Socket $SockPath\n";
		my $MyFH = IO::Socket::UNIX->new(
										  Peer    => $SockPath,
										  Type    => SOCK_STREAM,
										  Timeout => 10
		  )
		  or die SOAP::Fault->faultcode("Container Fault")
		  ->faultstring("Container Failure - Socket problem $!");

		#if using SSL add the extra information to the HTTP request
		if ( defined( $ENV{SSL_CLIENT_DN} ) ) {
			$request->header(
						   'Client-SSL-Cert-Subject' => "$ENV{SSL_CLIENT_DN}" );
			$request->header(
						'Client-SSL-Cert-Issuer' => "$ENV{SSL_CLIENT_ISSUER}" );
		}

		#print "Ingoing HTTP>>>\n".$r->as_string()."\n<<<HTTP\n";
		my $out = print $MyFH ( $request->as_string() );
		if ( !defined($out) ) {
			print STDERR "$$ ERROR could not write to $MyFH\n";
		}

		#read the response from the Socket and turn it into a
		#HTTP::Response
		$resp = WSRF::Daemon::ResponseHandler($MyFH);
		$MyFH->close;
		print STDERR "$$ $Path Processing Finished\n";
	} else    #no process to handle this message - we need to create one
	{

		#check the socket is up - send SOAP to socket
		my $MyFH = IO::Socket::UNIX->new(
										  Peer    => $SockPath,
										  Type    => SOCK_STREAM,
										  Timeout => 10
		);
		if ( !$MyFH ) {

			#create the file and fork the process
			my $service = WSRF::Resource->new(
											   module => $module,
											   path   => $RelativeDirectory,
											   ID     => $module
			);
			$service->handle();

			$MyFH = IO::Socket::UNIX->new(
										   Peer    => $SockPath,
										   Type    => SOCK_STREAM,
										   Timeout => 10
			  )
			  or die SOAP::Fault->faultcode("Container Fault")
			  ->faultstring("Container Failure - Socket problem $!");
		}

		#if using SSL add the extra information to the HTTP request
		if ( defined( $ENV{SSL_CLIENT_DN} ) ) {
			$request->header(
						   'Client-SSL-Cert-Subject' => "$ENV{SSL_CLIENT_DN}" );
			$request->header(
						'Client-SSL-Cert-Issuer' => "$ENV{SSL_CLIENT_ISSUER}" );
		}

		my $out = print $MyFH ( $request->as_string() );
		if ( !defined($out) ) { print STDERR "ERROR\n" }

		#read the response from the Socket and turn it into a
		#HTTP::Response
		$resp = WSRF::Daemon::ResponseHandler($MyFH);
		$MyFH->close;
		print STDERR "$$ $Path Processing Finished\n";
	}

	#   print STDERR "$$ >>>out>>>\n".$resp->content."\n<<<out<<<\n";
	if ( $GET || $PUT )    #Original Request was a GET
	{
		$resp = WSRF::Container::getProperties( $resp, $Directory, $module );
	}

	return $resp;
}

sub GetWSDL {
	my ($request) = @_;

	#get the path from the HTTP::Request
	my $uri  = $request->uri;
	my $path = $request->uri->path;
	$path =~ s/^\/+//o;
	my $endpoint = $ENV{URL} . $path;

	#strip extra '/' at start of URL
	#$path =~ s/^\/+//o;

	#we only allow certain types of Path
	#alphanumeric, hypen, and forward-slash
	#BUG - this pattern is too restrictive
	if ( $path =~ /^([-\/\w]+)$/ ) {
		$path = $1;
	} else {    #Bad Path
		return HTTP::Response->new(RC_FORBIDDEN);
	}

	my $LongPATH = $ENV{WSRF_MODULES} . "/" . $path . ".WSDL";

	#  print STDERR "WSRF::Container::GetWSDL LongPATH=\"$LongPATH\"\n";

	#BUG - this could be done with reg-ex
	#split up path
	my @patharray = split( /\//, $path );

	#sometimes the path will have an ID at the end - pop it of
	pop @patharray;

	#rebuild path
	$path = join '/', @patharray;
	my $ShortPATH = $ENV{WSRF_MODULES} . "/" . $path . ".WSDL";

	#  print STDERR "WSRF::Container::GetWSDL ShortPATH=\"$ShortPATH\"\n";

	# resp will be a HTTP::Response object
	# ReturnWSDL can throw exceptions, so we catch them
	my ($resp);

	#check if I can read the file
	if ( -r $LongPATH ) {
		eval { $resp = WSRF::WSDL::ReturnWSDL( $LongPATH, $endpoint ); };
		if ($@) {
			print STDERR
"$$ WSRF::Container::GetWSDL could not retrieve WSDL from $LongPATH";
			$resp = HTTP::Response->new(RC_INTERNAL_SERVER_ERROR);
		}
	} elsif ( -r $ShortPATH ) {
		eval { $resp = WSRF::WSDL::ReturnWSDL( $ShortPATH, $endpoint ); };
		if ($@) {
			print STDERR
"$$ WSRF::Container::GetWSDL could not retrieve WSDL from $ShortPATH";
			$resp = HTTP::Response->new(RC_INTERNAL_SERVER_ERROR);
		}
	} else {
		$resp = HTTP::Response->new(RC_NOT_FOUND);
	}

	return $resp;
}

#===============================================================================
# WS_Address
#
#  A class for holding and handling WS-Addressing EPRs
#
package WSRF::WS_Address;

=pod

=head1 WSRF::WS_Address

Class to provide support for WS-Addressing

=head2 METHODS

=over

=item new

Creates a new WSRF::WS_Address object, takes either a SOM object or raw XML that
contains a WS-Addressing Endpoint Reference and creates a WSRF::WS_Addressing 
object.

=item from_envelope

Creates a new WSRF::WS_Address object from a SOM representation of a SOAP Envelope 
that contains a WS-Addressing Endpoint Reference. 

=item MessageID

If the WSRF::WS_Address is used to send a message to a service to client this function
is used to create a unique identifier for the message. The identifier goes into 
the WS-Addressing SOAP Header MessageID.

=item XML

Returns the WS-Addressing Endpoint Reference as a string.

=item serializeReferenceParameters

Outputs the ReferenceParameters of the WS-Addressing Endpoint Reference.  

=back

=cut

sub new {
	my ( $self, $stuff ) = @_;

	my ( $address, $ref_params, $meta_data, $XML );
	if ( defined($stuff) ) {

		# we accept either a SOM or XML
		my $som =
		  UNIVERSAL::isa( $stuff => 'SOAP::SOM' )
		  ? $stuff
		  : SOAP::Deserializer->new->deserialize($stuff);

#    $XML =  WSRF::SimpleSerializer->new->serialize( $som->dataof("//{$WSRF::Constants::WSA}EndpointReference"));

		$address = $som->valueof("//{$WSRF::Constants::WSA}Address");

		#print STDERR "address= $address\n";

		if ( $som->match("//{$WSRF::Constants::WSA}ReferenceParameters") ) {
			my $i = 1;
			while (
					$som->match(
							"//{$WSRF::Constants::WSA}ReferenceParameters/[$i]")
			  )
			{
				$ref_params .= WSRF::SimpleSerializer->new->serialize(
						$som->dataof(
							"//{$WSRF::Constants::WSA}ReferenceParameters/[$i]")
				);
				$i++;
			}
		}

		if ( $som->match("//{$WSRF::Constants::WSA}Metadata") ) {
			my $i = 1;
			while ( $som->match("//{$WSRF::Constants::WSA}Metadata/[$i]") ) {
				$meta_data .=
				  WSRF::SimpleSerializer->new->serialize(
					   $som->dataof("//{$WSRF::Constants::WSA}Metadata/[$i]") );
				$i++;
			}
		}

	}

	bless {
			_Address             => $address,
			_ReferenceParameters => $ref_params,
			_Metadata            => $meta_data,
			_XML                 => $XML
	}, $self;

}

sub from_envelope {
	my ( $self, $stuff ) = @_;

	return $self unless defined $stuff;

	my ( $address, $ref_params, $meta_data, $XML );
	my $som =
	  UNIVERSAL::isa( $stuff => 'SOAP::SOM' )
	  ? $stuff
	  : SOAP::Deserializer->new->deserialize($stuff);

	$address =
	  $som->match("//Body//EndpointReference/{$WSRF::Constants::WSA}Address")
	  ? $som->valueof(
					 "//Body//EndpointReference/{$WSRF::Constants::WSA}Address")
	  : die
	  "WS_Address::from_envlope No wsa:EndpointReference in Envelope Body\n";

	#  print STDERR "address= $address\n";

	if (
		$som->match(
"//Body//EndpointReference/{$WSRF::Constants::WSA}ReferenceParameters" )
	  )
	{
		my $i = 1;
		while (
			$som->match( "//Body//EndpointReference/{$WSRF::Constants::WSA}ReferenceParameters/[$i]"
			)
		  )
		{
			$ref_params .= WSRF::SimpleSerializer->new->serialize(
				$som->dataof(
"//Body//EndpointReference/{$WSRF::Constants::WSA}ReferenceParameters/[$i]"
				)
			);
			$i++;
		}
	}

	if (
		 $som->match(
					"//Body//EndpointReference/{$WSRF::Constants::WSA}Metadata")
	  )
	{
		my $i = 1;
		while (
			$som->match(
				"//Body//EndpointReference{$WSRF::Constants::WSA}Metadata/[$i]")
		  )
		{
			$meta_data .= WSRF::SimpleSerializer->new->serialize(
				$som->dataof(
"//Body//EndpointRefernce/{$WSRF::Constants::WSA}Metadata/[$i]"
				)
			);
			$i++;
		}
	}

	bless {
			_Address             => $address,
			_ReferenceParameters => $ref_params,
			_Metadata            => $meta_data,
			_XML                 => $XML
	}, $self;
}

sub BEGIN {
	no strict 'refs';

	for my $method (qw(Address ReferenceParameters Metadata )) {
		my $field = '_' . $method;
		*$method = sub {
			my $self = shift;
			@_
			  ? ( $self->{$field} = shift, return $self )
			  : return $self->{$field};
		  }
	}
}

sub MessageID {
	return join '', 'urn:www.sve.man.ac.uk-', int( rand 100000000000 ) + 1,
	  gmtime;
}

sub XML {
	my $self = shift;

	if ( !defined $self->{_XML} ) {
		my $XML = '<?xml version="1.0" encoding="UTF-8"?>';
		$XML .= " <wsa:EndpointReference xmlns:wsa=\"$WSRF::Constants::WSA\">";
		$XML .= '<wsa:Address>' . $self->{_Address} . '</wsa:Address>';
		$XML .=
		  $self->{_ReferenceParameters} ? $self->{_ReferenceParameters} : '';
		$XML .= $self->{_Metadata} ? $self->{_Metadata} : '';
		$XML .= '</wsa:EndpointReference>';
		$self->{_XML} = $XML;
	}

	return $self->{_XML};
}

sub serializeReferenceParameters {
	my $self = shift;

	if ( !defined( $self->{_ReferenceParameters} ) ) {
		return undef;
	}

	#need to wrap the ReferenceParameters to parse
	my $som =
	  SOAP::Deserializer->new->deserialize(
						 '<_foo>' . $self->{_ReferenceParameters} . '</_foo>' );

	my $ans = "";
	my $i   = 1;
	while ( $som->match("/[1]/[$i]") ) {
		my $data = $som->dataof("/[1]/[$i]");
		my %attr = %{ $data->attr };
		$attr{'wsa:isReferenceParameter'} = 'true';
		$data->attr( \%attr );
		$ans .= WSRF::SimpleSerializer->new->serialize($data);
		$i++;
	}

	return $ans;

}

#===============================================================================
# WS-BaseFaults
#
# This function allows you to return a WS-BaseFault.
# Simply call die_with_Fault to case your service to
# through an exception.
#
# The function takes hash with the following:
#   OriginatorReference  (where did the fault originally originate)
#   ErrorCode            (some code number)
#   dialect              (?)
#   Description          (a description of the fault)
#   FaultCause           (?)
# For details check out the BasFault spec.
#
# I am not sure when you should throw a SOAP fault or a BaseFault

package WSRF::BaseFaults;

=pod

=head1 WSRF::BaseFaults

Class to support the WSRF BaseFaults specification 

=head2 METHODS

=over

=item die_with_Fault

To return a WSRF BaseFault call die_with_Fault. die_with_Fault creates a SOAP fault
then dies.
	     
	 die_with_Fault(
	    OriginatorReference => $EPR,             
	    ErrorCode           => $errorcode,     
	    dialect             => $dialect,       	
	    Description         => $Description,
	    FaultCause          => $FaultCause  
	  );
	   
OriginatorReference is the WS-Addressing Endpoint Reference of the WS-Resource that the 
fault orignially came from. ErrorCode allows the WS-Resource to pass an error code 
back to the client. dialect is the dialect that the error code belongs to. Description
provides a description of the fault and FaultCause provides the reason for the fault.
  
=back

=cut

sub die_with_Fault {
	my %args = @_;

	my $fault = "<wsbf:BaseFault xmlns:wsbf=\"$WSRF::Constants::WSBF\">";
	$fault .=
	    "<wsbf:Timestamp>"
	  . WSRF::Time::ConvertEpochTimeToString(time)
	  . "</wsbf:Timestamp>";

	if ( defined( $args{OriginatorReference} ) ) {
		$fault .=
		    "<wsbf:OriginatorReference>"
		  . $args{OriginatorReference}
		  . "</wsbf:OriginatorReference>";
	}

	#has the client defined an error code & dialect
	if ( defined( $args{ErrorCode} ) ) {
		if ( defined( $args{dialect} ) ) {
			$fault .=
			    "<wsbf:ErrorCode dialect=\""
			  . $args{dialect} . "\">"
			  . $args{ErrorCode}
			  . "</wsbf:ErrorCode>";
		} else {
			$fault .=
			  "<wsbf:ErrorCode>" . $args{ErrorCode} . "</wsbf:ErrorCode>";
		}
	}

	#has the client defined a Description
	if ( defined( $args{Description} ) ) {
		$fault .=
		  "<wsbf:Description>" . $args{Description} . "</wsbf:Description>";
	}

	#has the client defined a BaseCause
	if ( defined( $args{FaultCause} ) ) {
		$fault .=
		  "<wsbf:FaultCause>" . $args{FaultCause} . "</wsbf:FaultCause>";
	}

	$fault .= "</wsbf:BaseFault>";

	die SOAP::Fault->faultdetail($fault);
}

#===============================================================================
# For WSRF services that are Session based - the process that calls
# this function does all the work - it loads the module, does the operation
# and returns the result.
#
package WSRF::Session;

use SOAP::Transport::HTTP;

use vars qw(@ISA);

@ISA = qw(SOAP::Transport::HTTP::Server);

sub DESTROY { SOAP::Trace::objects('()') }

# constructor for the WSRF::Deamon object
sub new {
	my $self = shift;

	unless ( ref $self ) {
		my $class = ref($self) || $self;
		$self = $class->SUPER::new(@_);
		SOAP::Trace::objects('()');
	}
	return $self;
}

sub handle {
	my $self = shift->new;
	$self->request( shift @_ );
	$self->SUPER::handle;
	return $self->response;
}

#===============================================================================
# Similar to the SOAP::Transport::Daemon module except it listens to a UNIX
# Domain Socket rather than an INET port
#
package WSRF::Daemon;

use vars qw(@ISA);

use HTTP::Status;
use SOAP::Transport::HTTP;

@ISA = qw(SOAP::Transport::HTTP::Server);

sub DESTROY { SOAP::Trace::objects('()') }

# constructor for the WSRF::Deamon object
sub new {
	my $self = shift;

	unless ( ref $self ) {
		my $class = ref($self) || $self;
		$self = $class->SUPER::new(@_);
		SOAP::Trace::objects('()');
	}
	return $self;
}

# takes a socket and handles the info coming out of
# it, passes it to the SOAP handler and then returns
# the answer.
sub handle {
	my $self = shift->new;
	my $Hdle = shift;

	while ( my $new_c = $Hdle->accept ) {
		my $req = $self->Requesthandler($new_c);

		#print "CHILD START::\n",$req->as_string, "CHILD END\n";
		$self->request($req);
		$self->SUPER::handle;
		my $resp = $self->response;

		#print "Return>>>\n".$resp->as_string."\n<<<Return\n";
		print $new_c ( $resp->as_string );
	}
	close($Hdle);
}

# A function that takes a HTTP message from a socket $Handle
# and converts it to a HTTP::Request object
# This HTTP handler is not very sophisticated but we know the
# message has already been parsed in the pipeline
sub Requesthandler {
	my ( $self, $Handle ) = @_;
	my $request = HTTP::Request->new();
	chomp( my $method = <$Handle> );
	my ( $Met, $URI, @blah ) = split( / /, $method );
	$request->method($Met);
	$request->uri($URI);
	my $SIZE = 0;
  LINE: while ( my $line = <$Handle> ) {
		last LINE if $line eq "\n";
		my ( $TAG, $VAL ) = split( /: /, $line, 2 );
		if ( $TAG eq "Content-Length" ) {
			$SIZE = $VAL;
		} elsif ( $TAG eq 'Client-SSL-Cert-Subject' ) {
			$ENV{SSL_CLIENT_DN} = $VAL;
		} elsif ( $TAG eq 'Client-SSL-Cert-Issuer' ) {
			$ENV{SSL_CLIENT_ISSUER} = $VAL;
		}
		$request->header( $TAG, $VAL );
	}
	$request->remove_header( 'TE', 'Connection', 'SOAPAction' );
	my $content = "";

	if ( $SIZE != 0 ) {

	  FULL: while ( my $line = <$Handle> ) {
			$content .= $line;
			last FULL if length($content) >= $SIZE;
		}
		$request->content($content);
	}

	return $request;
}

#parses a HTTP message that comes from a Socket called $Handler
#and returns a HTTP::Response object.
#not much error checking but we know the response should be
#good since we created it.
sub ResponseHandler {
	my ($Handler) = @_;
	my $SIZE      = 0;
	my $resp      = HTTP::Response->new(RC_OK);
	chomp( my $result = <$Handler> );

	#    $resp->message($result);
  LINE: while ( my $line = <$Handler> ) {
		last LINE if $line eq "\n";
		my ( $TAG, $VAL ) = split( /:/, $line, 2 );
		my $headers .= $TAG . " " . $VAL;
		if ( $TAG eq "Content-Length" ) {
			$SIZE = $VAL;
		}
		$resp->header( $TAG, $VAL );
	}
	my $content = "";
  FULL: while ( my $line = <$Handler> ) {
		$content .= $line;
		last FULL if length($content) >= $SIZE;
	}
	$resp->content($content);
	return $resp;
}

#===============================================================================
# This class takes a WSDL file and changes the endpoint to match the
# proper endpoint of the service
#
# BUG(FIXED) - "soap:address" is hardcoded, problem with XML::DOM not
#       understanding namespaces - FIXED

package WSRF::WSDL;

use XML::DOM;
use HTTP::Status;

sub ReturnWSDL {
	my ( $FILEPATH, $endpoint ) = @_;

	#  print STDERR "WSDL File Path  = $FILEPATH\n";

	if ( !-r $FILEPATH ) {
		print STDERR "ERROR WSDL file does not exist\n";
		return HTTP::Response->new(RC_NOT_FOUND);
	}

	#open file and read contents
	#print "Creating Response Object\n";
	#if we cannot open file we do NOT throw a SOAP fault
	#because we are not answering a SOAP request but a HTTP
	#GET request for the WSDL. This exception should be caught
	#by however has called this function.
	open FILE, "< $FILEPATH" or die "Could not open WSDL file";

	#read file
	my $wsdl = join "", <FILE>;

	#close file
	close FILE or die "Could not close WSDL file";

	#take a copy of the WSDL
	my $soap = $wsdl;

	#get the prefix for the http://schemas.xmlsoap.org/wsdl/soap/
	#namespace - hacky because XML::DOM does not like namespaces
	$soap =~ s/="http:\/\/schemas\.xmlsoap\.org\/wsdl\/soap\/"(.|\n)*//o;
	$soap =~ s/(.|\n)*xmlns://o;

	#  print STDERR "Soap Namespace= ".$soap."\n";

	my $parser = new XML::DOM::Parser;

	# we used to just parse the file but the above hack screwed that
	# up - we just parse the string.
	# my $doc = $parser->parsefile($FILEPATH);
	my $doc  = $parser->parse($wsdl);
	my $node = $doc->getElementsByTagName( $soap . ":address" );

	if ( !defined $node->item(0) ) {
		print STDERR "$$ ERROR in WSDL file - no " . $soap
		  . ":address element\n";
		return HTTP::Response->new(RC_INTERNAL_SERVER_ERROR);
	}

	#These methods can throw exceptions - please catch them
	$node->item(0)->getAttributeNode("location")->setValue();
	$node->item(0)->getAttributeNode("location")->setValue($endpoint);

	my $ans = $doc->toString;
	$doc->dispose;

	my $resp = HTTP::Response->new(RC_OK);
	$resp->header( 'Content-Type' => 'text/xml' );
	$resp->content($ans);
	return $resp;
}

#===============================================================================
#
# Some helper functions that have been bundled together
#
package WSRF::GSutil;

use IO::Socket;

# function to generate a unique handle for the resource.
# BUG - the name is misleading, GSH is a hangover from OGSI
sub CalGSH_ID {
	my $num = int( rand 100000 ) + 1;
	my $gsh_id = join( '', gmtime ) . $num;
	return $gsh_id;

}

# create a WS-Address
# BUG - we die without throwing proper SOAP faults
# function takes a HASH with the following
#  path    = relative path to module directory (relative to $ENV{WSRF_MODULES})
#  module  = name of module file
#  ID      = the WS-Resource identifier (can be created with CalGSH_ID above)
sub createWSAddress {
	my %args = @_;

	my $URL    = $ENV{'URL'};
	my $path   = $args{path} || die "createWSAddress:: No Module Path\n";
	my $module = $args{module} || die "createWSAddress:: No Module\n";
	my $ID     = $args{ID} || die "createWSAddress:: No ID\n";

	#strip .pm from module name if it is there
	$module =~ s/\.pm$//o;

	#strip leading /
	$path =~ s/^\/+//o;

	#strip trailing /
	$path =~ s/\/+$//o;

	#actual endpoint of service
	my $endpoint = $ENV{'URL'} . $path . '/' . $module . '/' . $ID;

	#here we create the WS-Addressing string
	my $response =
	  "<wsa:EndpointReference xmlns:wsa=\"$WSRF::Constants::WSA\">";
	$response .= "<wsa:Address>" . $endpoint . "</wsa:Address>";
	$response .= "</wsa:EndpointReference>";

	return $response;
}

# send some SOAP down the UNIX socket to the Resource, returns a SOM object
sub SendSOAPToSocket {
	my ( $SocketAddress, $URI, $method, @params ) = @_;

	#print "SendSOAPToSocket: SocketAddress= $SocketAddress\n";
	#print "SendSOAPToSocket: URI= $URI\n";
	#print "SendSOAPToSocket: method= $method\n";
	#foreach my $param ( @params )
	#{
	#  print "SendSOAPToSocket: params= $param\n";
	#}

	#create a SOAP message
	my $my_soap =
	  SOAP::Lite->serializer->uri($URI)->envelope( method => $method, @params );

	#print "SendSOAPToSocket: my_soap= \n".$my_soap."\n";

	#create a HTTP message and put the SOAP into it
	my $request = HTTP::Request->new();
	$request->method('POST');
	$request->uri($URI);
	$request->push_header( 'Content_Length' => length($my_soap) );
	$request->push_header( 'Content-Type'   => 'text/xml; charset=utf-8' );
	$request->content($my_soap);

	#BUG - have we actually checked the socket exists?
	#open the sockect
	my $rendev = $SocketAddress;
	my $MyFH = IO::Socket::UNIX->new(
									  Peer    => "$rendev",
									  Type    => SOCK_STREAM,
									  Timeout => 10
	  )
	  or die SOAP::Fault->faultcode("Container Fault")
	  ->faultstring("Container Failure - Socket problem $!");

   #print "SendSOAPToSocket sending \n".$request->as_string()."\n to $rendev\n";
   #send HTTP request with SOAP messgae down sockect
	my $out = print $MyFH ( $request->as_string() )
	  or die SOAP::Fault->faultcode("Container Fault")
	  ->faultstring("Container Failure - Socket problem $!");

	if ( !defined($out) ) {
		print STDERR
"$$ ERROR - WSRF::GSutil::SendSOAPToSocket did not get response from Socket\n";
		die SOAP::Fault->faultcode("Container Fault")
		  ->faultstring("Container Failure - Socket problem");
	}

	#resp is a HTTP::Response Object
	my $resp = WSRF::Daemon::ResponseHandler($MyFH);

	#$som is a WSRF::SOM object
	my $som = WSRF::Deserializer->deserialize( $resp->content );

	return $som;
}

#===============================================================================
# Some functions to handle time - convert to/from epoch time/W3C time.
# To handle times and compare them we convert all times in W3C format to
# seconds since the epoch (ie. the number of seconds since 1970)
#
# This module provides some helper classes for doing this
#
package WSRF::Time;

=pod

=head1 WSRF::Time

WSRF::Time provides two helper sub routines for converting a W3C time
to seconds since the Epoch and vice versa.

=head2 METHODS

=over

=item ConvertStringToEpochTime

Converts a W3C date time string to the number of seconds since the UNIX Epoch.

=item ConvertEpochTimeToString

Converts a time in seconds since the UNIX Epoch to a W3C date time string.

=back

=cut

=head2 VARIABLES

=over

=item EXPIRES_IN

You can specify how long until an item expires with $WSRF::TIME::EXPIRES_IN. This variable defaults to 60 seconds. 

=back

=cut


use DateTime::Format::W3CDTF;
use DateTime::Format::Epoch;

# THE EXPIRES_IN variable, rather than hard code 60*60 seconds
$WSRF::TIME::EXPIRES_IN = 60;

# convert XML format Time string to time in seconds since epoch
sub ConvertStringToEpochTime {
	my ($StringTime) = @_;

	#print "StringTime = $StringTime\n";
	#$f object used to convert W3CDTF TimeString to DateTime object
	my $f = DateTime::Format::W3CDTF->new;

	#$formatter used to convert DateTime object to seconds from epoch
	#we use the unix epoch here
	my $dt = DateTime->new( year => '1970', month => '1', day => '1' );
	my $formatter = DateTime::Format::Epoch->new( epoch => $dt );

	#convert $StringTime to a DateTime object
	#This will throw an exception if StringTime is not in the correct W3C format
	#BUG(fixed) with DateTime::Format::W3CDTF - does not
	#like subseconds - should patch DateTime::Format::W3CDTF
	#strip of the crap that DateTime::Format::W3CDTF does not understand
	$StringTime =~ s/\.\d+//;

	my $DateTimeObject = $f->parse_datetime($StringTime);

	#calc time in sec from epoch of $DateTimeObject
	my $EpochTime = $formatter->format_datetime($DateTimeObject);

	return $EpochTime;
}

# convert time in secs since Epoch to suitable XML format string
sub ConvertEpochTimeToString {
	my ($EpochTime) = @_;

	#if no input time use now
	if ( !defined($EpochTime) ) {
		$EpochTime = time;
	}

	#use formatter to convert epoch time to W3CDTF TimeString
	my $dt = DateTime->new( year => 1970, month => 1, day => 1 );
	my $formatter = DateTime::Format::Epoch->new( epoch => $dt );

	my $DateTimeObject = $formatter->parse_datetime($EpochTime);

	my $f = DateTime::Format::W3CDTF->new;

	my $TimeString = $f->format_datetime($DateTimeObject);

	return $TimeString;
}

#===============================================================================
# Class that allows us to create a new WSRF reource - uses a process to hold
# the state of the resource. The handle function actually forks the process
# to manage and hold the state of the Resource.
#
package WSRF::Resource;

=pod 

=head1 WSRF::Resource

A process based WS-Resource. The state of the WS-Resource is held in a 
process, the WSRF::Lite Container talks to the WS-Resource via a named UNIX
socket.

=head2 METHODS

=over

=item new

Creates a new WSRF::Resource.

  my $resource = WSRF::Resource->new(
          module    => Counter,       
          path      => /WSRF/Counter/Counter.pm,
	  ID        => M4325324563456,
	  namespace => Counter
          ); 

B<module> is the name of the module that implements the WS-Resource, 
B<path> is the path to the module relative to $ENV{WSRF_MODULES},
B<ID> is the identifier for your WS-Resource, it will used as part of
the URI in the WS-Addressing EPR. If you do not include the B<ID> one
will be assigned for you. B<namespace> is the namespace of the WSDL 
port for any non WSRF operations the WS-Resource supports, if no namespace
is provided the name of the module will be used 

=item handle

This subroutine should be called after B<new>. It forks the process
that is the WS-Resource. Anything passed to B<handle> is sent to the
B<init> method of the WS-Resource after it is created. The WS-Addressing
EPR of the WS-Resource is available to the WS-Resource through $ENV{WSA}.
B<handle> returns the WSRF identifier for the WS-Resource, this is used
to form the URI used in the WS-Addressing EPR.
	  
=item ID

ID returns the WSRF identifier for the WS-Resource. 

=back

=cut

use IO::Socket;

use vars qw($AUTOLOAD);

# new takes a HASH with
#  module - name of module
#  path   - relative path to module (relative to $ENV{WSRF_MODULES}
#  ID     - idnetifier for resource (if non is provided then it is calc'd
#           for you)
#  namepsace - for your service
sub new {
	my ( $class, %args ) = @_;

	bless {
		_module => $args{module} || die("missing module name\n"),
		_path   => $args{path}   || die("missing module path\n"),
		_ID     => $args{ID}     || WSRF::GSutil::CalGSH_ID(),
		_namespace => $args{namespace}
		  || ""

	}, $class;
}

sub ID {
	my ($self) = @_;
	return $self->{_ID};
}

# function that forks the process that manages the Resource - after
# forking the init function is called on the Service. Allows user to
# put an init funtion into their module which they know will be
# called when the service is first created.
sub handle {
	my ( $self, @Params ) = @_;

	my $ModulePath = $self->{_path};
	my $resourceID = $self->{_ID};
	my $ModuleName = $self->{_module};
	my $Namespace  = $self->{_namespace};

	#strip .pm from end of module if is there
	$ModuleName =~ s/\.pm$//o;

	#print "handle Namespace = $Namespace\n";
	#$SIG{CHLD} = 'IGNORE';

	#my $URL = $ENV{'URL'};
	#chop $URL;
	my $location = $ENV{'URL'} . "$ModulePath";

	#fork the service off here
	if ( my $pid = fork ) {

		#parent process
	} elsif ( defined $pid ) {    #child
		$SIG{ALRM} = sub { die "Alarm went off\n"; };

		#There may be an open connection to the world - need to close it
		if ( defined($WSRF::Constants::ExternSocket) ) {
			$WSRF::Constants::ExternSocket->close;
			undef $WSRF::Constants::ExternSocket;
		}

		#Store the WSA addres in a ENV variable so the
		#service can know its own EPR
		$ENV{WSA} =
		  WSRF::GSutil::createWSAddress(
										 module => $ModuleName,
										 path   => $ModulePath,
										 ID     => $resourceID
		  );

		#the address of the socket were this resource is going to live
		my $rendivous = $WSRF::Constants::SOCKETS_DIRECTORY . "/" . $resourceID;

		#remove any file that is already there...
		if ( -e $rendivous ) {
			unlink "$rendivous"
			  or die SOAP::Fault->faultcode("Container Fault")
			  ->faultstring("Container Failure - Could not remove file");
		}

		print STDERR "$$ Created $resourceID rendezvous:: $rendivous\n";
		my $Handle = IO::Socket::UNIX->new(
											Local  => "$rendivous",
											Type   => SOCK_STREAM,
											Listen => SOMAXCONN
		  )
		  or die SOAP::Fault->faultcode("Container Fault")
		  ->faultstring("Container Failure - Socket problem $!");
		print STDERR "$$ $resourceID Socket: $Handle\n";

		# redirect stderr/stdout to log directory
		open( STDOUT, "> " . $ENV{WSRF_MODULES} . "/logs/$resourceID.log" )
		  or print STDERR "$$ WARNING: Could not open log file "
		  . $ENV{WSRF_MODULES}
		  . "/logs/$resourceID.log in WSRF::Resource::handle\n";
		open( STDERR, ">&STDOUT" );

#my %namespaces = { 'http://www.ibm.com/xmlns/stdwip/web-services/WS-ResourceLifetime'
#                    => "$ModuleName",
#                   'http://www.ibm.com/xmlns/stdwip/web-services/WS-ResourceProperties'
#                    => "$ModuleName"
#                 };

		#if ($Namespace  ne "" )
		#{
		#   $namespaces{$Namespace} = $ModuleName;
		#}

		#print "handle set $Namespace = ".$namespaces{$Namespace}."\n";

		#create a new service

		# BUG - if Namespace is not set
		# Now start the Resource in the process we have just created.
		%WSRF::WSRP::ResourceProperties   = ();
		%WSRF::WSRP::PropertyNamespaceMap = ();
		%WSRF::WSRP::NotDeletable         = ();
		%WSRF::WSRP::NotModifiable        = ();
		%WSRF::WSRP::NotInsert            = ();
		%WSRF::WSRP::Private              = ();

		my $daemon =
		  WSRF::Daemon->new()->serializer( WSRF::WSRFSerializer->new )
		  ->deserializer( WSRF::Deserializer->new )
		  ->dispatch_to(   "$ENV{WSRF_MODULES}" . "/"
						 . "$ModulePath" )->dispatch_with(
									 {
									   $WSRF::Constants::WSRL => "$ModuleName",
									   $WSRF::Constants::WSRP => "$ModuleName",
									   $WSRF::Constants::WSSG => "$ModuleName",
									   $Namespace             => $ModuleName
									 }
						 );

		#use eval to handle any time out
		eval { $daemon->handle($Handle); };
		print STDERR
"$$ WSRF::Resource::handle caught exception: $@ - if it is \"Alarm went off\" then the WS-Resource's lifetime has expired";
		unlink($rendivous)
		  or print STDERR
		  "$$ WARNING: Could not remove $rendivous in WSRF::Resource::handle\n";
		print STDERR "$$ Resource Shutting Down\n";

		exit;    #should never get here!!
	} else {     #problem forking
		print STDERR
"$$ ERROR: Could perform fork it start Resource in WSRF::Resource::handle\n";
		return "FAILURE";
	}

	#Parent Process Takes Over Here.
	# by default the factory will call init on the service it just
	# created - select is called to allow the child time to set up socket
	my $rend = $WSRF::Constants::SOCKETS_DIRECTORY . "/" . $resourceID;

	#sleep for 0.2 seconds
	select( undef, undef, undef, 0.2 );

	#resp from SendSOAPToSocket is a WSRF::SOM object - here we call init method
	my $resp =
	  WSRF::GSutil::SendSOAPToSocket( $rend, $ModuleName, "init", @Params );

	#Check for a fault from the init method
	if ( $resp->fault ) {
		print STDERR "$$ ERROR: SOAP fault from init: "
		  . $resp->faultstring
		  . "\n in WSRF::Resource::handle\n";
	}

	return ( $resourceID, $resp );
}

# Once a WSRF::Resource is created with new and started using handle
# method we can call operations on the Service using AUTOLOAD
sub AUTOLOAD {
	my ( $self, @params ) = @_;

	#strip class name from method name (Conway p56)
	$AUTOLOAD =~ s/.*:://;

	my $rend = $WSRF::Constants::SOCKETS_DIRECTORY . "/" . $self->ID();

	if ( $AUTOLOAD eq "DESTROY" ) {

		#    print STDERR "Attempt to DESTROY ".$self->ID()."\n";
		return;
	}

	#$resp is WSRF::SOM object
	my $resp =
	  WSRF::GSutil::SendSOAPToSocket( $rend, $self->{_module}, $AUTOLOAD,
									  @params );

	return $resp;
}

#===============================================================================
# This is the module that provides file locking for us - when an object of this
# class is created a lock file is created. The lock file is automatically
# removed when the object is destroyed. We could use  fcntl to do this - I
# decided to actually create lock files so a user could manually create and
# remove lock files themselves.
#
# This`works by creating/checking for/removing a directory
#
# BUG - This is not very sophistcated. We use this class in WSRF::File

=pod

=head1 WSRF::FileLock

Simple class to provide file locking. It is possible to use fcntl to
do file locking but some file systems don't support it. WSRF::FileLock is
used to by the file based WS-Resources in WSRF::Lite to prevent concurrent
access to the WS-Resource by more than one client.  

=head2 METHODS

=over

=item new

B<new> takes a name and tries to create a directory with that name,
if there is already a directory with that name it will sleep for half
a second and retry. When the directory is created a new WSRF::FileLock
object is returned, then the object goes out of scope the directory is
removed.

   my $lock = WSRF::FileLock->new($somefilelocation); 

=back 
 
=cut

package WSRF::FileLock;

#Provides a simple locking tool -

sub new {
	my ( $self, $file ) = @_;

	#$file is the name of the directory to make - the lock
	until ( mkdir $file ) {
		select( undef, undef, undef, 0.5 );
		print STDERR "$$ Lock on $file\n";
	}

	bless { _file => $file }, $self;
}

sub DESTROY {
	my ($self) = @_;
	print STDERR "$$ Removing Lock File ";
	print STDERR $self->{_file} . "\n";
	if ( -d $self->{_file} ) {
		rmdir $self->{_file}
		  or die SOAP::Fault->faultcode("Container Fault")
		  ->faultstring( "Could not remove lock file " . $self->{_file} );
	}
	print STDERR "$$ Lock file " . $self->{_file} . " removed\n";
}

#===============================================================================
# This module supports writing all the resource properties of a Resource to a
# file. Allows the state of the resource to be stored in a file between calls
# to the Resource. Relies on the Serialisers provided by SOAP::Lite to do the
# work
#
# We could use other Perl modules to do this (eg. the Dumper module) - I
# decided to reuse stuff from SOAP::Lite
#
package WSRF::File;
use Storable qw(lock_store lock_nstore lock_retrieve);
use Safe;

=pod

=head1 WSRF::File

This class provides support for serializing the state of a WS-Resource to
a file.

=head2 METHODS

=over

=item new

Takes a WSRF::SOM envelope, gets the ID of the WS-Resource and then loads
the properties of the WS-Resource into the WSRF::WSRP::ResourceProperties 
hash. B<new> locks the WS-Resource so that no other client can access 
the WS-Resource while this clients request is being processed. When the
WSRF::File object runs out of scope and is destroyed the lock is removed.

=item ID

Returns the WSRF::Lite indentifier of the WS-Resource.

=item path

Filename of the file that holds the state of the WS-Resource.

 
=item toFile

Serializes the  WSRF::WSRP::ResourceProperties hash back to the file. If the
properties of the WS-Resource have been modified this should be called before
the WSRF::File object goes out of scope.

=back

=cut 

# this is made a private function - Resources use files to store their state
# inherit this module along the way, we do not want remote clients to be
# able to invoke this function so we make it private. (SOAP::Lite will not
# allow you to invoke private functions in a module remotely)
# This function takes a SOM object and puts the data from the SOM object
# into the ResourceProperty HASH of the Resource, the resource developer
# only has to program using the hash.
#
my $Insert = sub {
	my ($b) = @_;

	#get the name of the property
	my $name = $b->dataof()->name;

	#print "insert name= ".$name."\n";

	#check there is no user defined function
	#for inserting this property
	if ( defined( $WSRF::WSRP::InsertMap{$name} ) ) {
		$WSRF::WSRP::InsertMap{$name}->($b);
		return;
	}

	#get the value of the property
	my $value = $b->dataof()->value;

	#print "insert $name value= $value\n";

	#check the property actually exists
	if ( defined( $WSRF::WSRP::ResourceProperties{$name} ) ) {

		#check the type of the property (scalar|array)
		my $type = ref( $WSRF::WSRP::ResourceProperties{$name} );
		if ( $type eq "" )    #scalar
		{
			$WSRF::WSRP::ResourceProperties{$name} = $value;
		} elsif ( $type eq "ARRAY" )    #array
		{

			#add property to array
			push( @{ $WSRF::WSRP::ResourceProperties{$name} }, $value );
		} elsif ( $type ne "CODE" ) {
			print STDERR
"$$ ERROR: Property $name is a $type, only ARRAY,SCALAR and CODE are supported in WSRF::File::Insert\n";
		}
	} else {
		print STDERR
"$$ ERROR: Attempting to load property from file that has not been declared in WSRF::File::Insert\n";
	}

	return;
};

# Takes a SOAP::SOM envelope, gets the ID of the Resource and then loads the
# properties into the WSRF::WSRP::ResouceProperties hash for the service. Uses
# the Insert function to load the properties into the hash. Also creates a
# lock file - lock file is removed in the DESTROY operation when the
# WSRF::File object is destroyed
#
sub new {
	my ( $class, $envelope ) = @_;

	my $address = $envelope->headerof("//{$WSRF::Constants::WSA}To");
	if ( defined $address ) {
		$address = $envelope->headerof("//{$WSRF::Constants::WSA}To")->value;
	} else {
		print STDERR "ERROR: No ResourceID in the SOAP Header\n";
		die SOAP::Fault->faultcode("No WS-Resource Identifier")
		  ->faultstring("No WS-Resource identifier in SOAP Header");
	}

	my @PathArray = split( /\//, $address );
	my $ID        = pop @PathArray;

	#my $ID = $ENV{ID};

	#check the ID is safe - we do not accept dots,
	#all paths will be relative to $ENV{WRF_MODULES}
	#only allow alphanumeric, underscore and hyphen
	if ( $ID =~ /^([-\w]+)$/ ) {
		$ID = $1;
	} else {
		print STDERR "$$ WSRF::File ERROR: Bad $ID for WS-Resource\n";
		die SOAP::Fault->faultcode("Badly formed WS-Resource Identifier")
		  ->faultstring("Badly formed WS-Resource Identifier: $ID");
	}

	my $ID_clipped = $ID;

	#ID can be of the form 1341-4565, we use this form to all multiple
	#WS-Resources to share the same state, the state is in the file
	#1341 - we use this with ServiceGroup/ServiceGroupEntry
	$ID_clipped =~ s/-\w*//o;

	my $path = $WSRF::Constants::Data . $ID_clipped;

	if ( !( -e $path ) ) {
		print STDERR "$$ ERROR: No Resource $path\n";
		die SOAP::Fault->faultcode("No WS-Resource")
		  ->faultstring("No WS-Resource with Identifer $ID");
	}

	#The address of the lock file
	my $lock = $path . ".lock";

	#Acquire a lock for the file
	my $Lock = WSRF::FileLock->new($lock);

#   open FILE, "$path" or die SOAP::Fault->faultcode("Container Failure")
#		                        ->faultstring("Container Failure: Could not open WS-Resource file");
#   #read the XML from the file
#   my $XML = join "",<FILE> ;

#   close FILE or die SOAP::Fault->faultcode("Container Failure")
#		                ->faultstring("Container Failure: Could not close WS-Resource file");

	# convert the XML into a SOM object. (the SOM object will still allow access
	# to the raw XML)
	#   my $som = WSRF::Deserializer->deserialize($XML);

	#iterate through the ResourceProperties and call insert for each one
	#   my $k = 1;
	#   while( $som->match("//ResourceProperties/[$k]") )
	#   {
	#print "SOM name= ".$som->dataof("//ResourceProperties/[$k]")->name()."\n";
	#     $Insert->( $som->match("//ResourceProperties/[$k]") );
	#     $k++;
	#   }

	#   my $safe = new Safe;
	#   $safe->permit(qw(:default require));
	#   local $Storable::Eval = sub { $safe->reval($_[0]) };
	my $hashref = Storable::lock_retrieve($path);

	#   print "Thawing...\n";
	#   foreach my $key (keys %$hashref)
	#   {
	#     $WSRF::WSRP::ResourceProperties{$key} = $hashref->{$key};
	#     print $key.": ".$hashref->{$key}."\n";
	#   }
	#print "CurrentTime = ".${$hashref->{CurrentTime}}."\n";

	%WSRF::WSRP::ResourceProperties =
	  ( %WSRF::WSRP::ResourceProperties, %{ $hashref->{Properties} } );

	%WSRF::WSRP::Private = ( %WSRF::WSRP::Private, %{ $hashref->{Private} } );

	#check that the resource is still alive - if TT time is not
	#set then TT is infinity
	if ( defined( $WSRF::WSRP::ResourceProperties{'TerminationTime'} )
		 && ( $WSRF::WSRP::ResourceProperties{'TerminationTime'} ne "" ) )
	{
		if (
			 WSRF::Time::ConvertStringToEpochTime(
							  $WSRF::WSRP::ResourceProperties{'TerminationTime'}
			 ) < time
		  )
		{
			print STDERR "$$ Resource $ID expired\n";
			unlink $path
			  or die SOAP::Fault->faultcode("Container Failure")
			  ->faultstring("Container Failure: Could not remove file");
			rmdir $lock
			  or die SOAP::Fault->faultcode("Container Failure")
			  ->faultstring("Container Failure: Could not remove lock file");
			die SOAP::Fault->faultcode("No such Resource")
			  ->faultstring("No such Resource $ID - Lifetime expired");
		}
	}

	bless {
			_ID   => $ID,
			_path => $path,
			_lock => $Lock
	}, $class;
}

sub ID {
	my ($self) = @_;
	return $self->{_ID};
}

sub path {
	my ($self) = @_;
	return $self->{_path};
}

# Send the ResourceProperties to a file
sub toFile {
	my $class = shift;

	my $filename =
	  ref($class)
	  ? $class->{_path}
	  : $WSRF::Constants::Data . $class;

#   open FILE, ">$filename" or die SOAP::Fault->faultcode("Container Failure")
#		                             ->faultstring("Container Failure: Could open file");

 #  print ">>>>AFTER>>>>\n".WSRF::WSRP::xmlizeProperties()."\n<<<<<<<<<<<<\n\n";

	#   print FILE WSRF::WSRP::xmlizeProperties();

	#   close FILE or die  SOAP::Fault->faultcode("Container Failure")
	#		                 ->faultstring("Container Failure: Could close file");
	#   my $safe = new Safe;
	#   $safe->permit(qw(:default require));
	#   local $Storable::Eval = sub { $safe->reval($_[0]) };
	#   local $Storable::Deparse = 1;

	my %tmpPrivate = (%WSRF::WSRP::Private);

	#should use map?
	foreach my $key ( keys %tmpPrivate ) {
		if ( ref( $tmpPrivate{$key} ) eq "CODE" ) {
			delete $tmpPrivate{$key};
		}
	}

	#take a copy of the ResourceProperties to copy to file
	my %tmphash = (%WSRF::WSRP::ResourceProperties);
	foreach my $key ( keys %tmphash ) {
		if ( ref( $tmphash{$key} ) eq "CODE" ) {
			delete $tmphash{$key};
		}
	}

	my %tmpStore = ( Properties => \%tmphash, Private => \%tmpPrivate );

	local $Storable::forgive_me = "TRUE";
	lock_store \%tmpStore, $filename;

	return;
}

sub unlock {
	my ($self) = @_;
	my $Lock = $self->{_lock};
	$Lock->DESTROY();
}

#===============================================================================
# header function creates a SOAP::Header that should be included
# in the response to the client. Handles the WS-Address stuff.
# Takes the original envelope and creates a Header from it -
# the second paramter will be stuffed into the Header so must
# be XML
#
# BUG This should be better automated - probably in the SOAP serializer,
# not sure how because we need to remember the MessageID
package WSRF::Header;

=pod

=head1 WSRF::Header

WSRF::Header provides one helper routine B<header>

=head2 METHODS

=over

=item header

This subroutine takes a WSRF::SOM envelope and creates the appropriate
SOAP Headers for the response including the required WS-Addressing SOAP
headers. 
 
 
 sub foo {
    my $envelope = pop @_;
    
    return WSRF::Header::header($envelope); 
  } 
  
=back

=cut

sub header {
	my ( $envelope, $anythingelse ) = @_;

	#To create the wsa:Action we must find the operation name
	#and its namespace
	my $data     = $envelope->match('/Envelope/Body/[1]')->dataof;
	my $method   = $data->name;
	my $uri      = $data->uri;
	my $Action   = $uri . "/" . $method . "Response";
	my $myHeader = "<wsa:Action wsu:Id=\"Action\">" . $Action . "</wsa:Action>";

	#We only use "anonoymous" for wsa:To
	$myHeader .= "<wsa:To wsu:Id=\"To\">$WSRF::Constants::WSA_ANON</wsa:To>";

	#We use our endpoint to create the wsa:From - the endpoint
	#is an ENV variable
	if ( $envelope->match("/Envelope/Header/{$WSRF::Constants::WSA}To") ) {
		my $from =
		  $envelope->valueof("/Envelope/Header/{$WSRF::Constants::WSA}To");
		$myHeader .=
"<wsa:From wsu:Id=\"From\"><wsa:EndPointReference><wsa:Address>$from</wsa:Address></wsa:EndPointReference></wsa:From>";
	}

	$myHeader .=
	    "<wsa:MessageID wsu:Id=\"MessageID\">"
	  . WSRF::WS_Address::MessageID()
	  . "</wsa:MessageID>";

	#check for wsa:MessageID in envelope - if it is set use it to
	#create a wsa:RelatesTo element
	my $messageID = $envelope->headerof("//{$WSRF::Constants::WSA}MessageID");
	if ( defined $messageID ) {
		$messageID =
		  $envelope->headerof("//{$WSRF::Constants::WSA}MessageID")->value;
		$myHeader .=
		    "<wsa:RelatesTo wsu:Id=\"RelatesTo\">"
		  . $messageID
		  . "</wsa:RelatesTo>";
	}

	#append anything else the user has given us
	$myHeader .= $anythingelse;

	#create the SOAP::Header object and return to client
	return SOAP::Header->value($myHeader)->type('xml');
}

#===============================================================================
# Base class for the process based WSRF services - a Service can inherit from
# this class to pick up GetResourceProperty, GetMultiResourceProperties and
# SetResourceProperty operations.

package WSRF::WSRP;

=pod 

=head1 WSRF::WSRP

Provides support for WSRF ResourceProperties, the properties of the WS-Resource
are stored in a hash called %WSRF::WSRP::ResourceProperties. 

=head2 METHODS

=over

=item xmlizeProperties 

=item GetResourcePropertyDocument

=item GetResourceProperty

=item GetMultipleResourceProperties

=item SetResourceProperties

=item InsertResourceProperties

=item UpdateResourceProperties 

=item DeleteResourceProperties

=back

=cut

use vars qw(@ISA);

# we inherit this to gain access to the envelope - see SOAP::Lite
@ISA = qw(SOAP::Server::Parameters);

# Hash to store resource properties - we make this effectively
# a globe variable
%WSRF::WSRP::ResourceProperties = ();

# Hash stores the prefix for the resource property
# eg CurrentTime will use the prefix wsrl, the
# map between tthe prefix and the namespace is
# elsewhere
%WSRF::WSRP::PropertyNamespaceMap = ();

# Hash that maps a property and the fuction that
# should be called when aan attempt is made to
# insert that property. Simple properties are
# handled by default.
%WSRF::WSRP::InsertMap = ();

# Hash that maps property to function that should
# be used to delete it - simple properties are
# handled by default
%WSRF::WSRP::DeleteMap = ();

# Hash to define which properties can be "nil" - by
# default properties can not be nil.
%WSRF::WSRP::Nillable = ();

# Hash to define which properties cannot be Deleted
%WSRF::WSRP::NotDeletable = ();

# Hash to define which properties cannot be changed
%WSRF::WSRP::NotModifiable = ();

# Hash to define which properties cannot be inserted
%WSRF::WSRP::NotInsert = ();

# serach for a resource property - this is used by getResourceProperty
# and getMultipleResourceProperties. Takes the ID of the resource
# and the name of the rsource.
#
# BUG - we do not handle namespaces of property!!
sub searchResourceProperty {
	my $longsearch = shift @_;

	#dump the namespace of property
	my ( $junk, $search );
	if ( $longsearch =~ m/:/ ) {
		( $junk, $search ) = split /:/, $longsearch;
	} else {
		$search = $longsearch;
	}

	#default result!!
	my $ans = "";

	#print "Printing keys\n";
	#foreach my $key ( keys %WSRF::WSRP::ResourceProperties)
	#{
	#   print "  key= <$key>\n";
	#}

	#Check Resource property exists, if it does it can either
	#be a simple scalar, an array or a function.
	if ( defined( $WSRF::WSRP::ResourceProperties{$search} ) ) {

		#get type of property
		my $type = ref( $WSRF::WSRP::ResourceProperties{$search} );
		if ( $type eq "" )    # if scalar
		{

			#check if property set
			if ( $WSRF::WSRP::ResourceProperties{$search} ne "" ) {
				$ans .= "<"
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
				  . ":$search ";

				#do we need to add a namespace for this property
				my $ns =
				  defined(
					   $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace} )
				  ? " xmlns:"
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix} . "=\""
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace}
				  . "\">"
				  : ">";
				$ans .= $ns
				  . $WSRF::WSRP::ResourceProperties{$search} . "</"
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
				  . ":$search>";
			}

			#property NOT set - is it nillable?
			elsif ( $WSRF::WSRP::ResourceProperties{$search} eq ""
					&& defined( $WSRF::WSRP::Nillable{$search} ) )
			{
				$ans .= "<"
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
				  . ":$search";
				my $ns =
				  defined(
					   $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace} )
				  ? " xmlns:"
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix} . "=\""
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace}
				  . "\""
				  : " ";
				$ans .= $ns . " xsi:nil=\"true\"/>";
			}
		}

		#property is array of things
		elsif ( $type eq "ARRAY" ) {

			#check array is not empty - and property is nillable
			if ( !@{ $WSRF::WSRP::ResourceProperties{$search} }
				 && defined( $WSRF::WSRP::Nillable{$search} ) )
			{
				$ans .= "<"
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
				  . ":$search";
				my $ns =
				  defined(
					   $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace} )
				  ? " xmlns:"
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix} . "=\""
				  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace}
				  . "\""
				  : " ";
				$ans .= $ns . " xsi:nil=\"true\"/>";
			}

			#loop over array building result
			else {
				foreach
				  my $entry ( @{ $WSRF::WSRP::ResourceProperties{$search} } )
				{
					$ans .= "<"
					  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
					  . ":$search";

					#do we need to add a namespace for this property
					my $ns =
					  defined( $WSRF::WSRP::PropertyNamespaceMap->{$search}
							   {namespace} )
					  ? " xmlns:"
					  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
					  . "=\""
					  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace}
					  . "\">"
					  : ">";
					$ans .=
					    $ns . $entry . "</"
					  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
					  . ":$search>";
				}
			}
		}

		#property is a subroutine - call it to get result
		#example of this is CurrentTime
		elsif ( $type eq "CODE" ) {
			$ans .= $WSRF::WSRP::ResourceProperties{$search}->();
		}

   #Some type we do not understand yet eg. Hash - attempt to serialize it anyway
		else {
			my $serializer = WSRF::SimpleSerializer->new();
			$ans .= "<"
			  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
			  . ":$search";

			#do we need to add a namespace for this property
			my $ns =
			  defined( $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace} )
			  ? " xmlns:"
			  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix} . "=\""
			  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace} . "\">"
			  : ">";

			$ans .= $ns
			  . $serializer->serialize(
									  $WSRF::WSRP::ResourceProperties{$search} )
			  . "</"
			  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
			  . ":$search>";

			#       die SOAP::Fault->faultcode("WSRF::Lite Failure")
			#		      ->faultstring("Could not understand type: $type");
		}

	}

	return $ans;
}

# This creates  XML with all the ResourceProperties in it - we can then
# use the XPath query from queryResourceProperty on it.
# BUG (FIXED(?) But we have not written queryResourceProperty yet - its a
# bad idea anyway so lets  not worry about it.
#
sub xmlizeProperties {

	#my $ans = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
	my $ans =
	    "<wsrp:ResourceProperties"
	  . " xmlns:wsrp=\"$WSRF::Constants::WSRP\" "
	  . " xmlns:wsrl=\"$WSRF::Constants::WSRL\" "
	  . " xmlns:wssg=\"$WSRF::Constants::WSSG\" "
	  . " xmlns:wsa=\"$WSRF::Constants::WSA\" "
	  . " xmlns:xsi=\"http://www.w3.org/1999/XMLSchema-instance\" "
	  . " xmlns:xsd=\"http://www.w3.org/1999/XMLSchema\">";

	foreach my $key ( keys %WSRF::WSRP::ResourceProperties ) {
		$ans .= searchResourceProperty($key);
	}

	$ans .= "</wsrp:ResourceProperties>";

	return $ans;
}

sub GetResourcePropertyDocument {
	my $envelope = pop @_;
	my $xml      = xmlizeProperties();
	return WSRF::Header::header($envelope),
	  SOAP::Data->value($xml)->type('xml');
}

# delete property
# BUG we do not handle namespaces
my $mydelete = sub {
	my ($name) = @_;

	#strip namespace
	$name =~ s/\w*://o;

	#   #check for user defined delete function for this property
	if ( defined( $WSRF::WSRP::DeleteMap{$name} ) ) {
		$WSRF::WSRP::DeleteMap{$name}->();
		return;
	}

	#check we are allowed to delete this function
	#   if( defined( $WSRF::WSRP::NotDeletable{$name} ) )
	#   {
	#     die SOAP::Fault->faultcode("setResourceproperty: Delete Failure")
	#		    ->faultstring("Could not delete $name");
	#   }

	#check property exists
	if ( defined( $WSRF::WSRP::ResourceProperties{$name} ) ) {

		#check type either array or scalar
		my $type = ref( $WSRF::WSRP::ResourceProperties{$name} );
		if ( $type eq "" )    #scalar
		{
			$WSRF::WSRP::ResourceProperties{$name} = "";
		} elsif ( $type eq "ARRAY" )    # array
		{

			#set contents to nothing
			@{ $WSRF::WSRP::ResourceProperties{$name} } = ();
		} else {
			die SOAP::Fault->faultcode("setResourceproperty: Delete Failure")
			  ->faultstring("Could not delete $name");
		}
	} else {
		die SOAP::Fault->faultcode("setResourceproperty: Delete Failure")
		  ->faultstring("No ResourceProperty: $name");
	}
	return;
};

# insert property - this function is used by the Insert and Update
# in the SetResourceProperty operation. This operation takes
# the ID of the resource and a SOAP::SOM object that has been set
# at the property that should be inserted
# Only one property can be inserted at a time using the function -
# SetResourceProperty of course loops over it
my $insert = sub {
	my ($b) = @_;

	#get the name of the property
	my $name = $b->dataof()->name;

	#   #check there is no user defined function
	#   #for inserting this property
	if ( defined( $WSRF::WSRP::InsertMap{$name} ) ) {
		$WSRF::WSRP::InsertMap{$name}->($b);
		return;
	}

	#check this property can be changed
	#   if( defined( $WSRF::WSRP::NotModifiable{$name} ))
	#   {
	#     die SOAP::Fault->faultcode("setResourceproperty: Insert Failure")
	#		    ->faultstring("Could not insert $name");
	#   }

	#get the value of the property
	my $value = $b->dataof()->value;

	#check the property actually exists
	if ( defined( $WSRF::WSRP::ResourceProperties{$name} ) ) {

		#check the type of the property (scalar|array)
		my $type = ref( $WSRF::WSRP::ResourceProperties{$name} );
		if ( $type eq "" )    #scalar
		{
			$WSRF::WSRP::ResourceProperties{$name} = $value;
		} elsif ( $type eq "ARRAY" )    #array
		{

			#add property to array
			push( @{ $WSRF::WSRP::ResourceProperties{$name} }, $value );
		} else                          #perhaps subroutine?
		{
			die SOAP::Fault->faultcode("setResourceproperty: Insert Failure")
			  ->faultstring("Could not insert $name");
		}
	} else {
		die SOAP::Fault->faultcode(
								"setResourceproperty: No such ResourceProperty")
		  ->faultstring("$name is not a ResourceProperty of this WS-Resource");
	}
	return;
};

# we provide an init method in case the service writer does bother - this
# will be called whenever the WS-Resource is created
sub init { return; }

# wsrp GetResourceProperty
sub GetResourceProperty {
	my $envelope = pop @_;

	#print "XML>>>\n".xmlizeProperties()."\n<<<XML\n";

	#search through envelope to the GetResourceProperty bit
	#and get the resource property name
	my $search = $envelope->valueof('//GetResourceProperty/');

	#print "GetResourceProperty = $search\n";
	my $ans = searchResourceProperty($search);

	#print "GetResourceProperty Ans= $ans\n";

	return WSRF::Header::header($envelope),
	  SOAP::Data->value($ans)->type('xml');
}

# wsrp GetMultipleResourceProperties
sub GetMultipleResourceProperties {
	my $envelope = pop @_;

	my $ans = "";    #we will just cat the answers together

	#    print "XML>>>\n".$xmlizeProperties->($ID)."\n<<<XML\n";

	#loop over each ResourceProperty request
	foreach my $search ( $envelope->valueof('//ResourceProperty/') ) {
		$ans .= searchResourceProperty($search);
	}

	return WSRF::Header::header($envelope),
	  SOAP::Data->value($ans)->type('xml');

}

# wsrp SetResourceProperties - the client can request that properties
# are inserted, updated and deleted in the one operation. The commands
# must happen in the order they come in the request, all stop when we
# hit a problem
sub SetResourceProperties {

	#get the envelope
	my $som = pop @_;

	#the base point of all our searchs.
	my $base = "//SetResourceProperties";

	#find the start of commands - should think
	#of this as an array of arries - that is why we have [$jj]/[$kk]
	if ( $som->match($base) ) {
		my $jj = 1;

		#now we loop over commands - $jj records our postion
		while ( $som->dataof("$base/[$jj]") ) {

			#get the command name
			my $Function = $som->dataof("$base/[$jj]")->name();
			if ( $Function eq "Insert" )    #an Insert
			{
				my $kk = 1;

				#loop over the things that have to be inserted
				while ( $som->match("$base/[$jj]/[$kk]") ) {

			 #print "Inserting ".$som->dataof("$base/[$jj]/[$kk]")->name()."\n";
			 #insert the thing - note we pass a SOM object becasue the
					if (
						 !defined(
								   $WSRF::WSRP::NotInsert{ $som->dataof(
												  "$base/[$jj]/[$kk]")->name() }
						 )
					  )
					{
						$insert->( $som->match("$base/[$jj]/[$kk]") );
					}    #thing could be pretty complex.

					$kk++;
				}
			} elsif ( $Function eq "Update" )    #an Update
			{
				my $kk      = 1;
				my %tmpHash = ();

				#loop over things to Update - an update is a Delete followed
				#by an Insert in a single atomic operation
				while ( $som->match("$base/[$jj]/[$kk]") ) {

					#get name of thing we are updating
					my $name = $som->dataof("$base/[$jj]/[$kk]")->name();

			   #print "Updating $name\n";
			   #check we have not deleted it before else delete before inserting
					if ( !defined( $WSRF::WSRP::NotModifiable{$name} ) ) {
						if ( !defined( $tmpHash{$name} ) ) {
							$mydelete->($name);
							$tmpHash{$name} = 1;
						}

						#insert value
						$insert->( $som->match("$base/[$jj]/[$kk]") );
					}
					$kk++;
				}
			} elsif ( $Function eq "Delete" )    #a Delete
			{

				#the property to delete is actually an attribute
				#in the delete element
				my $propname =
				  $som->dataof("$base/[$jj]")->attr->{'resourceProperty'};

				#print "Delete $propname\n";
				#delete property
				if ( !defined( $WSRF::WSRP::NotDeletable{$propname} ) ) {
					$mydelete->($propname);
				}
			} else {    #something other than Insert|Update|Delete
				die SOAP::Fault->faultcode(
										"setResourceproperty: Unkown operation")
				  ->faultstring("$Function not supported - only Insert,Update and Delete are supported"
				  );
			}
			$jj++;
		}
	}

	return WSRF::Header::header($som);
}

sub InsertResourceProperties {
	my $som  = pop @_;
	my $base = "//InsertResourceProperties";
	if ( $som->match($base) ) {
		my $kk = 1;
		while ( $som->match("$base/[1]/[$kk]") ) {
			my $name = $som->dataof("$base/[1]/[$kk]")->name();
			print "Inserting $name\n";

			#insert the thing - note we pass a SOM object becasue the
			#thing could be pretty complex.
			if ( !defined( $WSRF::WSRP::NotInsert{$name} ) ) {
				$insert->( $som->match("$base/[1]/[$kk]") );
			} else {
				die "InvalidInsertResourcePropertiesRequestContent\n";
			}
			$kk++;
		}
	}
	return WSRF::Header::header($som);
}

sub UpdateResourceProperties {
	my $som  = pop @_;
	my $base = "//UpdateResourceProperties";
	if ( $som->match($base) ) {
		my $kk      = 1;
		my %tmpHash = ();
		while ( $som->match("$base/[1]/[$kk]") ) {

			#get name of thing we are updating
			my $name = $som->dataof("$base/[1]/[$kk]")->name();
			print "Updating $name\n";
			if ( !defined( $WSRF::WSRP::NotModifiable{$name} ) ) {

			   #check we have not deleted it before else delete before inserting
				if ( !defined( $tmpHash{$name} ) ) {
					$mydelete->($name);
					$tmpHash{$name} = 1;
				}

				#insert value
				$insert->( $som->match("$base/[1]/[$kk]") );
			} else {
				die "InvalidUpdateResourcePropertiesRequestContent\n";
			}
			$kk++;
		}
	}

	return WSRF::Header::header($som);
}

sub DeleteResourceProperties {
	my $som  = pop @_;
	my $base = "//DeleteResourceProperties";
	if ( $som->match($base) ) {
		my $kk = 1;
		while ( $som->match("$base/[$kk]") ) {
			print "Into Loop inner...\n";

			#the property to delete is actually an attribute
			#in the delete element
			my $propname =
			  $som->dataof("$base/[$kk]")->attr->{'ResourceProperty'};
			$propname =~ s/\w*://o;

			#delete property
			if ( !defined( $WSRF::WSRP::NotDeletable{$propname} ) ) {
				$mydelete->($propname);
			} else {
				die "InvalidDeleteResourcePropertiesRequestContent\n";
			}
			$kk++;
		}
	}

	return WSRF::Header::header($som);
}

#===============================================================================
# The WSRL class, inherits from the WSRF::WSRP class and adds Destroy
# and SetTerminationTime operations. Adds the resource properties
# required wsrl:TerminationTime and wsrl:CurrentTime
#
package WSRF::WSRL;

=pod

=head1 WSRF::WSRL

Provides support for WS-ResourceLifetimes. WS-ResourceLifetime defines
a standard mechanism for controlling the lifetime of a WS-Resource. It
adds the ResourceProperty I<TerminationTime> to the set of ResourceProerties
of the WS-Resource, the I<TerminationTim> cannot be changed through the 
WS-ResourceProperties - it can only be modified using the WS-ResourceLifetime
B<SetTerminationTime> operation.

=head2 METHODS

=over

=item Destroy

=item SetTerminationTime

=back

=cut

use vars qw(@ISA);

@ISA = qw(WSRF::WSRP);

sub init {
	my $self = shift @_;

	# Add TerminationTime as a resource property -
	# initalise to nothing (ie. set TT to infinity)
	$WSRF::WSRP::ResourceProperties{'TerminationTime'} = "";

	# belongs to RsourceLiftetime namespace - defined
	# elsewhere to be wsrl
	$WSRF::WSRP::PropertyNamespaceMap->{TerminationTime}{prefix} = "wsrl";

	# the TerminationTime can be nil.
	$WSRF::WSRP::Nillable{TerminationTime}      = 1;
	$WSRF::WSRP::NotModifiable{TerminationTime} = 1;

	# add resource property CurrentTime - in this
	# case a subroutine that returns the current
	# time in the correct format
	$WSRF::WSRP::ResourceProperties{'CurrentTime'} = sub {
		return "<wsrl:CurrentTime>"
		  . WSRF::Time::ConvertEpochTimeToString()
		  . "</wsrl:CurrentTime>";
	};
	$WSRF::WSRP::PropertyNamespaceMap->{CurrentTime}{prefix} = "wsrl";

	# By default if a resource property is a subroutine
	# then you cannot change it or delete it - however
	# for completeness we set the following
	$WSRF::WSRP::NotDeletable{CurrentTime}  = 1;
	$WSRF::WSRP::NotModifiable{CurrentTime} = 1;
	$WSRF::WSRP::NotInsert{CurrentTime}     = 1;

	$self->SUPER::init();

}

sub Destroy {

	#set alarm to 1, gives us time to return a result
	#before we die
	alarm(1);

	#return nothing except a SOAP HEADER
	return WSRF::Header::header( pop @_ );
}

# wsrl SetTerminationTime - if you want to make a max limit your Resource
# you should override this function in your module.
sub SetTerminationTime {
	my $envelope = pop @_;
	shift @_;    #the first paramter is always the class of the object
	my $time = shift @_;    #the new TerminationTime

	#check for null time - allowed by wsrl, means TT is infinity
	if ( $time eq "" ) {
		$WSRF::WSRP::ResourceProperties{'TerminationTime'} = "";

		#disable alarm
		alarm;
		my $ans =
		    "<wsrl:NewTerminationTime xsi:nil=\"true\" />"
		  . "<wsrl:CurrentTime>"
		  . WSRF::Time::ConvertEpochTimeToString()
		  . "</wsrl:CurrentTime>";

		return WSRF::Header::header($envelope),
		  SOAP::Data->value($ans)->type('xml');
	}

	#BUG this is handled by WSRF::Time::ConvertStringToEpochTime now - should
	#BUG be removed from here
	$time =~ s/\.\d+//;

	#print "Setting TerminationTime to: $time\n";
	#test time is good - this will die if the string is faulty, causing
	#a SOAP fault to be sent to the cli
	#ent
	DateTime::Format::W3CDTF->new->parse_datetime($time);

	my $SecsToLive = WSRF::Time::ConvertStringToEpochTime($time);

	if ( $SecsToLive < time )    # TT is sometime in the past, die now
	{

		#give us time to reply - then die
		alarm 1;
	} else {

		#reset the alarm, this is were you can set a max TT.
		alarm( $SecsToLive - time );
	}

	#reset TerminationTime
	$WSRF::WSRP::ResourceProperties{'TerminationTime'} = $time;

	my $result = "<wsrl:NewTerminationTime>$time</wsrl:NewTerminationTime>";
	$result .=
	    "<wsrl:CurrentTime>"
	  . WSRF::Time::ConvertEpochTimeToString()
	  . "</wsrl:CurrentTime>";

	return WSRF::Header::header($envelope),
	  SOAP::Data->value($result)->type('xml');
}

#===============================================================================
# If the Service inherits from this class then the ResourceProperties are
# stored in a file between calls.
#
package WSRF::FileBasedResourceProperties;

=pod

=head1 WSRF::FileBasedResourceProperties

If a WS-Resource module inherits from this class then its ResourceProperties 
will be stored in a file.

=head2 METHODS

=over

=item GetResourceProperty

=item GetMultipleResourceProperties

=item SetResourceProperties

=item InsertResourceProperties

=item UpdateResourceProperties

=item DeleteResourceProperties

=item GetResourcePropertyDocument

=back

=cut

use vars qw(@ISA);

@ISA = qw(WSRF::WSRP);

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub GetResourceProperty {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);

	#print "TT= ".$WSRF::WSRP::ResourceProperties{TerminationTime}."\n";
	#print "calling SUPER::GetResourceProperty\n";
	my @resp = $self->SUPER::GetResourceProperty($envelope);
	$lock->toFile();
	return @resp;
}

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub GetMultipleResourceProperties {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	my @resp     = $self->SUPER::GetMultipleResourceProperties($envelope);
	$lock->toFile();
	return @resp;
}

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub SetResourceProperties {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	my @resp     = $self->SUPER::SetResourceProperties($envelope);
	$lock->toFile();
	return @resp;
}

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub InsertResourceProperties {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	my @resp     = $self->SUPER::InsertResourceProperties($envelope);
	$lock->toFile();
	return @resp;
}

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub UpdateResourceProperties {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	my @resp     = $self->SUPER::UpdateResourceProperties($envelope);
	$lock->toFile();
	return @resp;
}

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub DeleteResourceProperties {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	my @resp     = $self->SUPER::DeleteResourceProperties($envelope);
	$lock->toFile();
	return @resp;
}

# Load the ResourceProperties from the file into the ResourceProperties hash
# then call the super operation.
sub GetResourcePropertyDocument {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	my @resp     = $self->SUPER::GetResourcePropertyDocument($envelope);
	$lock->toFile();
	return @resp;
}

#=============================================================================
# Inherits from WSRF::FileBasedResourceProperties, adds the WSRL operations
# to the Service. Again all the ResourceProperties are stored in a file
# between calls - the name of the file is the same as the Resource ID
#

package WSRF::FileBasedResourceLifetimes;

=pod

=head1 WSRF::FileBasedResourceLifetimes

If a WS-Resource wants to store its state in a file and wants to support 
WS-ResourceLifetimes it should inherit from this class. 
WSRF::FileBasedResourceLifetimes inherits from 
WSRF::FileBasedResourceProperties.

=head2 METHODS

=over

=item Destroy

=item SetTerminationTime

=back

=cut

use vars qw(@ISA);

@ISA = qw(WSRF::FileBasedResourceProperties);

#Add TerminationTime as a reource property -
#initalise to nothing (infinity)
$WSRF::WSRP::ResourceProperties{'TerminationTime'} = "";

#belongs to RsourceLiftetime namespace - defined
#elsewhere to be wsrl
$WSRF::WSRP::PropertyNamespaceMap->{TerminationTime}{prefix} = "wsrl";

#the TerminationTime can be nil
$WSRF::WSRP::Nillable{TerminationTime}      = 1;
$WSRF::WSRP::NotModifiable{TerminationTime} = 1;

#add resource property CurrentTime - in this
#case a subroutine that returns the current
#time in the correct format
$WSRF::WSRP::ResourceProperties{'CurrentTime'} = sub {
	return "<wsrl:CurrentTime>"
	  . WSRF::Time::ConvertEpochTimeToString()
	  . "</wsrl:CurrentTime>";
};
$WSRF::WSRP::PropertyNamespaceMap->{CurrentTime}{prefix} = "wsrl";

#By default if a resource property is a subroutine
#then you cannot change it or delete it - however
#for completeness we set the following
$WSRF::WSRP::NotDeletable{CurrentTime}  = 1;
$WSRF::WSRP::NotModifiable{CurrentTime} = 1;

# remove the file with the resource properties in it.
sub Destroy {
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	my $file     = $WSRF::Constants::Data . $lock->ID();
	unlink $file
	  or die SOAP::Fault->faultcode("Container Failure")
	  ->faultstring("Container Failure: could not remove file");
	return WSRF::Header::header($envelope);
}

# load the properties from the file into the hash then
# set the termination time and store back to the file.
sub SetTerminationTime {
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	shift @_;    #the first paramter is always the class of the object
	my $time = shift @_;    #the new TerminationTime

	#check for null time - allowed by wsrl
	my ($ans);
	if ( $time eq "" ) {
		$WSRF::WSRP::ResourceProperties{'TerminationTime'} = "";

		my $ans =
		    "<wsrl:NewTerminationTime xsi:nil=\"true\" />"
		  . "<wsrl:CurrentTime>"
		  . WSRF::Time::ConvertEpochTimeToString(time)
		  . "</wsrl:CurrentTime>";
	} else {

		#BUG - this is done in ConvertEpochTimeToString now so we can drop it
		$time =~ s/\.\d+//;

		#print "Setting TerminationTime to: $time\n";

		#test time is good - this will die if the string is faulty, causing
		#a SOAP fault to be sent to the client
		DateTime::Format::W3CDTF->new->parse_datetime($time);

		#reset TerminationTime
		$WSRF::WSRP::ResourceProperties{'TerminationTime'} = $time;

		$ans = "<wsrl:NewTerminationTime>$time</wsrl:NewTerminationTime>";
		$ans .=
		    "<wsrl:CurrentTime>"
		  . WSRF::Time::ConvertEpochTimeToString()
		  . "</wsrl:CurrentTime>";
	}

	$lock->toFile();
	return WSRF::Header::header($envelope),
	  SOAP::Data->value($ans)->type('xml');
}

#===============================================================================
# In this case a single process acts on behave of a number of
# Resources - the resource properties are all held in a hash - the
# ID of the resource is used as the key to the hash. The Container
# talks to the process through a named UNIX socket - the name of the
# socket is the same as the name of the module.
#
package WSRF::MultiResourceProperties;

=pod

=head1 WSRF::MultiResourceProperties

In this case a single process acts on behave of a number of
WS-Resources. The I<ResourceProperties> are all held in a hash - the
WSRF::Lite identifier of the WS-Resource is used as the key to the hash. 
The WSRF::Lite I<Container> talks to the process through a named UNIX socket 
- the name of the socket is the same as the name of the module.
The WS-Resource module should inherit this class

=head2 METHODS

=over

=item GetResourcePropertyDocument

=item GetResourceProperty

=item GetMultipleResourceProperties

=item SetResourceProperties

=item InsertResourceProperties

=item UpdateResourceProperties 

=item DeleteResourceProperties

=back

=cut

use vars qw(@ISA);

#we inherit this to gain access to the envelope - see SOAP::Lite
@ISA = qw(SOAP::Server::Parameters);

# For this example all Resources are managed by one process,
# a hash holds an entry for each resource, the same hash
# also holds all the resource properties for each resource

#Hash to store each resource and its properties
%WSRF::MultiResourceProperties::ResourceProperties = ();

# Hash stores the prefix for the resource property
# eg CurrentTime will use the prefix wsrl, the
# map between tthe prefix and the namespace is
# elsewhere
%WSRF::MultiResourceProperties::PropertyNamespaceMap = ();

# Hash that maps a property and the fuction that
# should be called when aan attempt is made to
# insert that property. Simple properties are
# handled by default.
%WSRF::MultiResourceProperties::InsertMap = ();

# Hash that maps property to function that should
# be used to delete it - simple properties are
# handled by default
%WSRF::MultiResourceProperties::DeleteMap = ();

# Hash to define which properties can be "nil" - by
# default properties can not be nil.
%WSRF::MultiResourceProperties::Nillable = ();

# Hash to define which properties cannot be Deleted
%WSRF::MultiResourceProperties::NotDeletable = ();

# Hash to define which properties cannot be changed
%WSRF::MultiResourceProperties::NotModifiable = ();

%WSRF::MultiResourceProperties::NotInsert = ();

# get the Resource ID from the envelope - check that it is in the
# hash and check the termination time for the resource.
# BUG - should we check the TT for all resources and do Garbag Collection
#       pro-actively
sub getID {
	my $envelope = shift;

	#print STDERR "Calling getID...\n";
	#search for ResourceID in Header
	my $ID = $envelope->headerof("//{$WSRF::Constants::WSA}To");
	if ( defined $ID ) {
		$ID = $envelope->headerof("//{$WSRF::Constants::WSA}To")->value;
	} else {
		die SOAP::Fault->faultcode('No WS-Resource Identifier')
		  ->faultstring('No Resource Identifier in SOAP Header');
	}

	my @PathArray = split( /\//, $ID );
	$ID = pop @PathArray;

	#print STDERR "ID => $ID\n";

	#check the Resource actually exists or die
	if ( !defined( $WSRF::MultiResourceProperties::ResourceProperties->{$ID} ) )
	{
		die SOAP::Fault->faultcode('No WS-Resource')
		  ->faultstring("No Resource with Identifier $ID");
	}

	#check that the resource is still alive - if TT time is not
	#set then TT is infinity
	foreach
	  my $key ( keys %{$WSRF::MultiResourceProperties::ResourceProperties} )
	{
		if (
			 defined(
					  $WSRF::MultiResourceProperties::ResourceProperties->{$key}
						{'TerminationTime'}
			 )
			 && ( $WSRF::MultiResourceProperties::ResourceProperties->{$key}
				  {'TerminationTime'} ne "" )
		  )
		{
			if (
				 WSRF::Time::ConvertStringToEpochTime(
					  $WSRF::MultiResourceProperties::ResourceProperties->{$key}
						{'TerminationTime'}
				 ) < time
			  )
			{
				print STDERR "MultiResourceProperties Resource $key Expired\n";
				delete
				  $WSRF::MultiResourceProperties::ResourceProperties->{$key};
			}
		}
	}

	#check the Resource actually exists or die
	if ( !defined( $WSRF::MultiResourceProperties::ResourceProperties->{$ID} ) )
	{
		die SOAP::Fault->faultcode('No WS-Resource')
		  ->faultstring("No Resource with Identifier $ID");
	}

	#could set as ENV variable?
	return $ID;
}

# serach for a resource property - this is used by getResourceProperty
# and getMultipleResourceProperties. Takes the ID of the resource
# and the name of the rsource.
# BUG - we do not handle namespaces of peroperty!!
my $MultisearchResourceProperty = sub {
	my %args       = @_;
	my $ID         = $args{ID};
	my $longsearch = $args{property};

	#dump the namespace of property
	my ( $junk, $search );
	if ( $longsearch =~ m/:/ ) {
		( $junk, $search ) = split /:/, $longsearch;
	} else {
		$search = $longsearch;
	}

	#default result!!
	my $ans = "";

	#Check Resource property exists, if it does it can either
	#be a simple scalar, an array or a function.
	if (
		 defined(   $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{$search}
		 )
	  )
	{

		#get type of property
		my $type =
		  ref( $WSRF::MultiResourceProperties::ResourceProperties->{$ID}
			   {$search} );
		if ( $type eq "" )    # if scalar
		{

			#check if property set
			if ( $WSRF::MultiResourceProperties::ResourceProperties->{$ID}
				 {$search} ne "" )
			{
				$ans .= "<"
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{prefix} . ":$search ";

				#do we need to add a namespace for this property
				my $ns =
				  defined( $WSRF::MultiResourceProperties::PropertyNamespaceMap
						   ->{$search}{namespace} )
				  ? " xmlns:"
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{prefix} . "=\""
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{namespace} . "\">"
				  : ">";
				$ans .= $ns
				  . $WSRF::MultiResourceProperties::ResourceProperties->{$ID}
				  {$search} . "</"
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{prefix} . ":$search>";
			}

			#property NOT set - is it nillable?
			elsif ( $WSRF::MultiResourceProperties::ResourceProperties->{$ID}
				 {$search} eq ""
				 && defined( $WSRF::MultiResourceProperties::Nillable{$search} )
			  )
			{
				$ans .= "<"
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{prefix} . ":$search";
				my $ns =
				  defined( $WSRF::MultiResourceProperties::PropertyNamespaceMap
						   ->{$search}{namespace} )
				  ? " xmlns:"
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{prefix} . "=\""
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{namespace} . "\""
				  : " ";
				$ans .= $ns . " xsi:nil=\"true\"/>";
			}
		}

		#property is array of things
		elsif ( $type eq "ARRAY" ) {

			#check array is not empty - and property is nillable
			if (
				 !@{
					 $WSRF::MultiResourceProperties::ResourceProperties->{$ID}
					   {$search}
				 }
				 && defined( $WSRF::MultiResourceProperties::Nillable{$search} )
			  )
			{
				$ans .= "<"
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{prefix} . ":$search";
				my $ns =
				  defined( $WSRF::MultiResourceProperties::PropertyNamespaceMap
						   ->{$search}{namespace} )
				  ? " xmlns:"
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{prefix} . "=\""
				  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
				  ->{$search}{namespace} . "\""
				  : " ";
				$ans .= $ns . " xsi:nil=\"true\"/>";
			}

			#loop over array building result
			else {
				foreach my $entry (
						  @{
							  $WSRF::MultiResourceProperties::ResourceProperties
								->{$ID}{$search}
						  }
				  )
				{
					$ans .= "<"
					  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
					  ->{$search}{prefix} . ":$search";

					#do we need to add a namespace for this property
					my $ns =
					  defined(
							$WSRF::MultiResourceProperties::PropertyNamespaceMap
							  ->{$search}{namespace} )
					  ? " xmlns:"
					  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
					  ->{$search}{prefix} . "=\""
					  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
					  ->{$search}{namespace} . "\">"
					  : ">";
					$ans .=
					    $ns . $entry . "</"
					  . $WSRF::MultiResourceProperties::PropertyNamespaceMap
					  ->{$search}{prefix} . ":$search>";
				}
			}
		}

		#property is a subroutine - call it to get result
		#example of this is CurrentTime
		elsif ( $type eq "CODE" ) {
			$ans .=
			  $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{$search}
			  ->();
		}

		#Some type we do not understand yet eg. Hash
		else {

			my $serializer = WSRF::SimpleSerializer->new();
			$ans .= "<"
			  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
			  . ":$search";

			#do we need to add a namespace for this property
			my $ns =
			  defined( $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace} )
			  ? " xmlns:"
			  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix} . "=\""
			  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{namespace} . "\">"
			  : ">";

			$ans .= $ns
			  . $serializer->serialize(
							   $WSRF::WSRP::ResourceProperties->{$ID}{$search} )
			  . "</"
			  . $WSRF::WSRP::PropertyNamespaceMap->{$search}{prefix}
			  . ":$search>";

			#die "Do not understand type\n";
		}

	}

	return $ans;
};

# This creates  XML with all the ResourceProperties in it - we can then
# use the XPath query from queryResourceProperty on it.
# BUG - we have not written queryResourceProperty
my $xmlizeProperties = sub {
	my $ID = shift @_;

	if ( !defined($ID) || $ID eq "" ) {
		die "Attempt to call xmlizeProperties without ID\n";
	}

	#print "$$ MultiSession xmlizeProperties called for $ID\n";

	#my $ans = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
	my $ans =
	    "<wsrp:ResourceProperties"
	  . " xmlns:wsrp=\"$WSRF::Constants::WSRP\" "
	  . " xmlns:wsrl=\"$WSRF::Constants::WSRL\" "
	  . " xmlns:wsa=\"$WSRF::Constants::WSA\" >";

	foreach my $key (
		   keys %{ $WSRF::MultiResourceProperties::ResourceProperties->{$ID} } )
	{
		$ans .= $MultisearchResourceProperty->( ID => $ID, property => $key );
	}

	$ans .= "</wsrp:ResourceProperties>";

	return $ans;
};

sub GetResourcePropertyDocument {
	my $envelope = pop @_;
	my $ID       = getID($envelope);
	print "$$ Called GetResourcePropertyDocument, ID= $ID\n";
	my $xml = $xmlizeProperties->($ID);
	return WSRF::Header::header($envelope),
	  SOAP::Data->value($xml)->type('xml');
}

# insert property - this function is used by the Insert and Update
# in the SetResourceProperty operation. This operation takes
# the ID of the resource and a SOAP::SOM object that has been set
# at the property that should be inserted
# Only one property can be inserted at a time using the function -
# SetResourceProperty of course loops over it
my $Multiinsert = sub {
	my %args = @_;
	my $ID   = $args{ID};
	my $b    = $args{som};

	#get the name of the property
	my $name = $b->dataof()->name;

	#check there is no user defined function
	#for inserting this property
	if ( defined( $WSRF::MultiResourceProperties::InsertMap{$name} ) ) {
		$WSRF::MultiResourceProperties::InsertMap{$name}->( $ID, $b );
		return;
	}

	#check this property can be changed
	#   if( defined( $WSRF::MultiResourceProperties::NotModifiable{$name} ))
	#   {
	#     die SOAP::Fault->faultcode("setResourceproperty: Failure")
	#		    ->faultstring("Could not modify $name");
	#   }

	#get the value of the property
	my $value = $b->dataof()->value;

	#check the property actually exists
	if (
		 defined(     $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{$name}
		 )
	  )
	{

		#check the type of the property (scalar|array)
		my $type =
		  ref(
			 $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{$name} );
		if ( $type eq "" )    #scalar
		{
			$WSRF::MultiResourceProperties::ResourceProperties->{$ID}{$name} =
			  $value;
		} elsif ( $type eq "ARRAY" )    #array
		{

			#add property to array
			push(
				  @{
					  $WSRF::MultiResourceProperties::ResourceProperties->{$ID}
						{$name}
					},
				  $value
			);
		} else                          #perhaps subroutine?
		{
			die SOAP::Fault->faultcode("setResourceproperty: Failure")
			  ->faultstring("Could not modify $name");
		}
	} else {
		die SOAP::Fault->faultcode("No such WS-Resource")
		  ->faultstring("No such WS-Resource with identifier $ID");
	}
	return;
};

# delete property
# BUG we do not handle namespaces
my $Multimydelete = sub {
	my %args = @_;
	my $ID   = $args{ID};
	my $name = $args{property};

	#strip namespace
	$name =~ s/\w*://;

	#check for user defined delete function for this property
	if ( defined( $WSRF::MultiResourceProperties::DeleteMap{$name} ) ) {
		$WSRF::MultiResourceProperties::DeleteMap{$name}->($ID);
		return;
	}

	#check we are allowed to delete this function
	#   if( defined( $WSRF::MultiResourceProperties::NotDeletable{$name} ) )
	#   {
	#     die SOAP::Fault->faultcode("setResourceproperty: Delete Failure")
	#		     ->faultstring("Could not delete $name");
	#   }

	#check property exists
	if (
		 defined(     $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{$name}
		 )
	  )
	{

		#check type either array or scalar
		my $type =
		  ref(
			 $WSRF::MultiResourceProperties::ResourceProperties->{$ID}{$name} );
		if ( $type eq "" )    #scalar
		{
			$WSRF::MultiResourceProperties::ResourceProperties->{$ID}{$name} =
			  "";
		} elsif ( $type eq "ARRAY" )    # array
		{

			#set contents to nothing
			@{ $WSRF::MultiResourceProperties::ResourceProperties->{$ID}
				  {$name} } = ();
		} else {
			die SOAP::Fault->faultcode("setResourceproperty: Delete Failure")
			  ->faultstring("Could not delete $name");
		}
	} else {
		die SOAP::Fault->faultcode("No such WS-Resource")
		  ->faultstring("No WS-Resource with identifier $ID");
	}
	return;
};

# provide a default init - incase the service developer doesn't bother
sub init { return; }

# wsrp GetResourceProperty
sub GetResourceProperty {
	my $envelope = pop @_;
	my $ID       = getID($envelope);

	#search through envelope to the GetResourceProperty bit
	#and get the resource property name
	my $search = $envelope->valueof('//GetResourceProperty/');

	my $ans = $MultisearchResourceProperty->(    ID       => $ID,
											  property => $search );

	return WSRF::Header::header($envelope),
	  SOAP::Data->value($ans)->type('xml');
}

# wsrp GetMultipleResourceProperties
sub GetMultipleResourceProperties {
	my $envelope = pop @_;
	my $ID       = getID($envelope);

	my $ans = "";    #we will just cat the answers together

	#    print "XML>>>\n".$xmlizeProperties->($ID)."\n<<<XML\n";

	#loop over each ResourceProperty request
	foreach my $search ( $envelope->valueof('//ResourceProperty/') ) {
		$ans .= $MultisearchResourceProperty->(       ID       => $ID,
												property => $search );
	}

	return WSRF::Header::header($envelope),
	  SOAP::Data->value($ans)->type('xml');

}

# wsrp SetResourceProperties - the client can request that properties
# are inserted, updated and deleted in the one operation. The commands
# must happen in the order they come in the request, all stop when we
# hit a problem
sub SetResourceProperties {

	#get the envelope
	my $som = pop @_;
	my $ID  = getID($som);

	#the base point of all our searchs.
	my $base = "//SetResourceProperties";

	#find the start of commands - should think
	#of this as an array of arries - that is why we have [$jj]/[$kk]
	if ( $som->match($base) ) {
		my $jj = 1;

		#now we loop over commands - $jj records our postion
		while ( $som->dataof("$base/[$jj]") ) {

			#get the command name
			my $Function = $som->dataof("$base/[$jj]")->name();
			if ( $Function eq "Insert" )    #an Insert
			{
				my $kk = 1;

				#loop over the things that have to be inserted
				while ( $som->match("$base/[$jj]/[$kk]") ) {

			 #print "Inserting ".$som->dataof("$base/[$jj]/[$kk]")->name()."\n";
			 #insert the thing - note we pass a SOM object becasue the
			 #thing could be pretty complex.
					if (
						 !defined(
								 $WSRF::MultiResourceProperties::NotInsert{ $som
									   ->dataof("$base/[$jj]/[$kk]")->name() }
						 )
					  )
					{
						$Multiinsert->(                   ID  => $ID,
										som => $som->match("$base/[$jj]/[$kk]") );
					}
					$kk++;
				}
			} elsif ( $Function eq "Update" )    #an Update
			{
				my $kk      = 1;
				my %tmpHash = ();

				#loop over things to Update - an update is a Delete followed
				#by an Insert in a single atomic operation
				while ( $som->match("$base/[$jj]/[$kk]") ) {

					#get name of thing we are updating
					my $name = $som->dataof("$base/[$jj]/[$kk]")->name();

			   #print "Updating $name\n";
			   #check we have not deleted it before else delete before inserting
					if (
						!defined(             $WSRF::MultiResourceProperties::NotModifiable{$name}
						)
					  )
					{
						if ( !defined( $tmpHash{$name} ) ) {
							$Multimydelete->(                      ID       => $ID,
											  property => $name );
							$tmpHash{$name} = 1;
						}

						#insert value
						$Multiinsert->(                   ID  => $ID,
										som => $som->match("$base/[$jj]/[$kk]") );
					}
					$kk++;
				}
			} elsif ( $Function eq "Delete" )    #a Delete
			{

				#the property to delete is actually an attribute
				#in the delete element
				my $propname =
				  $som->dataof("$base/[$jj]")->attr->{'resourceProperty'};

				#print "Delete $propname\n";
				#delete property
				if (
					 !defined(          $WSRF::MultiResourceProperties::NotDeletable{$propname}
					 )
				  )
				{
					$Multimydelete->(                ID       => $ID,
									  property => $propname );
				}
			} else {    #something other than Insert|Update|Delete
				die SOAP::Fault->faultcode("setResourceproperty: Failure")
				  ->faultstring("setResourceProperty does not support $Function: only Insert, Update and Delete are supported"
				  );
			}
			$jj++;
		}
	}

	return WSRF::Header::header($som);
}

sub InsertResourceProperties {
	my $som  = pop @_;
	my $ID   = getID($som);
	my $base = "//InsertResourceProperties";
	if ( $som->match($base) ) {
		my $kk = 1;
		while ( $som->match("$base/[1]/[$kk]") ) {
			my $name = $som->dataof("$base/[1]/[$kk]")->name();
			print "Inserting $name\n";

			#insert the thing - note we pass a SOM object becasue the
			#thing could be pretty complex.
			if ( !defined( $WSRF::MultiResourceProperties::NotInsert{$name} ) )
			{
				$Multiinsert->(             ID  => $ID,
								som => $som->match("$base/[1]/[$kk]") );
			} else {
				die "InvalidInsertResourcePropertiesRequestContent\n";
			}
			$kk++;
		}
	}
	return WSRF::Header::header($som);
}

sub UpdateResourceProperties {
	my $som  = pop @_;
	my $ID   = getID($som);
	my $base = "//UpdateResourceProperties";
	if ( $som->match($base) ) {
		my $kk      = 1;
		my %tmpHash = ();
		while ( $som->match("$base/[1]/[$kk]") ) {

			#get name of thing we are updating
			my $name = $som->dataof("$base/[1]/[$kk]")->name();
			print "Updating $name\n";
			if (
				 !defined(             $WSRF::MultiResourceProperties::NotModifiable{$name}
				 )
			  )
			{

			   #check we have not deleted it before else delete before inserting
				if ( !defined( $tmpHash{$name} ) ) {
					$Multimydelete->(                ID       => $ID,
									  property => $name );
					$tmpHash{$name} = 1;
				}

				#insert value
				$Multiinsert->(             ID  => $ID,
								som => $som->match("$base/[1]/[$kk]") );
			} else {
				die "InvalidUpdateResourcePropertiesRequestContent\n";
			}
			$kk++;
		}
	}

	return WSRF::Header::header($som);
}

sub DeleteResourceProperties {
	my $som  = pop @_;
	my $ID   = getID($som);
	my $base = "//DeleteResourceProperties";
	if ( $som->match($base) ) {
		my $kk = 1;
		while ( $som->match("$base/[$kk]") ) {
			print "Into Loop inner...\n";

			#the property to delete is actually an attribute
			#in the delete element
			my $propname =
			  $som->dataof("$base/[$kk]")->attr->{'ResourceProperty'};
			$propname =~ s/\w*://o;

			#delete property
			if (
				 !defined(           $WSRF::MultiResourceProperties::NotDeletable{$propname}
				 )
			  )
			{
				$Multimydelete->(             ID       => $ID,
								  property => $propname );
			} else {
				die "InvalidDeleteResourcePropertiesRequestContent\n";
			}
			$kk++;
		}
	}

	return WSRF::Header::header($som);
}

#===============================================================================
# The extension to WSRF::MultiResourceProperties that supports WSRL - adding
# the operations Destroy and SetTerminationTime
#
package WSRF::MultiResourceLifetimes;

=pod

=head1 WSRF::MultiResourceLifetimes

Extends WSRF::MultiResourceProperties to add support for WS-ResourceLifetime.

=head2 METHODS

=over

=item Destroy

=item SetTerminationTime

=back 

=cut

use vars qw(@ISA);

@ISA = qw(WSRF::MultiResourceProperties);

# wsrl Destroy
sub Destroy {
	my $envelope = pop @_;
	my $ID       = WSRF::MultiResourceProperties::getID($envelope);

	delete $WSRF::MultiResourceProperties::ResourceProperties->{$ID};

	#return nothing except a SOAP HEADER
	return WSRF::Header::header($envelope);
}

# wsrl SetTerminationTime
sub SetTerminationTime {
	my $envelope = pop @_;
	shift @_;    #the first paramter is always the class of the object
	my $time = shift @_;    #the new TerminationTime
	my $ID = WSRF::MultiResourceProperties::getID($envelope);

	#check for null time - allowed by wsrl
	if ( $time eq "" ) {
		$WSRF::MultiResourceProperties::ResourceProperties->{$ID}
		  {'TerminationTime'} = "";

		my $ans =
		    "<wsrl:NewTerminationTime xsi:nil=\"true\" />"
		  . "<wsrl:CurrentTime>"
		  . WSRF::Time::ConvertEpochTimeToString(time)
		  . "</wsrl:CurrentTime>";

		return WSRF::Header::header($envelope),
		  SOAP::Data->value($ans)->type('xml');
	}

	#BUG - with DateTime::Format::W3CDTF - does not
	#like subseconds - should patch DateTime::Format::W3CDTF
	#print "Called SetTerminationTime: $time\n";
	$time =~ s/\.\d+//;

	#print "Setting TerminationTime to: $time\n";

	#test time is good - this will die if the string is faulty, causing
	#a SOAP fault to be sent to the client
	DateTime::Format::W3CDTF->new->parse_datetime($time);

	#reset TerminationTime
	$WSRF::MultiResourceProperties::ResourceProperties->{$ID}
	  {'TerminationTime'} = $time;

	my $result = "<wsrl:NewTerminationTime>$time</wsrl:NewTerminationTime>";
	$result .=
	    "<wsrl:CurrentTime>"
	  . WSRF::Time::ConvertEpochTimeToString()
	  . "</wsrl:CurrentTime>";

	return WSRF::Header::header($envelope),
	  SOAP::Data->value($result)->type('xml');
}

#===============================================================================
# This package is for supporting ServiceGroups:
# http://www.globus.org/wsrf/specs/ws-servicegroup.pdf
#
# ServiceGroups allows you to bunch a set of WS-Resources
# together. They are the building blocks of Registries
#
#
package WSRF::ServiceGroup;

=pod

=head1 WSRF::ServiceGroup

Provides support for WS-ServiceGroups. This implementation of WS-ServiceGroups
stores the state of the WS-ServiceGroup in a file, it extends 
WSRF::FileBasedResourceLifetimes.

=head2 METHODS

=over

=item Add

Adds a WS-Resource to the ServiceGroup

=item createServiceGroup

Creates a new ServiceGroup

=back

=cut

use vars qw(@ISA);

@ISA = qw(WSRF::FileBasedResourceLifetimes);

# foo is an array of things
$WSRF::WSRP::ResourceProperties{Entry}                = [];
$WSRF::WSRP::PropertyNamespaceMap->{Entry}{prefix}    = "wssg";
$WSRF::WSRP::PropertyNamespaceMap->{Entry}{namespace} = $WSRF::Constants::WSSG;
$WSRF::WSRP::NotDeletable{Entry} = 1; #Cannot delete through SetResourceProperty
$WSRF::WSRP::NotModifiable{Entry} =
  1;                                  #Cannot modify through SetResourceProperty

$WSRF::WSRP::ResourceProperties{ServiceGroupEPR}                = "";
$WSRF::WSRP::PropertyNamespaceMap->{ServiceGroupEPR}{prefix}    = "wssg";
$WSRF::WSRP::PropertyNamespaceMap->{ServiceGroupEPR}{namespace} =
  $WSRF::Constants::WSSG;
$WSRF::WSRP::NotDeletable{ServiceGroupEPR} =
  1;                                  #Cannot delete through SetResourceProperty
$WSRF::WSRP::NotModifiable{ServiceGroupEPR} =
  1;                                  #Cannot modify through SetResourceProperty

# The module name and path to use when creating a new entry
# in the SG.  Can be overridden by any module that subclasses this one.
$WSRF::ServiceGroup::ServiceGroupEntryModule = "ServiceGroupEntry";
$WSRF::ServiceGroup::ServiceGroupEntryPath   = "Session/ServiceGroupEntry/";

$WSRF::WSRP::InsertMap{ServiceGroupEPR} = sub {
	my ($som) = @_;

	print STDERR
	  "ServiceGroup WSRF::WSRP::InsertMap{ServiceGroupEPR}  called\n";

	my $serializer = new WSRF::SimpleSerializer;

	#print STDERR "$$ WSRF::ServiceGroup serializing ServiceGroupEPR\n";
	$WSRF::WSRP::ResourceProperties{ServiceGroupEPR} =
	  $serializer->serialize( $som->dataof('[1]') );
};

$WSRF::WSRP::InsertMap{Entry} = sub {
	my ($som) = @_;

	print STDERR "ServiceGroup WSRF::WSRP::InsertMap{Entry}  called\n";

	my $serializer = new WSRF::SimpleSerializer;

	#We store the entry as follows
	#   MemberServiceEPR
	#   ServiceGroupEntryEPR
	#   Content (optional)
	#   EntryTerminationTime
	#We will use EntryTerminationTime as a marker

	#get MemberServiceEPR
	my $Entry = $serializer->serialize( $som->dataof('[1]') );

	#get ServiceGroupEntryEPR
	$Entry .= $serializer->serialize( $som->dataof('[2]') );

	#Get the Content
	my $ContentorTime = $serializer->serialize( $som->dataof('[3]') );

	my $Time = "";
	if ( $ContentorTime =~ m/EntryTerminationTime/o ) {
		$Time = $ContentorTime;
		$Entry .= $Time;
	} else {
		$Entry .= $ContentorTime;
		$Time = $serializer->serialize( $som->dataof('[4]') );
		$Entry .= $Time;
	}

	#print STDERR "$$ Entry= $Entry\n\n";

	#strip xml tags away from time
	$Time =~ s/<\/?EntryTerminationTime\/?>//og;

	#print STDERR "$$ TerminationTime for Entry= $Time\n";

	if ( $Time eq "nil" )    #No TerminationTime
	{
		push( @{ $WSRF::WSRP::ResourceProperties{Entry} }, $Entry );
	} else {

		#check TerminationTime
		if ( WSRF::Time::ConvertStringToEpochTime($Time) > time ) {
			push( @{ $WSRF::WSRP::ResourceProperties{Entry} }, $Entry );
		}
	}

};

my $strip_old_Entries = sub {
	my $parser = new XML::DOM::Parser;
	my @tmp    = @{ $WSRF::WSRP::ResourceProperties{Entry} };
	@{ $WSRF::WSRP::ResourceProperties{Entry} } = ();
	foreach my $entry (@tmp) {
		my $tmpentry = "<t>" . $entry . "</t>";
		my $doc      = $parser->parse($tmpentry);

		#print STDERR "Parsed document..\n";
		my $TermTime =
		  defined( $doc->getElementsByTagName("EntryTerminationTime")->item(0)
				   ->getFirstChild )
		  ? $doc->getElementsByTagName("EntryTerminationTime")->item(0)
		  ->getFirstChild->getNodeValue
		  : "";

		next
		  if (    ( $TermTime ne "nil" )
			   && ( WSRF::Time::ConvertStringToEpochTime($TermTime) < time ) );

		push @{ $WSRF::WSRP::ResourceProperties{Entry} }, $entry;
		$doc->dispose;
	}

};

# wsrp GetResourceProperty
sub GetResourceProperty {
	my $self     = shift @_;
	my $envelope = pop @_;

	my $lock = WSRF::File->new($envelope);
	$strip_old_Entries->();

	my $search = $envelope->valueof('//GetResourceProperty/');

	#strip namespace - BUG we should handle namespaces properly and
	#not just ignore them
	$search =~ s/\w*://o;

	my $ans = "";

	#print STDERR "GetResourceProperty = $search\n";
	if ( $search eq "Entry" ) {
		foreach my $entry ( @{ $WSRF::WSRP::ResourceProperties{Entry} } ) {
			$ans .= "<wssg:Entry xmlns:wssg=\"$WSRF::Constants::WSSG\">";

			#BUG - why must we take a copy?
			my $tmp = $entry;
			$tmp =~ s/<EntryTerminationTime\/>//o;
			$tmp =~ s/<EntryTerminationTime>\w*<\/EntryTerminationTime>//o;
			$ans .= $tmp;
			$ans .= "</wssg:Entry>";
		}
	} else {
		$ans = WSRF::WSRP::searchResourceProperty($search);
	}

	$lock->toFile();
	return WSRF::Header::header($envelope),
	  SOAP::Data->value($ans)->type('xml');
}

# wsrp GetMultipleResourceProperties
sub GetMultipleResourceProperties {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $lock     = WSRF::File->new($envelope);
	$strip_old_Entries->();

  #print ">>>>BEFORE>>>>\n".WSRF::WSRP::xmlizeProperties()."\n<<<<<<<<<<<<\n\n";

	my $ans = "";    #we will just cat the answers together

	#    print "XML>>>\n".$xmlizeProperties->($ID)."\n<<<XML\n";

	#loop over each ResourceProperty request
	foreach my $search ( $envelope->valueof('//ResourceProperty/') ) {

		#strip namespace
		$search =~ s/\w*://o;
		if ( $search eq "Entry" ) {
			foreach my $entry ( @{ $WSRF::WSRP::ResourceProperties{Entry} } ) {
				$ans .= "<wssg:Entry xmlns:wssg=\"$WSRF::Constants::WSSG\">";

				#BUG - why must we take a copy?
				my $tmp = $entry;
				$tmp =~ s/<EntryTerminationTime\/>//o;
				$tmp =~ s/<EntryTerminationTime>\w*<\/EntryTerminationTime>//o;
				$ans .= $tmp;
				$ans .= "</wssg:Entry>";
			}
		} else {
			$ans .= WSRF::WSRP::searchResourceProperty($search);
		}
	}

#print STDERR ">>>>AFTER>>>>\n".WSRF::WSRP::xmlizeProperties()."\n<<<<<<<<<<<<\n\n";

	$lock->toFile();
	return WSRF::Header::header($envelope),
	  SOAP::Data->value($ans)->type('xml');
}

# operation to create a new File based Counter
sub createServiceGroup {
	my $envelope = pop @_;
	my ( $class, @params ) = @_;

	# get an ID for the Resource
	my $ID = WSRF::GSutil::CalGSH_ID();

	#create a WS-Address for the Resource
	my $wsa = WSRF::GSutil::createWSAddress(
											 module => 'ServiceGroup',
											 path   => 'Session/ServiceGroup/',
											 ID     => $ID
	);

	$WSRF::WSRP::ResourceProperties{ServiceGroupEPR} = $wsa;

	#write the properties to a file
	WSRF::File::toFile($ID);

	#return the WS-Address
	return WSRF::Header::header($envelope),
	  SOAP::Data->value($wsa)->type('xml');
}

# add an entry to the SG
sub Add {
	my $envelope = pop @_;                     #get the SOAP envelope
	my $lock     = WSRF::File->new($envelope); #get the properties from the file
	$strip_old_Entries->();
	my ( $class, $val ) = @_;                  #get the operation paramaters

	my $serializer = new WSRF::SimpleSerializer;

#print "$$ Message::\n".$serializer->serialize( $envelope->dataof('/') )."\n\n";

	# BUG
	# We cannot use the following to get the MemberEPR
	# my $mepr = $serializer->serialize( $envelope->dataof('//MemberEPR/[1]') );
	# because it screws up the namespaces - SimpleSerializer cannot
	# handle more than one namespace in a message.

	my $mepraddress =
	    $envelope->match("//MemberEPR//{$WSRF::Constants::WSA}Address")
	  ? $envelope->valueof("//MemberEPR//{$WSRF::Constants::WSA}Address")
	  : die "No MemberEPR in Add message\n";    #BUG - BaseFault

	#check for ReferenceParameters
	my ($RefParam);
	if ( $envelope->dataof('//MemberEPR//ReferenceParameters/*') ) {
		my $i = 0;
		foreach
		  my $a ( $envelope->dataof('//MemberEPR//ReferenceParameters/*') )
		{
			$i++;
			my $name  = $a->name();
			my $uri   = $a->uri();
			my $value = $a->value();
			$RefParam .=
			    "<myns" . $i . ":" . $name
			  . " xmlns:myns"
			  . $i . "=\""
			  . $uri . "\">"
			  . $value
			  . "</myns"
			  . $i . ":"
			  . $name . ">";
		}
	}

	my $mepr = "<wsa:EndpointReference xmlns:wsa=\"$WSRF::Constants::WSA\">";
	$mepr .= "<wsa:Address>$mepraddress</wsa:Address>";
	$mepr .= $RefParam ? $RefParam : "";
	$mepr .= "</wsa:EndpointReference>";

	$mepr = "<wssg:MemberServiceEPR>$mepr</wssg:MemberServiceEPR>";

	#print STDERR "$$ MEPR = $mepr\n";

	my $content = "";
	if ( defined( $envelope->dataof('//Content/[1]') ) ) {

		#print "Content!! ". $envelope->dataof('//Content')  ."\n";
		$content = $serializer->serialize( $envelope->dataof('//Content/[1]') );

		$content = "<wssg:Content>$content</wssg:Content>";
	}

	#  print STDERR "Content = $content\n";

	my $termTime = "nil";
	if ( defined( $envelope->valueof('//InitialTerminationTime') ) ) {
		$termTime = $envelope->valueof('//InitialTerminationTime');

		#BUG with DateTime::Format::W3CDTF - does not
		#like subseconds - should patch DateTime::Format::W3CDTF
		#print "Called SetTerminationTime: $time\n";
		$termTime =~ s/\.\d+//;

		#print "Setting TerminationTime to: $time\n";

		#test time is good - this will die if the string is faulty, causing
		#a SOAP fault to be sent to the client
		#BUG should eval this and throw a WS-BaseFault
		DateTime::Format::W3CDTF->new->parse_datetime($termTime);
	}

	$termTime = "<EntryTerminationTime>$termTime</EntryTerminationTime>";

	# get an ID for the new ServiceGroupEntry
	my $ID = WSRF::GSutil::CalGSH_ID();
	$ID = $lock->ID() . "-" . $ID;

	#print STDERR "ServiceGroup ID = ".$lock->ID()."\n";
	#print STDERR "ServiceGroupEntry ID = $ID\n";

	my $sge_wsa = WSRF::GSutil::createWSAddress(
						 module => $WSRF::ServiceGroup::ServiceGroupEntryModule,
						 path   => $WSRF::ServiceGroup::ServiceGroupEntryPath,
						 ID     => $ID
	);

	my $ans = $sge_wsa;
	$sge_wsa =
	  "<wssg:ServiceGroupEntryEPR>$sge_wsa</wssg:ServiceGroupEntryEPR>";

	my $Entry = $mepr . $sge_wsa . $content . $termTime;

	push( @{ $WSRF::WSRP::ResourceProperties{Entry} }, $Entry );

	$lock->toFile();                        #put the properties back in the file
	return WSRF::Header::header($envelope), #return result
	  SOAP::Data->value($ans)->type('xml');
}

#===============================================================================

package WSRF::ServiceGroupEntry;

=pod

=head1 WSRF::ServiceGroupEntry

Provides support for ServiceGroupEntry WS-Resources defined in the
WS-ServiceGroup specification. Each ServiceGroupEntry WS-Resource 
represents an entry in a ServiceGroup, destroy the ServiceGroupEntry
and the entry disappears from the ServiceGroup.

=head2 METHODS

=over

=item GetResourcePropertyDocument

=item GetResourceProperty

=item GetMultipleResourceProperties

=item SetResourceProperties

=item Destroy

=item SetTerminationTime

=back 

=cut

use vars qw(@ISA);
use XML::DOM;
use Storable qw(lock_store lock_nstore lock_retrieve);

@ISA = qw(WSRF::WSRL);

# foo is an array of things
$WSRF::WSRP::ResourceProperties{Content}                = "";
$WSRF::WSRP::PropertyNamespaceMap->{Content}{prefix}    = "wssg";
$WSRF::WSRP::PropertyNamespaceMap->{Content}{namespace} =
  $WSRF::Constants::WSSG;
$WSRF::WSRP::NotDeletable{Content} =
  1;    #Cannot delete through SetResourceProperty
$WSRF::WSRP::NotModifiable{Content} =
  1;    #Cannot modify through SetResourceProperty

$WSRF::WSRP::ResourceProperties{ServiceGroupEPR}                = "";
$WSRF::WSRP::PropertyNamespaceMap->{ServiceGroupEPR}{prefix}    = "wssg";
$WSRF::WSRP::PropertyNamespaceMap->{ServiceGroupEPR}{namespace} =
  $WSRF::Constants::WSSG;
$WSRF::WSRP::NotDeletable{ServiceGroupEPR} =
  1;    #Cannot delete through SetResourceProperty
$WSRF::WSRP::NotModifiable{ServiceGroupEPR} =
  1;    #Cannot modify through SetResourceProperty

$WSRF::WSRP::ResourceProperties{MemberEPR}                = "";
$WSRF::WSRP::PropertyNamespaceMap->{MemberEPR}{prefix}    = "wssg";
$WSRF::WSRP::PropertyNamespaceMap->{MemberEPR}{namespace} =
  $WSRF::Constants::WSSG;
$WSRF::WSRP::NotDeletable{MemberEPR} =
  1;    #Cannot delete through SetResourceProperty
$WSRF::WSRP::NotModifiable{MemberEPR} =
  1;    #Cannot modify through SetResourceProperty

my $fromFile = sub {

	# get ID
	my ( $envelope, %args ) = @_;

	foreach my $key ( keys %args ) {
		print "$$ fromFile $key => " . $args{$key} . "\n";
	}
	if ( defined( $args{Destroy} ) ) {
		print "$$ fromFile Attempt to Destroy\n";
	}

	my $address = $envelope->headerof("//{$WSRF::Constants::WSA}To");
	if ( defined $address ) {
		$address = $envelope->headerof("//{$WSRF::Constants::WSA}To")->value;
	} else {
		print STDERR "ERROR: No ResourceID in the SOAP Header\n";
		die SOAP::Fault->faultcode("No WS-Resource Identifier")
		  ->faultstring("No WS-Resource identifier in SOAP Header");
	}

	my @PathArray = split( /\//, $address );
	my $ID        = pop @PathArray;

	#check the ID is safe - we do not accept dots,
	#all paths will be relative to $ENV{WRF_MODULES}
	#only allow alphanumeric, underscore and hyphen
	if ( $ID =~ /^([-\w]+)$/ ) {
		$ID = $1;
	} else {
		print STDERR "ERROR: Bad ResourceID $ID in SOAP Header\n";
		die SOAP::Fault->faultcode("Badly formed WS-Resource Identifier")
		  ->faultstring("Badly formed WS-Resource Identifier in SOAP Header");
	}

	$ENV{ID} = $ID;

	my $ID_clipped = $ID;

	#ID can be of the form 1341-4565, we use this form to all multiple
	#WS-Resources to share the same state, the state is in the file
	#1341 - we use this with ServiceGroup/ServiceGroupEntry
	$ID_clipped =~ s/-\w*//o;

	my $path = $WSRF::Constants::Data . $ID_clipped;

	if ( !( -e $path ) ) {
		print STDERR "ERROR: No Resource $path\n";
		die SOAP::Fault->faultcode("No such WS-Resource")
		  ->faultstring("No WS-Resource with identifier $ID");
	}

	my $lock = $path . ".lock";

	my $Lock = WSRF::FileLock->new($lock);

	my $hashref = Storable::lock_retrieve($path);

	%WSRF::WSRP::ResourceProperties =
	  ( %WSRF::WSRP::ResourceProperties, %{ $hashref->{Properties} } );

	%WSRF::WSRP::Private = ( %WSRF::WSRP::Private, %{ $hashref->{Private} } );

	#   print STDERR "$$ fromFile about to enter loop\n";
	my $parser = new XML::DOM::Parser;
	my $found  = 0;
	my ( $doc, $TerminationTime, $MEPR, $Content, $Destroyed );
	my @tmp = @{ $WSRF::WSRP::ResourceProperties{Entry} };
	@{ $WSRF::WSRP::ResourceProperties{Entry} } = ();

	#   print "$$ Number of Entries= @tmp\n";
	foreach my $entry (@tmp) {

		#      print STDERR $entry."\n";
		my $tmpentry = "<t>" . $entry . "</t>";
		$doc = $parser->parse($tmpentry);

		#print STDERR "Parsed document..\n";
		my $TermTime =
		  defined( $doc->getElementsByTagName("EntryTerminationTime")->item(0)
				   ->getFirstChild )
		  ? $doc->getElementsByTagName("EntryTerminationTime")->item(0)
		  ->getFirstChild->getNodeValue
		  : "";

		if (    ( $TermTime ne "nil" )
			 && ( WSRF::Time::ConvertStringToEpochTime($TermTime) < time ) )
		{
			print STDERR "Deleting Node\n";
			next;
		}

		my $subnodes = $doc->getElementsByTagName("wssg:ServiceGroupEntryEPR");

		#      print "Length= ".$subnodes->getLength."\n";
		my $ResourceID = $subnodes->item(0)->getElementsByTagName("Address");
		if ( $ResourceID->getLength == 0 ) {
			$ResourceID =
			  $subnodes->item(0)->getElementsByTagName("wsa:Address");
		}

		#      print "$$ ResourceID Length= ".$ResourceID->getLength."\n";
		$ResourceID = $ResourceID->item(0)->getFirstChild->getNodeValue;

		#      print STDERR "$$ ResourceID = $ResourceID\n";
		if ( $ResourceID eq $address )    #found node we want
		{
			print STDERR "$$ ResourceIDs match\n";
			$TerminationTime = ( $TermTime eq "nil" ) ? "" : $TermTime;
			$Content =
			  $doc->getElementsByTagName("wssg:Content")->item(0)
			  ->getFirstChild->toString;
			$MEPR =
			  $doc->getElementsByTagName("wssg:MemberServiceEPR")->item(0)
			  ->getFirstChild->toString;
			$found = 1;
			if ( defined( $args{Destroy} ) ) {

			  #            print STDERR "$$ Destroying ServiceGroupEntry $ID\n";
				$Destroyed = "True";
				next;
			}
			if ( defined( $args{TerminationTime} ) ) {
				$doc->getElementsByTagName("EntryTerminationTime")->item(0)
				  ->getFirstChild->setNodeValue( $args{TerminationTime} );
			}
			my $foo = $doc->toString;
			$foo =~ s/<\/?t>//og;
			$entry = $foo;
		}
		push @{ $WSRF::WSRP::ResourceProperties{Entry} }, $entry;
		$doc->dispose;
	}

	my %tmpPrivate = (%WSRF::WSRP::Private);

	#should use map?
	foreach my $key ( keys %tmpPrivate ) {
		if ( ref( $tmpPrivate{$key} ) eq "CODE" ) {
			delete $tmpPrivate{$key};
		}
	}

	#take a copy of the ResourceProperties to copy to file
	my %tmphash = (%WSRF::WSRP::ResourceProperties);
	foreach my $key ( keys %tmphash ) {
		if ( ref( $tmphash{$key} ) eq "CODE" ) {
			delete $tmphash{$key};
		}
	}

	my %tmpStore = ( Properties => \%tmphash, Private => \%tmpPrivate );

	local $Storable::forgive_me = "TRUE";
	lock_store \%tmpStore, $path;

	#ServiceGroupEntry not found
	if ( !$found && !$Destroyed ) {
		die SOAP::Fault->faultcode("No such WS-Resource")
		  ->faultstring("No WS-Resource with identifier $address");
	}

	$WSRF::WSRP::ResourceProperties{TerminationTime} = $TerminationTime;
	$WSRF::WSRP::ResourceProperties{Content}         = $Content;
	$WSRF::WSRP::ResourceProperties{MemberEPR}       = $MEPR;

	return $path;
};

sub GetResourceProperty {
	my $self     = shift @_;
	my $envelope = pop @_;
	$fromFile->($envelope);

#   print STDERR "ServiceGroupEntry::GetResourceProperty Dumping Properties..\n";
#   foreach my $key ( keys %WSRF::WSRP::ResourceProperties )
#   {
#      print "  $key: ".$WSRF::WSRP::ResourceProperties{$key}."\n";
#   }
	my @resp = $self->SUPER::GetResourceProperty($envelope);
	return @resp;
}

sub GetResourcePropertyDocument {
	my $self     = shift @_;
	my $envelope = pop @_;
	$fromFile->($envelope);
	my @resp = $self->SUPER::GetResourcePropertyDocument($envelope);
	return @resp;
}

sub SetResourceProperties {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $path     = $fromFile->($envelope);
	my @resp     = $self->SUPER::SetResourceProperties($envelope);
	return @resp;
}

sub GetMultipleResourceProperties {
	my $self     = shift @_;
	my $envelope = pop @_;
	my $path     = $fromFile->($envelope);
	my @resp     = $self->SUPER::GetMultipleResourceProperties($envelope);
	return @resp;
}

sub Destroy {

	# get ID
	my ($envelope) = pop @_;
	print STDERR "$$ WSRF::ServiceGroupEntry Destroy invoked\n";
	$fromFile->( $envelope, Destroy => 1 );
	return WSRF::Header::header($envelope);
}

sub SetTerminationTime {

	# get ID
	my ($envelope) = pop @_;
	shift @_;    #the first paramter is always the class of the object
	my $time = shift @_;

	#print STDERR "time= $time\n";

	#BUG with DateTime::Format::W3CDTF - does not
	#like subseconds - should patch DateTime::Format::W3CDTF
	#print "Called SetTerminationTime: $time\n";
	$time =~ s/\.\d+//;

	#check time is in good format - otherwise die!
	DateTime::Format::W3CDTF->new->parse_datetime($time);

	$fromFile->( $envelope, TerminationTime => $time );

	my $result = "<wsrl:NewTerminationTime>$time</wsrl:NewTerminationTime>";
	$result .=
	    "<wsrl:CurrentTime>"
	  . WSRF::Time::ConvertEpochTimeToString()
	  . "</wsrl:CurrentTime>";

	return WSRF::Header::header($envelope),
	  SOAP::Data->value($result)->type('xml');

}

# ======================================================================

package WSRF;

use vars qw($AUTOLOAD);
require URI;

my $soap;    # shared between SOAP and SOAP::Lite packages

{
	no strict 'refs';
	*AUTOLOAD = sub {
		local ( $1, $2 );
		my ( $package, $method ) = $AUTOLOAD =~ m/(?:(.+)::)([^:]+)$/;
		return if $method eq 'DESTROY';

		my $soap =
		  ref $_[0] && UNIVERSAL::isa( $_[0] => 'SOAP::Lite' ) ? $_[0] : $soap
		  || die
"SOAP:: prefix shall only be used in combination with +autodispatch option\n";

		my $uri        = URI->new( $soap->uri );
		my $currenturi = $uri->path;
		$package =
		  ref $_[0] && UNIVERSAL::isa( $_[0] => 'SOAP::Lite' )
		  ? $currenturi
		  : $package eq 'SOAP'
		  ? ref $_[0]
		  || ( $_[0] eq 'SOAP'
			 ? $currenturi || Carp::croak "URI is not specified for method call"
			 : $_[0] )
		  : $package eq 'main'
		  ? $currenturi || $package
		  : $package;

		# drop first parameter if it's a class name
		{
			my $pack = $package;
			for ($pack) { s!^/!!; s!/!::!g; }
			shift @_
			  if @_ && !ref $_[0] && ( $_[0] eq $pack || $_[0] eq 'SOAP' )
			  || ref $_[0] && UNIVERSAL::isa( $_[0] => 'SOAP::Lite' );
		}

		for ($package) { s!::!/!g; s!^/?!/!; }
		$uri->path($package);

		my $som = $soap->uri( $uri->as_string )->call( $method => @_ );
		UNIVERSAL::isa( $som => 'SOAP::SOM' )
		  ? wantarray ? $som->paramsall : $som->result
		  : $som;
	};
}

# ======================================================================
# Copyright (C) 2000-2004 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

package WSRF::Lite;

=pod

=head1 WSRF::Lite

Extends SOAP::Lite to provide support for WS-Addressing.
WSRF::Lite uses WSRF::WSRFSerializer and WSRF::Deserializer
by default, it will also automatically include the WS-Addressing
SOAP headers in the SOAP message. If $ENV{WSS} is set to true,
$ENV{HTTPS_CERT_FILE} points to the public part of a X.509 
certificate and $ENV{HTTPS_KEY_FILE} points to the unencrypted
private key of the certificate then WSRF::Lite will digitally 
sign the message according to the WS-Security specification.

=head2 METHODS

WSRF::Lite supports the same set of methods as SOAP::Lite with the
addition of wsaddess.

=over

=item wsaddress

This can be used instead of the proxy method, it takes a WSRF::WS_Address 
object for the address of the service or WS-Resource:
	 
	$ans=  WSRF::Lite
	  -> uri($uri)
	  -> wsaddress(WSRF::WS_Address->new()->Address($target))              
	  -> createCounterResource(); 
	 
=back

=cut

use vars qw($AUTOLOAD @ISA);
use Carp ();

use SOAP::Packager;

@ISA = qw(SOAP::Cloneable);

# provide access to global/autodispatched object
sub self { @_ > 1 ? $soap = $_[1] : $soap }

# no more warnings about "used only once"
*UNIVERSAL::AUTOLOAD if 0;

sub autodispatched { \&{*UNIVERSAL::AUTOLOAD} eq \&{*SOAP::AUTOLOAD} }

sub soapversion {
	my $self    = shift;
	my $version = shift or return $SOAP::Constants::SOAP_VERSION;

	($version) =
	  grep { $SOAP::Constants::SOAP_VERSIONS{$_}->{NS_ENV} eq $version }
	  keys %SOAP::Constants::SOAP_VERSIONS
	  unless exists $SOAP::Constants::SOAP_VERSIONS{$version};

	die qq!$SOAP::Constants::WRONG_VERSION Supported versions:\n@{[
        join "\n", map {"  $_ ($SOAP::Constants::SOAP_VERSIONS{$_}->{NS_ENV})"} keys %SOAP::Constants::SOAP_VERSIONS
        ]}\n!
	  unless defined($version)
	  && defined( my $def = $SOAP::Constants::SOAP_VERSIONS{$version} );

	foreach ( keys %$def ) {
		eval
"\$SOAP::Constants::$_ = '$SOAP::Constants::SOAP_VERSIONS{$version}->{$_}'";
	}

	$SOAP::Constants::SOAP_VERSION = $version;
	$self;
}

BEGIN { WSRF::Lite->soapversion(1.1) }

sub import {
	my $pkg    = shift;
	my $caller = caller;
	no strict 'refs';

	# emulate 'use SOAP::Lite 0.99' behavior
	$pkg->require_version(shift) if defined $_[0] && $_[0] =~ /^\d/;

	while (@_) {
		my $command = shift;

		my @parameters =
		  UNIVERSAL::isa( $_[0] => 'ARRAY' ) ? @{ shift() } : shift
		  if @_ && $command ne 'autodispatch';
		if ( $command eq 'autodispatch' || $command eq 'dispatch_from' ) {
			$soap = ( $soap || $pkg )->new;
			no strict 'refs';
			foreach ( $command eq 'autodispatch' ? 'UNIVERSAL' : @parameters ) {
				my $sub = "${_}::AUTOLOAD";
				defined &{*$sub}
				  ? ( \&{*$sub} eq \&{*SOAP::AUTOLOAD}
					? ()
					: Carp::croak
					  "$sub already assigned and won't work with DISPATCH. Died"
				  )
				  : ( *$sub = *SOAP::AUTOLOAD );
			}
		} elsif ( $command eq 'service' ) {
			foreach (
					  keys %{ SOAP::Schema->schema_url( shift(@parameters) )
							->parse(@parameters)->load->services
					  }
			  )
			{
				$_->export_to_level( 1, undef, ':all' );
			}
		} elsif ( $command eq 'debug' || $command eq 'trace' ) {
			SOAP::Trace->import( @parameters ? @parameters : 'all' );
		} elsif ( $command eq 'import' ) {
			local $^W;    # supress warnings about redefining
			my $package = shift(@parameters);
			$package->export_to_level( 1, undef,
									   @parameters ? @parameters : ':all' )
			  if $package;
		} else {
			Carp::carp
			  "Odd (wrong?) number of parameters in import(), still continue"
			  if $^W && !( @parameters & 1 );
			$soap = ( $soap || $pkg )->$command(@parameters);
		}
	}
}

sub DESTROY { SOAP::Trace::objects('()') }

sub new {
	my $self = shift;
	return $self if ref $self;
	unless ( ref $self ) {
		my $class = ref($self) || $self;

	   # Check whether we can clone. Only the SAME class allowed, no inheritance
		$self = ref($soap) eq $class ? $soap->clone : {
			_transport    => SOAP::Transport->new,
			_serializer   => WSRF::WSRFSerializer->new,
			_deserializer => WSRF::Deserializer->new,
			_packager     => SOAP::Packager::MIME->new,
			_schema       => undef,
			_wsaddress    => undef,
			_autoresult   => 0,
			_on_action    => sub { sprintf '"%s#%s"', shift || '', shift },
			_on_fault => sub {
				ref $_[1]                                    ? return $_[1]
				  : Carp::croak $_[0]->transport->is_success ? $_[1]
				  : $_[0]->transport->status;
			},
		};
		bless $self => $class;
		$self->on_nonserialized(    $self->on_nonserialized
								 || $self->serializer->on_nonserialized );
		SOAP::Trace::objects('()');
	}

	Carp::carp "Odd (wrong?) number of parameters in new()"
	  if $^W && ( @_ & 1 );
	while (@_) {
		my ( $method, $params ) = splice( @_, 0, 2 );
		$self->can($method)
		  ? $self->$method( ref $params eq 'ARRAY' ? @$params : $params )
		  : $^W && Carp::carp "Unrecognized parameter '$method' in new()";
	}

	return $self;
}

sub init_context {
	my $self = shift->new;
	$self->{'_deserializer'}->{'_context'} = $self;
	$self->{'_serializer'}->{'_context'}   = $self;
}

sub destroy_context {
	my $self = shift;
	delete( $self->{'_deserializer'}->{'_context'} );
	delete( $self->{'_serializer'}->{'_context'} );
}

# Naming? wsdl_parser
sub schema {
	my $self = shift;
	if (@_) {
		$self->{'_schema'} = shift;
		return $self;
	} else {
		if ( !defined $self->{'_schema'} ) {
			$self->{'_schema'} = SOAP::Schema->new;
		}
		return $self->{'_schema'};
	}
}

sub BEGIN {
	no strict 'refs';
	for my $method (qw(serializer deserializer)) {
		my $field = '_' . $method;
		*$method = sub {
			my $self = shift->new;
			if (@_) {
				my $context =
				  $self->{$field}->{'_context'};    # save the old context
				$self->{$field} = shift;
				$self->{$field}->{'_context'} =
				  $context;                         # restore the old context
				return $self;
			} else {
				return $self->{$field};
			}
		  }
	}
	for my $method (
				 qw(endpoint transport outputxml autoresult packager wsaddress))
	{
		my $field = '_' . $method;
		*$method = sub {
			my $self = shift->new;
			@_
			  ? ( $self->{$field} = shift, return $self )
			  : return $self->{$field};
		  }
	}
	for my $method (qw(on_action on_fault on_nonserialized)) {
		my $field = '_' . $method;
		*$method = sub {
			my $self = shift->new;
			return $self->{$field} unless @_;
			local $@;

			# commented out because that 'eval' was unsecure
			# > ref $_[0] eq 'CODE' ? shift : eval shift;
			# Am I paranoid enough?
			$self->{$field} = shift;
			Carp::croak $@ if $@;
			Carp::croak
"$method() expects subroutine (CODE) or string that evaluates into subroutine (CODE)"
			  unless ref $self->{$field} eq 'CODE';
			return $self;
		  }
	}

	# SOAP::Transport Shortcuts
	# TODO - deprecate proxy() in favor of new language endpoint_url()
	for my $method (qw(proxy)) {
		*$method = sub {
			my $self = shift->new;
			if (@_) {
				my $endpoint = shift @_;
				if ( UNIVERSAL::isa( $endpoint => 'WSRF::WS_Address' ) ) {
					$self->{_wsaddress} = $endpoint;
					$endpoint = $endpoint->Address();
				}
				$self->transport->$method( $endpoint, @_ );
				return $self;
			}
			return $self->transport->$method();
		  }
	}

	# SOAP::Seriailizer Shortcuts
	for my $method (
		qw(autotype readable envprefix encodingStyle
		encprefix multirefinplace encoding typelookup uri
		header maptype xmlschema use_prefix ns default_ns)
	  )
	{
		*$method = sub {
			my $self = shift->new;
			@_
			  ? ( $self->serializer->$method(@_), return $self )
			  : return $self->serializer->$method();
		  }
	}

	# SOAP::Schema Shortcuts
	for my $method (qw(cache_dir cache_ttl)) {
		*$method = sub {
			my $self = shift->new;
			@_
			  ? ( $self->schema->$method(@_), return $self )
			  : return $self->schema->$method();
		  }
	}
}

sub parts {
	my $self = shift;
	$self->packager->parts(@_);
	return $self;
}

# Naming? wsdl
sub service {
	my $self = shift->new;
	return $self->{'_service'} unless @_;
	$self->schema->schema_url( $self->{'_service'} = shift );
	my %services = %{ $self->schema->parse(@_)->load->services };

	Carp::croak
"More than one service in service description. Service and port names have to be specified\n"
	  if keys %services > 1;
	my $service = ( keys %services )[0]->new;
	return $service;
}

sub AUTOLOAD {
	my $method = substr( $AUTOLOAD, rindex( $AUTOLOAD, '::' ) + 2 );
	return if $method eq 'DESTROY';

	ref $_[0]
	  or Carp::croak qq!Can\'t locate class method "$method" via package \"!
	  . __PACKAGE__ . '\"';

	no strict 'refs';
	*$AUTOLOAD = sub {
		my $self = shift;
		my $som = $self->call( $method => @_ );
		return $self->autoresult
		  && UNIVERSAL::isa( $som => 'SOAP::SOM' )
		  ? wantarray ? $som->paramsall : $som->result
		  : $som;
	};
	goto &$AUTOLOAD;
}

sub call {
	SOAP::Trace::trace('()');
	my $self = shift;

	if (
		 !(
			defined $self->proxy
			&& UNIVERSAL::isa( $self->proxy => 'SOAP::Client' )
		 )
		 && defined( $self->wsaddress )
		 && UNIVERSAL::isa( $self->wsaddress => 'WSRF::WS_Address' )
	  )
	{
		$self->proxy( $self->wsaddress->Address() );
	}

# Why is this here? Can't call be null? Indicating that there are no input arguments?
#return $self->{_call} unless @_;
	die
"A service address has not been specified either by using SOAP::Lite->proxy() or a service description)\n"
	  unless defined $self->proxy
	  && UNIVERSAL::isa( $self->proxy => 'SOAP::Client' );

	$self->init_context();
	my $serializer = $self->serializer;
	$serializer->on_nonserialized( $self->on_nonserialized );
	if ( defined $self->wsaddress ) {
		my $header =
		    "<wsa:Action wsu:Id=\"Action\">"
		  . scalar( $self->on_action->( $serializer->uriformethod( $_[0] ) ) )
		  . "</wsa:Action>";
		$header .=
		  "<wsa:To wsu:Id=\"To\">" . $self->wsaddress->Address() . "</wsa:To>";
		$header .=
		    "<wsa:MessageID wsu:Id=\"MessageID\">"
		  . $self->wsaddress->MessageID()
		  . "</wsa:MessageID>";
		$header .=
		    $self->wsaddress->serializeReferenceParameters()
		  ? $self->wsaddress->serializeReferenceParameters()
		  : '';

		#bug fix - John Newman
		$header .=
"<wsa:ReplyTo wsu:Id=\"ReplyTo\"><wsa:Address>$WSRF::Constants::WSA_ANON</wsa:Address></wsa:ReplyTo>";
		@_ = ( @_, SOAP::Header->value($header)->type('xml') );
	}

	my $response = $self->transport->send_receive(
		context  => $self,             # this is provided for context
		endpoint => $self->endpoint,
		action   =>
		  scalar( $self->on_action->( $serializer->uriformethod( $_[0] ) ) ),

		# leave only parameters so we can later update them if required
		envelope => $serializer->envelope( method => shift, @_ ),

		#    envelope => $serializer->envelope(method => shift, @_),
		encoding => $serializer->encoding,
		parts => @{ $self->packager->parts } ? $self->packager->parts : undef,
	);

	#BUG fix by Luke AT yahoo.com
	#return $response if $self->outputxml;
	# if ( $self->outputxml ) { $self->destroy_context(); return $response; }

	# deserialize and store result
	my $result = $self->{'_call'} =
	  eval { $self->deserializer->deserialize($response) }
	  if $response;

	if (
		!$self->transport->is_success ||    # transport fault
		$@                            ||    # not deserializible
		                                    # fault message even if transport OK
		  # or no transport error (for example, fo TCP, POP3, IO implementations)
		UNIVERSAL::isa( $result => 'SOAP::SOM' ) && $result->fault
	  )
	{
		return $self->{'_call'} =
		  ( $self->on_fault->( $self, $@ ? $@ . ( $response || '' ) : $result )
			|| $result );
	}

	return unless $response;    # nothing to do for one-ways

	# little bit tricky part that binds in/out parameters
	if (    UNIVERSAL::isa( $result => 'SOAPSOM' )
		 && ( $result->paramsout || $result->headers )
		 && $serializer->signature )
	{
		my $num = 0;
		my %signatures = map { $_ => $num++ } @{ $serializer->signature };
		for ( $result->dataof(SOAP::SOM::paramsout),
			  $result->dataof(SOAP::SOM::headers) )
		{
			my $signature = join $;, $_->name, $_->type || '';
			if ( exists $signatures{$signature} ) {
				my $param = $signatures{$signature};
				my ($value) = $_->value;    # take first value
				UNIVERSAL::isa( $_[$param] => 'SOAP::Data' )
				  ? $_[$param]->SOAP::Data::value($value)
				  : UNIVERSAL::isa( $_[$param] => 'ARRAY' )
				  ? ( @{ $_[$param] } = @$value )
				  : UNIVERSAL::isa( $_[$param] => 'HASH' )
				  ? ( %{ $_[$param] } = %$value )
				  : UNIVERSAL::isa( $_[$param] => 'SCALAR' )
				  ? ( ${ $_[$param] } = $$value )
				  : ( $_[$param] = $value );
			}
		}
	}
	$self->destroy_context();

    if ( $self->outputxml ) {
      return ($result, $response);
    } else {
	  return $result;
    }
}    # end of call()

# ======================================================================

package WSRF::WSS;

=pod

=head1 WSRF::WSS

Provides support for digitally signing SOAP messages according to the
WS-Security specification.

=head2 METHODS

=over

=item sign

=item verify

=back

=cut

%WSRF::WSS::ASNMTAP = ();
$WSRF::WSS::ASNMTAP{UsernameToken}    = undef;
$WSRF::WSS::ASNMTAP{SAML}             = undef;
$WSRF::WSS::ASNMTAP{Assertion}        = undef;
$WSRF::WSS::ASNMTAP{SAMLAssertionID}  = undef;

%WSRF::WSS::ID = (); 
$WSRF::WSS::ID{X509Token} = "X509Token-" . time(); 
$WSRF::WSS::ID{TimeStamp} = "TimeStamp-" . time(); 
$WSRF::WSS::ID{myBody} = "myBody-" . time(); 

%WSRF::WSS::Sign                      = ();
$WSRF::WSS::Sign{BinarySecurityToken} = 1;
$WSRF::WSS::Sign{Timestamp}           = 1;
$WSRF::WSS::Sign{MessageID}           = 1;
$WSRF::WSS::Sign{To}                  = 1;
$WSRF::WSS::Sign{Action}              = 1;
$WSRF::WSS::Sign{From}                = 1;
$WSRF::WSS::Sign{RelatesTo}           = 1;
$WSRF::WSS::Sign{ReplyTo}             = 1;
$WSRF::WSS::Sign{Body}                = 1;

%WSRF::WSS::ID_Xpath = ();

#XPaths to the parts of the SOAP message we want to sign
$WSRF::WSS::sec_xpath = 
	  '(//. | //@* | //namespace::*)[ancestor-or-self::wsse:BinarySecurityToken]';

#$WSRF::WSS::sec_xpath = 
#	  '<XPath xmlns:wsse="' 
#	. $WSRF::Constants::WSSE
#	. '">(//. | //@* | //namespace::*)[ancestor-or-self::wsse:BinarySecurityToken]</XPath>';

$WSRF::WSS::si_xpath = 
#	'<XPath xmlns:ds="' . $WSRF::Constants::DS . '">(//. | //@* | //namespace::*)[ancestor-or-self::ds:SignedInfo]</XPath>';
	'(//. | //@* | //namespace::*)[ancestor-or-self::ds:SignedInfo]';
$WSRF::WSS::timestamp_xpath = 
#	  '<XPath xmlns:wsu="' 
#	. $WSRF::Constants::WSU 
#	. '">(//. | //@* | //namespace::*)[ancestor-or-self::wsu:Timestamp]</XPath>';
	'(//. | //@* | //namespace::*)[ancestor-or-self::wsu:Timestamp]';

$WSRF::WSS::ID_Xpath{MessageID} =
#  '<XPath xmlns:wsa="'
#  . $WSRF::Constants::WSA 
#  . '">(//. | //@* | //namespace::*)[ancestor-or-self::wsa:MessageID]</XPath>';
   '(//. | //@* | //namespace::*)[ancestor-or-self::wsa:MessageID]';

$WSRF::WSS::ID_Xpath{To} = 
#  '<XPath xmlns:wsa="'
#  . $WSRF::Constants::WSA 
#  . '">(//. | //@* | //namespace::*)[ancestor-or-self::wsa:To]</XPath>';
   '(//. | //@* | //namespace::*)[ancestor-or-self::wsa:To]';

$WSRF::WSS::ID_Xpath{Action} =
#  '<XPath xmlns:wsa="'
#  . $WSRF::Constants::WSA 
#  . '">(//. | //@* | //namespace::*)[ancestor-or-self::wsa:Action]</XPath>'; 
  '(//. | //@* | //namespace::*)[ancestor-or-self::wsa:Action]';

$WSRF::WSS::ID_Xpath{From} = 
#  '<XPath xmlns:wsa="'
#   . $WSRF::Constants::WSA
#   . '">(//. | //@* | //namespace::*)[ancestor-or-self::wsa:From]</XPath>';
   '(//. | //@* | //namespace::*)[ancestor-or-self::wsa:From]';

$WSRF::WSS::ID_Xpath{ReplyTo} =
#  '<XPath xmlns:wsa="'
#  . $WSRF::Constants::WSA
#  . '">(//. | //@* | //namespace::*)[ancestor-or-self::wsa:ReplyTo]</XPath>';
  '(//. | //@* | //namespace::*)[ancestor-or-self::wsa:ReplyTo]';

$WSRF::WSS::ID_Xpath{RelatesTo} =
#  '<XPath xmlns:wsa="'
#  . $WSRF::Constants::WSA 
#  . '">(//. | //@* | //namespace::*)[ancestor-or-self::wsa:RelatesTo]</XPath>';
  '(//. | //@* | //namespace::*)[ancestor-or-self::wsa:RelatesTo]';

$WSRF::WSS::body_xpath =
#"<XPath xmlns:$SOAP::Constants::PREFIX_ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">"
#  . '(//. | //@* | //namespace::*)'
#  . "[ancestor-or-self::$SOAP::Constants::PREFIX_ENV:Body]</XPath>";
  '(//. | //@* | //namespace::*)' . "[ancestor-or-self::$SOAP::Constants::PREFIX_ENV:Body]";

$WSRF::WSS::priv_key = undef;
$WSRF::WSS::pub_key  = undef;

sub load_priv_key {

	if ( defined($WSRF::WSS::priv_key) ) {
		if ( ref($WSRF::WSS::priv_key) eq 'CODE' ) {
			return $WSRF::WSS::priv_key->();
		} else {
			return $WSRF::WSS::priv_key;
		}
	}

	eval { require Crypt::OpenSSL::RSA };
	die "Failed to access class Crypt::OpenSSL::RSA: $@" if $@;

	my $key_file_name =
	  $ENV{HTTPS_KEY_FILE} ? $ENV{HTTPS_KEY_FILE} : die "No Private Key\n";
	open( PRIVKEY, $key_file_name )
	  || die("Could not open file $key_file_name");
	my $privkey = join "", <PRIVKEY>;
	close(PRIVKEY);
	Crypt::OpenSSL::RSA->new_private_key($privkey);
}

#returns the cert block between the begin and end delimiters
sub load_cert {

	if ( defined($WSRF::WSS::pub_key) ) {
		if ( ref($WSRF::WSS::pub_key) eq 'CODE' ) {
			return $WSRF::WSS::pub_key->();
		} else {
			return $WSRF::WSS::pub_key;
		}
	}

	my $cert_file_name =
	  $ENV{HTTPS_CERT_FILE} ? $ENV{HTTPS_CERT_FILE} : die "No Public Key\n";
	open( CERT, $cert_file_name )
	  || die("Could not open certificate file $cert_file_name");
	my $start = 0;
	my $cert  = "";
	while (<CERT>) {
		if ( !m/-----END CERTIFICATE-----/ && $start == 1 ) {
			$cert = $cert . $_;
		}
		if (/-----BEGIN CERTIFICATE-----/) {
			$start = 1;
		}
	}
	close(CERT);
	return $cert;
}

sub sign {
	my $envelope = shift;

	eval { require XML::LibXML };
	die "Failed to access class XML::LibXML: $@" if $@;
	eval { require MIME::Base64 };
	die "Failed to access class MIME::Base64: $@" if $@;

	#Get Certificate
	my $certificate = WSRF::WSS::load_cert();

	my $header = "";

	my $for_signing =
	    '<ds:SignedInfo xmlns:ds="' . $WSRF::Constants::DS . '">'
	  . '<ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />'
	  . '<ds:SignatureMethod Algorithm="' . $WSRF::Constants::DS . 'rsa-sha1"/>';

	#search through the envelope for things to sign
	foreach my $key ( keys(%WSRF::WSS::ID_Xpath) ) {
		next unless (defined $WSRF::WSS::ID_Xpath{$key});
		$for_signing .=
		  WSRF::WSS::make_token( $envelope, $WSRF::WSS::ID_Xpath{$key}, $key )
		  if defined( $WSRF::WSS::Sign{$key} );
		my $parser = XML::LibXML->new();
		my $doc    = $parser->parse_string($envelope);
		my $canon = undef;
		eval {$canon  = $doc->toStringEC14N( 0, $WSRF::WSS::ID_Xpath{$key}, [''] );};
		$header .= defined($canon) ? $canon : "";
	}

	$for_signing .=
	  WSRF::WSS::make_token( $envelope, $WSRF::WSS::body_xpath, $WSRF::WSS::ID{myBody}  )
	  if defined( $WSRF::WSS::Sign{Body} );

	#create a security token using the certificate
	my $sec_token =
'<wsse:BinarySecurityToken xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary" ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3" wsu:Id="' . $WSRF::WSS::ID{X509Token} . '">'
	  . $certificate
	  . '</wsse:BinarySecurityToken>';
	if (    defined( $WSRF::WSS::Sign{BinarySecurityToken} )
		 && defined($WSRF::WSS::sec_xpath) )
	{
		$for_signing .=
		  WSRF::WSS::make_token( $sec_token, $WSRF::WSS::sec_xpath,
								 $WSRF::WSS::ID{X509Token} );
	}

	#create a timestamp
	my $timestamp = '';
	if ( defined($WSRF::WSS::timestamp_xpath) ) {
		$timestamp =
'<wsu:Timestamp xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" wsu:Id="' . $WSRF::WSS::ID{TimeStamp} . '">';
		$timestamp .=
		    '<wsu:Created>'
		  . WSRF::Time::ConvertEpochTimeToString(time)
		  . '</wsu:Created>';
		$timestamp .=
		    '<wsu:Expires>'
		  . WSRF::Time::ConvertEpochTimeToString( time + ($WSRF::TIME::EXPIRES_IN ? $WSRF::TIME::EXPIRES_IN : 60))
		  . '</wsu:Expires>';

		#$timestamp .= '<wsu:Created>2004-02-07T14:31:59Z</wsu:Created>';
		#$timestamp .= '<wsu:Expires>2006-02-07T14:36:59Z</wsu:Expires>';
		$timestamp .= '</wsu:Timestamp>';

		#canonicalize,digest + Base64 the timestamp
		$for_signing .=
		  WSRF::WSS::make_token( $timestamp, $WSRF::WSS::timestamp_xpath,
								 $WSRF::WSS::ID{TimeStamp} )
		  if defined( $WSRF::WSS::Sign{Timestamp} );
	}

	$for_signing .= '</ds:SignedInfo>';

	my $parser          = XML::LibXML->new();
	my $doc             = $parser->parse_string($for_signing);
	my $can_signed_info = $doc->toStringEC14N( 0, $WSRF::WSS::si_xpath, [''] );

#   print ">>>can_signed>>>>".MIME::Base64::encode(sha1($can_signed_info))."<<<<<can_aigned<<<<<\n";
#   print ">>>can_signed_info>>>>\n$can_signed_info\n<<<<<can_signed_info<<<<<\n";

	my $rsa_priv  = WSRF::WSS::load_priv_key();
	my $signature = $rsa_priv->sign($can_signed_info);
	$signature = MIME::Base64::encode($signature);

  my $sec_token_reference = '<wsse:Reference  ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3" URI="#' . $WSRF::WSS::ID{X509Token} . '"/>';

  if ( defined $WSRF::WSS::ASNMTAP{Assertion} and $WSRF::WSS::ASNMTAP{SAMLAssertionID} ) {
    $sec_token = $WSRF::WSS::ASNMTAP{Assertion};
    $WSRF::WSS::ASNMTAP{Assertion} =~ $WSRF::WSS::ASNMTAP{SAMLAssertionID};
    $sec_token_reference = '<wsse:KeyIdentifier  ValueType="http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.0#SAMLAssertionID">' . ( defined $1 ? $1 : '?' ) . '</wsse:KeyIdentifier>';
  }

	my $extraheader =
'<wsse:Security xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" 
xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
	  . $sec_token . "\n"
	  . '<ds:Signature xmlns:ds="' . $WSRF::Constants::DS . '">' 
	  . $can_signed_info . '<ds:SignatureValue>' 
	  . $signature . '</ds:SignatureValue><ds:KeyInfo>' 
    . '<wsse:SecurityTokenReference>' . $sec_token_reference . '</wsse:SecurityTokenReference>'
    . '</ds:KeyInfo></ds:Signature>';

	$extraheader .= $WSRF::WSS::ASNMTAP{UsernameToken} if ( $WSRF::WSS::ASNMTAP{UsernameToken} );

	  if ( defined($WSRF::WSS::timestamp_xpath) ) {
		$extraheader .= $timestamp;
	}
	$extraheader .= '</wsse:Security>';
	$header = $extraheader . $header;

	$doc = $parser->parse_string($envelope);
  my $Body = $doc->toStringEC14N( 0, $WSRF::WSS::body_xpath, ((defined $WSRF::WSS::ASNMTAP{SAML}) ? ['saml', 'samlp'] : ['']));
	# TODO: replace ['saml', 'samlp'] with the array created from the content of $WSRF::WSS::ASNMTAP{SAML}!!!
	#my $Body = $doc->toStringEC14N( 0, $WSRF::WSS::body_xpath, [''] );
	#my $Body = $doc->toStringC14N(0,$WSRF::WSS::body_xpath);
	
	#print ">>>header newline body>>>>\n$header\n\n$Body\n<<<<<header newline body<<<<<\n";
	return $header, $Body;
}

sub make_token {
	my ( $XML, $Path, $ID ) = @_;

	eval { require XML::LibXML };
	die "Failed to access class XML::LibXML: $@" if $@;
	eval { require Digest::SHA1 };
	die "Failed to access class Digest::SHA1: $@" if $@;
	eval { require MIME::Base64 };
	die "Failed to access class MIME::Base64: $@" if $@;

	#   print "make_token $ID\n";
	#   print "Xpath=> $Path\n";
	my $parser    = XML::LibXML->new();
	my $doc       = $parser->parse_string($XML);
	my $can_token = undef;
	eval {$can_token = $doc->toStringEC14N( 0, $Path, [''] );};
	return '' unless $can_token;

#	print ">>>token-$ID>>>\n$can_token\n<<<token-$ID<<<<\n";

	#take digest of token
	my $token_digest = Digest::SHA1::sha1($can_token);

	#base64 encode digest
	$token_digest = MIME::Base64::encode($token_digest);
	chomp($token_digest);

#print ">>>>token-$ID-digest>>>".$token_digest."<<<token-$ID-digest<<<<\n";

	return '<ds:Reference URI="#' . $ID . '">'
	  . '<ds:Transforms>'
	  . '<ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>'
	  #. '</ds:Transform>'
	  . '</ds:Transforms>'
	  . '<ds:DigestMethod Algorithm= "' . $WSRF::Constants::DS . 'sha1"/>'
	  . '<ds:DigestValue>'
	  . $token_digest
	  . '</ds:DigestValue>'
	  . '</ds:Reference>';

}

%WSRF::WSS::ThingsThatShouldBeSigned = ();

$WSRF::WSS::ThingsThatShouldBeSigned{Body} = $SOAP::Constants::NS_ENV;
$WSRF::WSS::Xpath{Body}                    = $WSRF::WSS::body_xpath;

$WSRF::WSS::ThingsThatShouldBeSigned{To} = $WSRF::Constants::WSA;
$WSRF::WSS::Xpath{To}                    = $WSRF::WSS::ID_Xpath{To};

$WSRF::WSS::ThingsThatShouldBeSigned{MessageID} = $WSRF::Constants::WSA;
$WSRF::WSS::Xpath{MessageID} = $WSRF::WSS::ID_Xpath{MessageID};

$WSRF::WSS::ThingsThatShouldBeSigned{ReplyTo} = $WSRF::Constants::WSA;
$WSRF::WSS::Xpath{ReplyTo}                    = $WSRF::WSS::ID_Xpath{ReplyTo};

$WSRF::WSS::ThingsThatShouldBeSigned{Action} = $WSRF::Constants::WSA;
$WSRF::WSS::Xpath{Action}                    = $WSRF::WSS::ID_Xpath{Action};

$WSRF::WSS::ThingsThatShouldBeSigned{Timestamp} = $WSRF::Constants::WSU;
$WSRF::WSS::Xpath{Timestamp}                    = $WSRF::WSS::timestamp_xpath;

$WSRF::WSS::ThingsThatShouldBeSigned{BinarySecurityToken} =
  $WSRF::Constants::WSSE;
$WSRF::WSS::Xpath{BinarySecurityToken} = $WSRF::WSS::sec_xpath;

$WSRF::WSS::ThingsThatShouldBeSigned{From} = $WSRF::Constants::WSA;
$WSRF::WSS::Xpath{From}                    = $WSRF::WSS::ID_Xpath{From};

$WSRF::WSS::ThingsThatShouldBeSigned{RelatesTo} = $WSRF::Constants::WSA;
$WSRF::WSS::Xpath{RelatesTo} = $WSRF::WSS::ID_Xpath{RelatesTo};

sub verify {
	my $envelope = shift;

	eval { require XML::LibXML };
	die "Failed to access class XML::LibXML: $@" if $@;
	eval { require Digest::SHA1 };
	die "Failed to access class Digest::SHA1: $@" if $@;
	eval { require Crypt::OpenSSL::RSA };
	die "Failed to access class Crypt::OpenSSL::RSA: $@" if $@;
	eval { require Crypt::OpenSSL::X509 };
	die "Failed to access class Crypt::OpenSSL::X509: $@" if $@;
	eval { require MIME::Base64 };
	die "Failed to access class MIME::Base64: $@" if $@;

	my %results = ();

	#get Security Token
	my $Token =
	  $envelope->match(
		"/Envelope/Header/Security/{$WSRF::Constants::WSSE}BinarySecurityToken")
	  ? $envelope->valueof(
		"/Envelope/Header/Security/{$WSRF::Constants::WSSE}BinarySecurityToken")
	  : die "WSRF::WSS::verify Fault - No Security Token in SOAP Header\n";

    $Token =~ s/\s+$//;
	$Token =
	  "-----BEGIN CERTIFICATE-----\n" . $Token . "\n-----END CERTIFICATE-----";

	#   print ">>>>Token>>>\n$Token\n<<<<Token<<<<<\n";

#create an X509 object from the string - this will die if it is not an X509 cert
	my $x509 = Crypt::OpenSSL::X509->new_from_string($Token);

	#if we get here then $Token IS a X509 cert
	$results{X509} = $Token;

	my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key( $x509->pubkey() );

	#get the piece of XML that has been signed
	my $parser          = XML::LibXML->new();
	my $doc             = $parser->parse_string( $envelope->raw_xml );
	my $can_signed_info = $doc->toStringEC14N( 0, $WSRF::WSS::si_xpath, [''] );

	#get the Signature value
	my $SignatureValue =
	  $envelope->match(
		 "/Envelope/Header//{$WSRF::Constants::DS}SignatureValue")
	  ? $envelope->valueof(
		 "/Envelope/Header//{$WSRF::Constants::DS}SignatureValue")
	  : die "WSRF::WSS::verify Fault - No Signature Value in SOAP Header\n";

	$SignatureValue = MIME::Base64::decode($SignatureValue);

	if ( $rsa_pub->verify( $can_signed_info, $SignatureValue ) ) {
		$results{Signed} = 'true';

		#print STDERR "WSRF::WSS::verify Message Signature is Correct\n";
	} else {
		die "WSRF::WSS::verify Fault - Message Signature is NOT Correct\n";
	}

	my $i           = 1;
	my %SignedStuff = ();
	while (
		 $envelope->match("/Envelope/Header/Security/Signature/SignedInfo/[$i]")
	  )
	{
		my $data =
		  $envelope->dataof(
						 "/Envelope/Header/Security/Signature/SignedInfo/[$i]");
		if ( $data->name eq "Reference" ) {
			my $attr        = $data->attr;
			my $name        = $attr->{URI};
			my $DigestValue =
			  $envelope->match(
"/Envelope/Header/Security/Signature/SignedInfo/[$i]//{$WSRF::Constants::DS}DigestValue"
			  )
			  ? $envelope->valueof(
"/Envelope/Header/Security/Signature/SignedInfo/[$i]//{$WSRF::Constants::DS}DigestValue"
			  )
			  : die "WSRF::WSS::verify No DigestValue for $name";

#strip the # that is part of the XLink stuff for pointing to other parts of the XML doc
			$name =~ s/^\#//o;
			$SignedStuff{$name} = $DigestValue;
		}
		$i++;
	}

	my %Signed = ();
	foreach my $key ( keys %WSRF::WSS::ThingsThatShouldBeSigned ) {
		if (
			 $envelope->match(
				  "/Envelope//{$WSRF::WSS::ThingsThatShouldBeSigned{$key}}$key")
		  )
		{
			my $data =
			  $envelope->dataof(
				 "/Envelope//{$WSRF::WSS::ThingsThatShouldBeSigned{$key}}$key");
			my $attr = $data->attr;
			my $ID   = $attr->{"{$WSRF::Constants::WSU}Id"};
			$Signed{$key} = $ID;
		}
	}

	foreach my $key ( keys %Signed ) {
		my $parser        = XML::LibXML->new();
		my $doc           = $parser->parse_string( $envelope->raw_xml );
		my $CanonicalForm =
		  $doc->toStringEC14N( 0, $WSRF::WSS::Xpath{$key}, [''] );
		die "Could not get the Canonicalize $key from Envelope\n"
		  unless $CanonicalForm;
		my $token_digest = Digest::SHA1::sha1($CanonicalForm);
		$token_digest = MIME::Base64::encode($token_digest);
		chomp($token_digest);
		if ( $SignedStuff{ $Signed{$key} } eq $token_digest ) {

			#print "WSRF::WSS::verify Message \"$key\" is signed\n";
			$results{PartsSigned}{$key} = 'true';
		} else {
			die "WSRF::WSS::verify $key digest hashs do not match\n";
		}
	}

	$results{Created} =
	  $envelope->match(
		   "/Envelope/Header/Security/Timestamp/{$WSRF::Constants::WSU}Created")
	  ? $envelope->valueof(
		   "/Envelope/Header/Security/Timestamp/{$WSRF::Constants::WSU}Created")
	  : undef;

#print STDERR "WSRF::WSS::verify Message Created at $results{Created} (should be GMT)\n" if $results{Created};

	$results{Expires} =
	  $envelope->match(
		   "/Envelope/Header/Security/Timestamp/{$WSRF::Constants::WSU}Expires")
	  ? $envelope->valueof(
		   "/Envelope/Header/Security/Timestamp/{$WSRF::Constants::WSU}Expires")
	  : undef;

#print STDERR "WSRF::WSS::verify Message Expires at \"$results{Expires}\" (should be GMT)\n" if  $results{Expires};

	return %results;
}

1;
