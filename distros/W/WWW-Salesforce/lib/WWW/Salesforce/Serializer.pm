package WWW::Salesforce::Serializer;

use strict;
use warnings;
use SOAP::Lite;

our @ISA = qw( SOAP::Serializer );

our $VERSION = '0.401';


#**************************************************************************
# encode_object( $object, $name, $type, $attr )
#   -- overloaded encode_object() function to take care of problem
#     with xsi:nil="true" attribute of tags that have no attributes
#**************************************************************************
sub encode_object {
    my ( $self, $object, $name, $type, $attr ) = @_;

#print "\n\t\t",$name," *********************************************\n" if $name;
    if ( defined $attr->{'xsi:nil'} ) {
        delete $attr->{'xsi:nil'};
        return [ $name, {%$attr} ];
    }
    return $self->SUPER::encode_object( $object, $name, $type, $attr );
}

1;
