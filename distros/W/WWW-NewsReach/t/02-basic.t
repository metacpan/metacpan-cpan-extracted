use Test::More;

use WWW::NewsReach;

SKIP: {
  skip 'Set environment variable NEWSREACH_API_KEY for testing', 5
    unless defined $ENV{NEWSREACH_API_KEY};

  my $nr = WWW::NewsReach->new({ api_key => $ENV{NEWSREACH_API_KEY} });

  ok($nr, 'Got something');
  isa_ok($nr, 'WWW::NewsReach');
  is($nr->api_key, $ENV{NEWSREACH_API_KEY}, 'Correct api key');
  isa_ok($nr->ua, 'WWW::NewsReach::Client');
  ok($nr->get_news, 'Got some news items');
}

done_testing;
