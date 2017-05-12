#!perl

use strict;
use warnings;
use Test::More;
use WWW::Piwik::API;
use Data::Dumper;

my $tracker = WWW::Piwik::API->new(endpoint => $ENV{PIWIK_URL} || 'http://localhost/piwik.php',
                                   idsite => $ENV{PIWIK_IDSITE} || 1,
                                   token_auth => $ENV{PIWIK_TOKEN_AUTH} || 'blablabla',
                                  );
ok($tracker);
my %data = (
            action_name => 'order',
            idgoal => 0,
            ec_id => '999999' . int(rand(100000)),
            ec_items => [
                         [ 8888, 'test item', 'test category', 10, 1 ],
                        ],
            revenue => 69,
            country => 'DE',
            url => $ENV{PIWIK_TARGET} || 'http://localhost/'
           );

my $uri = $tracker->track_uri(%data);
ok ($uri);
is_deeply({ $uri->query_form },
          {
           %data,
           ec_items => '[[8888,"test item","test category",10,1]]',
           idsite => $tracker->idsite,
           token_auth => $tracker->token_auth,
           rec => 1,
           bots => 1,
          });

ok($tracker->track_uri(%data));

# real url
if ($ENV{PIWIK_URL} && $ENV{PIWIK_IDSITE}) {
    my $res = $tracker->track(%data);
    ok($res);
}

done_testing;
