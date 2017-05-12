
use Test::More qw(no_plan);

use strict;
use WebService::BuzzurlAPI;

SKIP: {

    if(!$ENV{BUZZURL_USERID}){
        warn "\$ENV{BUZZURL_USERID} is not exported";
        skip "\$ENV{BUZZURL_USERID} is not exported", 1;
    }
    
    my $buzz = WebService::BuzzurlAPI->new;
    my $res = $buzz->user_articles( userid => $ENV{BUZZURL_USERID} );
    ok($res->is_success);
} # end SKIP BLOCK

