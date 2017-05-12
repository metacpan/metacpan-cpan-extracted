#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More tests => 11;
#use Test::More 'no_plan';
use WWW::PGXN;

SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
}

# Set up the WWW::PGXN object.
my $pgxn = new_ok 'WWW::PGXN', [ url => 'file:t/mirror' ];

##############################################################################
# Try to get a nonexistent user.
ok !$pgxn->get_user('nonexistent'),
    'Should get nothing when searching for a nonexistent user';

# Fetch user data.
ok my $user = $pgxn->get_user('theory'),
    'Find user "theory"';
isa_ok $user, 'WWW::PGXN::User', 'It';
can_ok $user, qw(
    new
    nickname
    name
    email
    uri
    twitter
    releases
);

is $user->nickname, 'theory', 'Should have nickname';
is $user->name, 'David E. Wheeler', 'Should have name';
is $user->email, 'david@justatheory.com', 'Should have email';
is $user->uri, 'http://justatheory.com/', 'Should have URI';
is $user->twitter, 'theory', 'Should have twitter nick';
is_deeply $user->releases, {
    explanation => { stable => [
        {version => "0.2.0", date => '2011-02-21T20:14:56Z'},
    ] },
    pair => { stable => [
        {version => "0.1.0", date => '2010-10-19T03:59:54Z'},
    ] },
}, 'Should have release data';
