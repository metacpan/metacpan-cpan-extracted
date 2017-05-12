package Yahoo::Marketing::APT::LibraryThirdPartyAd;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Yahoo::Marketing::ComplexType/;

=head1 NAME

Yahoo::Marketing::APT::LibraryThirdPartyAd - a data object to represent a LibraryThirdPartyAd.

=cut

sub _user_setable_attributes {
    return ( qw/ 
                 ID
                 accountID
                 adBehavior
                 adFormat
                 adSecurity
                 adSizeID
                 associatedToPlacement
                 createTimestamp
                 editorialStatus
                 folderID
                 height
                 impressionTrackingURL
                 lastUpdateTimestamp
                 name
                 status
                 tag
                 tagWithMacros
                 type
                 vendorID
                 width
            /  );
}

sub _read_only_attributes {
    return ( qw/
           / );
}

__PACKAGE__->mk_accessors( __PACKAGE__->_user_setable_attributes, 
                           __PACKAGE__->_read_only_attributes
                         );


1;
=head1 SYNOPSIS

See L<http://help.yahoo.com/l/us/yahoo/ewsapt/webservices/reference/data/> for documentation of the various data objects.


=cut

=head1 METHODS

=head2 new

Creates a new instance

=head2 get/set methods

=over 8

    ID
    accountID
    adBehavior
    adFormat
    adSecurity
    adSizeID
    associatedToPlacement
    createTimestamp
    editorialStatus
    folderID
    height
    impressionTrackingURL
    lastUpdateTimestamp
    name
    status
    tag
    tagWithMacros
    type
    vendorID
    width

=back

=head2 get (read only) methods

=over 8


=back

=cut

