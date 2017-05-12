package Yahoo::Marketing::AdGroup;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Yahoo::Marketing::ComplexType/;

=head1 NAME

Yahoo::Marketing::AdGroup - an object to represent a Yahoo Marketing AdGroup.

=cut

sub _user_setable_attributes {
    return ( qw/ 
                 ID
                 accountID
                 advancedMatchON
                 adAutoOptimizationON
                 campaignID
                 carrierConfig
                 contentMatchMaxBid
                 contentMatchON
                 name
                 sponsoredSearchMaxBid
                 sponsoredSearchON
                 status
                 watchON
            /  );
}

sub _read_only_attributes {
    return ( qw/
                 contentMatchBidStatus
                 contentMatchMaxBidTimestamp
                 contentMatchMinBid
                 createTimestamp
                 deleteTimestamp
                 lastUpdateTimestamp
                 sponsoredSearchMaxBidTimestamp
           / );
}

__PACKAGE__->mk_accessors( __PACKAGE__->_user_setable_attributes, 
                           __PACKAGE__->_read_only_attributes
                         );


1;
=head1 SYNOPSIS

See L<http://searchmarketing.yahoo.com/developer/docs/V7/reference/dataObjects.php> for documentation of the various data objects.


=cut

=head1 METHODS

=head2 new

Creates a new instance

=head2 get/set methods

=over 8

    ID
    accountID
    advancedMatchON
    campaignID
    carrierConfig
    contentMatchMaxBid
    contentMatchON
    name
    sponsoredSearchMaxBid
    sponsoredSearchON
    status
    watchON

=back

=head2 get (read only) methods

=over 8

    adAutoOptimizationON
    contentMatchBidStatus
    contentMatchMaxBidTimestamp
    contentMatchMinBid
    createTimestamp
    deleteTimestamp
    lastUpdateTimestamp
    sponsoredSearchMaxBidTimestamp

=back

=cut

