
use Test::More skip_all => "At present, add bookmark api test does skip";

use strict;
use WebService::BuzzurlAPI;


SKIP: {

    if(!$ENV{BUZZURL_EMAIL} || !$ENV{BUZZURL_PASSWORD}){
        warn "\$ENV{BUZZURL_EMAIL} or \$ENV{BUZZURL_PASSWORD} is not exported";
        skip "\$ENV{BUZZURL_EMAIL} or \$ENV{BUZZURL_PASSWORD} is not exported", 1;
    }
    
    my $buzz = WebService::BuzzurlAPI->new(
                                           email => $ENV{BUZZURL_EMAIL},
                                           password => $ENV{BUZZURL_PASSWORD}
                                          );
    my $res = $buzz->add(
                         url => "http://buzzurl.jp/",
                         title => "my bookmark title",
                         comment => "my bookmark comment",
                         keyword => [ "my keyword1", "my keyword2"
                        );
    ok($res->is_success);
} # end SKIP BLOCK

