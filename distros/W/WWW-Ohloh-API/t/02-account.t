use strict;
use warnings;

use Test::More qw/ no_plan /;    # last test to print

require 't/FakeOhloh.pm';

my $ohloh = Fake::Ohloh->new;

$ohloh->stash( 'http://www.ohloh.net/accounts/12933.xml?v=1&api_key=myapikey',
    'account.xml' );

my $account = $ohloh->get_account( id => 12933 );

like $account->as_xml => qr# ^ \s* <account> .* </account> \s* $ #sx,
  'as_xml()';

is $account->request_url =>
  'http://www.ohloh.net/accounts/12933.xml?v=1&api_key=myapikey',
  'request url';
is $account->id   => 12933,    'id';
is $account->name => 'Yanick', 'name';
isa_ok $account->created_at => 'Time::Piece';
is $account->updated_at     => '2008-01-03T14:53:18Z', 'updated at';
is $account->homepage_url   => '', "homepage url";
is $account->avatar_url =>
  'http://www.gravatar.com/avatar.php?gravatar_id=a15c336550dd22cbdff9743a54b56b3b',
  "avatar url";
is $account->posts_count  => 613,                  'posts count';
is $account->location     => 'Ottawa, ON, Canada', 'location';
is $account->country_code => 'CA',                 "country code";
is $account->latitude     => '45.423494',          "latitude";
is $account->longitude    => '-75.697933',         "longitude";

my $kudo = $account->kudo_score;
ok $kudo, "kudo score";

is $kudo->created_at     => '2008-01-03T05:16:25Z', 'kudo created at';
is $kudo->kudo_rank      => '7',                    'kudo rank';
is $kudo->rank           => '7',                    'kudo rank (short)';
is $kudo->position       => '8684',                 'kudo position';
is $kudo->max_position   => '84400',                'kudo max_position';
is $kudo->position_delta => '-56',                  'kudo position_delta';

like $kudo->as_xml => qr# ^ \s* <kudo_score> .* </kudo_score> \s* $ #sx,
  'kudo as_xml()';

# stack

$ohloh->stash( 'stack', 'stack.xml' );

my $stack = $account->stack;

isa_ok $stack, 'WWW::Ohloh::API::Stack';

$stack->account;

