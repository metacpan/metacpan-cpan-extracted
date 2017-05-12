use strict;
use warnings;

use lib 't';

use Test::More tests => 11;    # last test to print

use FakeOhloh;
use Validators;

my $ohloh = Fake::Ohloh->new;

$ohloh->stash( 'yadah', 'messages.xml' );

my $messages = $ohloh->fetch_messages( account => 'Yanick' );

isa_ok $messages, 'WWW::Ohloh::API::Messages',
  'fetch_messages is a W:O:A:M object';

my @messages = $messages->all;

is @messages, 4, 'we have 4 messages';

my $mess = shift @messages;

is $mess->id      => 4024,     'id()';
is $mess->account => 'Yanick', 'account()';
is $mess->avatar =>
  'http://www.gravatar.com/avatar.php?gravatar_id=a15c336550dd22cbdff9743a54b56b3b',
  'avatar()';
is $mess->creation_time => '2008-07-15T00:40:25Z', 'creation_time()';
is $mess->body => 'Adding messages to the API of #www-ohloh-api', 'body()';

my @tags = $mess->tags;

is @tags => 1, 'tags()';

my $tag = $tags[0];

is $tag->type => 'project', 'tag type';
is $tag->uri => 'http://www.ohloh.net/projects/www-ohloh-api', 'tag uri';
is $tag->content => 'WWW::Ohloh::API', 'tag content';

