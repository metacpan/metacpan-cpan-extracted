#!/usr/bin/perl

use warnings;
use Data::Dumper;
use Test::More 'no_plan';
use lib './lib';

use_ok('WWW::A9Toolbar');

if(!$ENV{A9USER} || !$ENV{A9PASSWD})
{
    warn "No A9USER and A9PASSWD found, aborting connection tests";
    exit;
}

my $a9 = WWW::A9Toolbar->new({email    => $ENV{A9USER},
                              password => $ENV{A9PASSWD},
                              connect  => 1});
isa_ok($a9, 'WWW::A9Toolbar');
ok($a9->customer_id(), 'Got a customer ID');
ok($a9->get_userdata(), 'Got user data');
ok($a9->get_bookmarks(), 'Got bookmarks');

my $lj = $a9->add_bookmark({title => 'LJ', url => 'http://www.livejournal.com',
                            type => 'url'});
is($lj->{url}, 'http://www.livejournal.com', 'Added LJ bookmark');
ok($lj->{guid}, 'Got new GUID for LJ');

ok($a9->delete_bookmark($lj), 'Deleted LJ bookmark');

my @ljs = $a9->find_bookmarks({url => qr!\Qhttp://www.livejournal.com\E!});
is(scalar @ljs, 0, 'Found no LJ bookmarks');

# $a9->get_diary_entries();

my $result = $a9->add_diary_entry({url => 'http://www.opera.com',
                                   text => 'Opera!',
                                   title => 'Opera'});

