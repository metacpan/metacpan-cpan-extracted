package Yahoo::Marketing::Test::KeywordParticipationStatus;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordParticipationStatus;

sub test_can_create_keyword_participation_status_and_set_all_fields : Test(3) {

    my $keyword_participation_status = Yahoo::Marketing::KeywordParticipationStatus->new
                                                                                   ->keywordID( 'keyword id' )
                                                                                   ->participationStatus( 'participation status' )
                   ;

    ok( $keyword_participation_status );

    is( $keyword_participation_status->keywordID, 'keyword id', 'can get keyword id' );
    is( $keyword_participation_status->participationStatus, 'participation status', 'can get participation status' );

};



1;

