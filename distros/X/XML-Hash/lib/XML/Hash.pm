package XML::Hash;

use warnings;
use strict;
use base qw/XML::Simple/;
use Carp;
use XML::DOM;
use File::Slurp; 

# Config options
our %XMLIN_SIMPLE_OPTIONS = (
    ForceContent => 1,
    ContentKey   => 'text',
    KeepRoot     => 1,
    KeyAttr      => []
);

our %XMLOUT_SIMPLE_OPTIONS = (
    ContentKey => 'text',
    KeepRoot   => 1,
    KeyAttr    => []
);

our $VERSION = '0.95';

sub new {
    my $class = shift;

    if ( @_ % 2 ) {
        croak "Default options must be name=>value pairs (odd number supplied)";
    }

    my %raw_opt = @_;

    my %def_opt;

    while ( my ( $key, $val ) = each %raw_opt ) {
        my $lkey = lc($key);
        $def_opt{$lkey} = $val;
    }

    my $self = { def_opt => \%def_opt };

    $class = ref $class if ref $class;

    $self = bless( $self, $class );

    $self->_xml_handler( XML::Simple->new(%XMLIN_SIMPLE_OPTIONS) );
    return $self;
}

sub _xml_handler {
	my ($self, $handler) = @_;
	
	$self->{'xml_handler'} ||= $handler; 
	
	return $self->{'xml_handler'};
}
sub fromDOMtoHash {
    my ( $self, $xml ) = @_;

    croak "You must specify a XML::DOM::Document has the XML parameter" unless ( ref($xml) eq "XML::DOM::Document" );

    return $self->fromXMLStringtoHash( $xml->toString() );
}

sub fromHashtoDOM {
    my ( $self, $hash ) = @_;

    croak "You must specify a Hash to converto into XML" unless ( ref($hash) eq "HASH" );

    my $xml_string = $self->fromHashtoXMLString($hash);
    return XML::DOM::Parser->new()->parse($xml_string);
}

sub fromXMLStringtoHash {
    my ( $self, $xml_str ) = @_;

    croak "You must specify a XML string" unless ( defined $xml_str );

    return $self->_xml_handler()->XMLin( $xml_str, %XMLIN_SIMPLE_OPTIONS );
}

sub fromHashtoXMLString {
    my ( $self, $hash ) = @_;

    croak "You must specify a Hash to converto into XML" unless ( ref($hash) eq "HASH" );

    return $self->_xml_handler()->XMLout( $hash, %XMLOUT_SIMPLE_OPTIONS );

}

#sub fromXMLFiletoHash {
#    my ( $self, $xml_str ) = @_;
#
#    croak "You must specify a filename" unless ( defined $xml_str );

#    return $self->xml_handler()->XMLin( $xml_str, %XMLIN_SIMPLE_OPTIONS );
#}

#sub fromHashtoXMLFile {
#    my ( $self, $hash, $filename ) = @_;

#    croak "You must specify a Hash to convert into XML file" unless ( ref($hash) eq "HASH" and $filename);
	
#	my $output = $self->xml_handler()->XMLout( $hash, %XMLOUT_SIMPLE_OPTIONS );
	
#	write_file($filename, $output);
	
#	return $output; 
#}

1;    # End of XML::Hash

__END__

=head1 NAME

XML::Hash - Converts from a XML into a Hash.

=head1 SYNOPSYS

	my $xml_converter = XML::Hash->new();

	# Convertion from a XML String to a Hash
	my $xml_hash = $xml_converter->fromXMLStringtoHash($xml);

	# Convertion from a Hash back into a XML String
	my $xml_str = $xml_converter->fromHashtoXMLString($xml_hash);

	#  Convertion from a XML::DOM::Document into a HASH
	$xml_hash = $xml_converter->fromDOMtoHash($xml_doc);

	# Convertion from a HASH back info a XML::DOM::Document
	my $xml_doc = $xml_converter->fromHashtoDOM($xml_hash);

=head1 DESCRIPTION

Simplifies the XML manipulation of documents by converting XML to perl Hashes. 

You can manipulate the perl Hash and dump back to XML file. It accepts strings as well as XML::DOM::Documents. 
Also provides reverse methods that convert the Hash back into string/XML::DOM::Documents.

The interface it is OO based and extents XML::Simple functionality.

=head1 METHODS

=over 2

=item B<new>

	Constructor: passes the default options to XML::Simple superclass

=item B<fromDOMtoHash>

	Converts from XML::DOM::Document to a Hash

	$self->fromDOMtoHash($doc)


=item B<fromHashtoDOM>

	Converts from a HASH into XML::DOM::Document

	$self->fromHashtoDOM($hash)

=item B<fromXMLStringtoHash>

	Converts from a XML String to a Hash

	$self->fromXMLStringtoHash($str)

=item B<fromHashtoXMLString>

	Converts from a Hash into a XML String

	$self->fromHashtoXMLString($hash)

=back

=head1 AUTHOR

Luis Azevedo, C<< <braceta@cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Hash

=head1 COPYRIGHT & LICENSE

Copyright 2008 Luis Azevedo, all rights reserved.

This program is free software licensed under the BSD License

The full text of the license can be found in the
LICENSE file included with this module.
