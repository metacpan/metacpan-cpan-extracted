use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 6;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal->new(
  server => $server,
  username => $user,
  password => $pass,
);

while(1)
{
  my $list = $client->getevents('lastn', howmany => 50);
  last unless @$list > 0;
  foreach my $event (@$list)
  {
    note "deleting $event";
    $event->delete;
  }
}

$client
  ->create( subject => 'spaceballs', event => 'watch out we are the spaceballs' )
  ->set_tags('spaceballone')
  ->save;

my($tag) = grep { $_->name eq 'spaceballone' } eval { $client->get_user_tags };
diag $@ if $@;

isa_ok $tag, 'WebService::LiveJournal::Tag';

is $tag->name, 'spaceballone', 'tag.name = spaceballone';
is $tag->display, 1, 'tag.display = 1';

is $tag->security_level, 'public', 'tag.security_level = public';
is $tag->uses, 1, 'tag.uses = 1';

is $tag->security->{public}, 1, 'tag.security.public = 1';
