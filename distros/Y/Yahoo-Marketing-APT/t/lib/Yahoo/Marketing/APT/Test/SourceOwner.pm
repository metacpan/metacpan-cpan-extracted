package Yahoo::Marketing::APT::Test::SourceOwner;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SourceOwner;

sub test_can_create_source_owner_and_set_all_fields : Test(3) {

    my $source_owner = Yahoo::Marketing::APT::SourceOwner->new
                                                    ->sourceOwnerID( 'source owner id' )
                                                    ->sourceOwnerType( 'source owner type' )
                   ;

    ok( $source_owner );

    is( $source_owner->sourceOwnerID, 'source owner id', 'can get source owner id' );
    is( $source_owner->sourceOwnerType, 'source owner type', 'can get source owner type' );

};



1;

