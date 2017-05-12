package XML::DB::ErrorCodes;
use strict;

=head1 NAME 

XML::DB::ErrorCodes - constants for error codes used by the XML:DB API

=head1 SYNOPSIS

  use XML::DB::ErrorCodes;

=head1 DESCRIPTION

ErrorCodes defines XML:DB error codes that can be used to set the 
errorCode returned by 'die'

=head1 BUGS

This module is not yet in use. The whole error-handling system needs fixing.

=cut

BEGIN {
    use Exporter ();
    use vars qw (@EXPORT);
    @EXPORT      = qw (%error_codes %error_strings);


    # XMLDB API error codes
    my %error_codes = (
		# Set when a more detailed error can not be determined.
		UNKNOWN_ERROR => 0,   
		# Set when a vendor specific error has occured.
		VENDOR_ERROR => 1,  
		# Set if the API implementation does not support the operation being invoked.
		NOT_IMPLEMENTED => 2,
                # Set if the content of a Resource is set to a content type
                # different from that which the Resource was intended to
                # support.
		WRONG_CONTENT_TYPE => 3,  
                # Set if access to the requested Collection can not be granted
                # due to the lack of proper credentials.
		PERMISSION_DENIED => 4,  
                # Set if the URI format is invalid.
		INVALID_URI => 5,  
                # Set if the requested Service could not be located.
                NO_SUCH_SERVICE => 100,  
                # Set if the requested Collection could not be located.
		NO_SUCH_COLLECTION => 200,  
                # Set if the Collection instance is in an invalid state.
		INVALID_COLLECTION => 201,  
                # Set when an operation is invoked against a Collection
                # instance that has been closed.
		COLLECTION_CLOSED => 202,
                # Set if the requested Resource could not be located.
		NO_SUCH_RESOURCE => 300,    
                # Set if the Resource provided to an operation is invalid.
                INVALID_RESOURCE => 301,  
                # Set if the resource type requested is unknown to the API implementation.
		UNKNOWN_RESOURCE_TYPE => 302,
                # Set if a Database instance can not be located for the provided URI.
		NO_SUCH_DATABASE => 400,  
                # Set if the Database instance being registered is invalid.
		INVALID_DATABASE => 401,  
	    );
	    # XML DB API error code reverse lookup
    my %error_strings = (
		0 => 'UNKNOWN_ERROR',   
		1 => 'VENDOR_ERROR',  
		2 => 'NOT_IMPLEMENTED',
		3 => 'WRONG_CONTENT_TYPE',  
		4 => 'PERMISSION_DENIED',  
		5 => 'INVALID_URI',  
                100 => 'NO_SUCH_SERVICE',  
		200 => 'NO_SUCH_COLLECTION',  
		201 => 'INVALID_COLLECTION',  
		202 => 'COLLECTION_CLOSED',
		300 => 'NO_SUCH_RESOURCE',    
                301 => 'INVALID_RESOURCE',  
		302 => 'UNKNOWN_RESOURCE_TYPE',
		400 => 'NO_SUCH_DATABASE',  
		401 => 'INVALID_DATABASE',
	    ); 
    }

1;
