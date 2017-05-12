package XML::RPC::Enc;

=head1 NAME

XML::RPC::Enc - Base class for XML::RPC encoders

=head1 SYNOPSIS

Generic usage

    use XML::RPC::Fast;
    
    my $server = XML::RPC::Fast->new( undef, encoder => XML::RPC::Enc::LibXML->new );
    my $client = XML::RPC::Fast->new( $uri, encoder => XML::RPC::Enc::LibXML->new );

=cut

use strict;
use warnings;
use Carp;

# Base class for encoders

use XML::RPC::Fast ();
our $VERSION = $XML::RPC::Fast::VERSION;

=head1 METHODS

The following methods should be implemented

=cut

=head2 new (%args)

Should support arguments:

=over 4

=item internal_encoding [ = undef ]

Internal encoding. C<undef> means wide perl characters (perl-5.8.1+)

=item external_encoding [ = utf-8 ]

External encoding. Which encoding to use in composed XML

=back

=cut

sub new {
	my ( $pkg, %args ) = @_;
}

# Encoder part

=head2 request ($method, @args) : xml byte-stream, [ new call url ]

Encode request into XML

=cut

sub request {
	my ( $self, $method, @args ) = @_;
	croak "request not implemented by $self";
	#return $xml;
}

=head2 response (@args) : xml byte-stream

Encode response into XML

=cut

sub response {
	my ( $self, $method, @args ) = @_;
	croak "response not implemented by $self";
	#return $xml;
}

=head2 fault ($faultcode, $faultstring) : xml byte-stream

Encode fault into XML

=cut

sub fault {
	my ( $self, $faultcode, $faultstring ) = @_;
	croak "fault not implemented by $self";
	#return $xml;
}

=head2 registerClass ($class_name,$encoder_cb)

Register encoders for custom Perl types

Encoders description:

    # Generic:
    $simple_encoder_cb = sub {
        my $object = shift;
        # ...
        return type => $string;
    };

    # Encoder-dependent (XML::RPC::Enc::LibXML)
    $complex_encoder_cb = sub {
        my $object = shift;
        # ...
        return XML::LibXML::Node;
    };

Samples:

    $enc->registerClass( DateTime => sub {
        return ( 'dateTime.iso8601' => $_[0]->strftime('%Y%m%dT%H%M%S.%3N%z') );
    });

    # Encoder-dependent (XML::RPC::Enc::LibXML)
    $enc->registerClass( DateTime => sub {
        my $node = XML::LibXML::Element->new('dateTime.iso8601');
        $node->appendText($_[0]->strftime('%Y%m%dT%H%M%S.%3N%z'));
        return $node;
    });

=cut

sub registerClass {
	my ( $self,$class,$encoder ) = @_;
	croak "registerClass not implemented by $self";
}

# Decoder part

=head2 decode ($xml) : $methodname, @args

Decode request xml

=head2 decode ($xml) : @args

Decode response xml

=head2 decode ($xml) : { fault => { faultCode => ..., faultString => ... } }

Decode fault xml

=cut

sub decode {
	my ( $self, $xml ) = @_;
	croak "decode not implemented by $self";
	# return $methodname, @args if request
	# return @args if response
	# return { fault => { faultCode => ..., faultString => ... } } if fault
}

=head2 registerType ($xmlrpc_type,$decoder_cb)

Register decoders for XML-RPC types

$decoder_cb is depends on encoder implementation.

Samples for XML::RPC::Enc::LibXML

    $enc->registerType( base64 => sub {
        my $node = shift;
        return MIME::Base64::decode($node->textContent);
    });

    $enc->registerType( 'dateTime.iso8601' => sub {
        my $node = shift;
        return DateTime::Format::ISO8601->parse_datetime($node->textContent);
    });

=cut

sub registerType {
	my ( $self,$type,$decoder ) = @_;
	croak "registerType not implemented by $self";
}

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008-2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=cut

1;
