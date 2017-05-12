use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my($user,$pass,$server,$type) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan skip_all => 'test requires LJ (not DW) server' if defined $type && $type eq 'dw';

plan tests => 12;

my $client = WebService::LiveJournal->new(
  server => $server,
  username => $user,
  password => $pass,
);

do {
  my $list = $client->get_friends;
  isa_ok $list, 'WebService::LiveJournal::FriendList';
  my($me)       = grep { $_->username eq $user } @$list;
  isa_ok $me, 'WebService::LiveJournal::Friend';
  is $me->username, $user, "me.username = $user";
};

do {
  my $friends = $client->get_friends;
  isa_ok $friends,    'WebService::LiveJournal::FriendList';
};

do {
  my($friends, $friends_of, $groups) = $client->get_friends(complete => 1);
  isa_ok $friends,    'WebService::LiveJournal::FriendList';
  isa_ok $friends_of, 'WebService::LiveJournal::FriendList';
  isa_ok $groups,     'WebService::LiveJournal::FriendGroupList';
  
  my($family) = grep { $_->name eq 'Family' } @$groups;
  isa_ok $family, 'WebService::LiveJournal::FriendGroup';
  is $family->name, 'Family', 'family.name = Family';
};

do {
  my $groups = $client->get_friend_groups;
  isa_ok $groups,     'WebService::LiveJournal::FriendGroupList';
  
  my($family) = grep { $_->name eq 'Family' } @$groups;
  isa_ok $family, 'WebService::LiveJournal::FriendGroup';
  is $family->name, 'Family', 'family.name = Family';
};

