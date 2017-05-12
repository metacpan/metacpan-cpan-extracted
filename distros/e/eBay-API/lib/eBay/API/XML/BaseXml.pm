package eBay::API::XML::BaseXml;

##########################################################################
#
# Module: ............... <user defined location>/eBay/API/XML
# File: ................. BaseXml.pm
# Original Author: ...... Jeff Nokes	
#
# Convert to UNIX lines
#
##########################################################################

=pod

=head1 NAME

eBay::API::XML::BaseXml - Configuration methods for XML-specific aspects

=head1 INHERITANCE

eBay::API::XML::BaseXml inherits from the L<eBay::API::BaseApi> class

=head1 DESCRIPTION

This top-level Perl module encapsulates all the functionality for the
eBay XML-specific aspects of the eBay API.  This library is really a
parent class wrapper to the classes eBay::API::XML::Session, and the
various call classes.

=cut

# Required Includes
# --------------------------------------------------------------------------
use strict;                   # Used to control variable hell.
use eBay::API::BaseApi;
use Exporter;                 # For Perl symbol export functionality.
use Data::Dumper;             # Used for logging support.

# Variable Declarations
# --------------------------------------------------------------------------
# Constants
use constant TRUE    => scalar 1;
use constant FALSE   => scalar 0;

# Global Variables
our @ISA = ("Exporter",
	    "eBay::API::BaseApi"
);     # Need to sub the Exporter class, to use the EXPORT* arrays below.

=head1 Subroutines

=cut



# Subroutine Prototypes
# --------------------------------------------------------------------------------
# Method Name                              Accessor Privileges      Method Type

sub setApiUrl($$;);                   #         Public                Instance
sub getApiUrl($;);                    #         Public                Instance



# Main Script
# --------------------------------------------------------------------------------


# Subroutine Definitions
# --------------------------------------------------------------------------------





=head2 setApiUrl()

Setter method to define the URL all eBay XML API requests are sent to.
This instance variable is normally set via the
$ENV{EBAY_API_XML_TRANSPORT} but this method can override it.

Arguments:

=over 4

=item *

Reference to object of type eBay::API::XML.

=item *

Scalar representing the fully qualified URL of the eBay XML API proxy.

=back

Returns:

=over 4

=item *

B<success> The value of eBay API URL (should be the same value that
was provided by the user)

=item *

B<error>    undefined

=back

=cut


  sub setApiUrl($$;) {

    # Local Variables
    my $this_sub = 'setApiUrl';

    # Get all values passed in.
    my($self, $proxy) = @_;

# Todo: validate $self is right class of object

    # Set the proxy
    $self->{proxy} =  $proxy;

    # Return success to the caller.
    return($proxy);

  }# end sub setApiUrl()



=head2 getApiUrl()

Local getter method for getting the current value of eBay API URL.

Arguments:

=over 4

=item *

Reference to object of type eBay::API::XML.

=back

Returns:

=over 4

=item *

B<success>  The value of eBay API URL.

=item *

B<error>    undefined

=back

=cut



  sub getApiUrl($;) {

    # Local Variables
    my($self) = @_;

    # Return success to the caller.
    return($self->{proxy});

  }# end sub getApiUrl()







# Return TRUE to perl
1;
