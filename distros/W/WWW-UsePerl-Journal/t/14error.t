#!/usr/bin/perl -w
use strict;

use Test::More tests => 15;
use WWW::UsePerl::Journal;


# bad username error
my $username = "anonexistentuser";
my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j, "WWW::UsePerl::Journal");
my $uid = $j->uid();
is($uid, undef, "no uid");
my $err = $j->error;
like($err, qr/Cannot connect to|Cannot obtain userid/, "... error: failed to get uid");
my %entries = eval { $j->entryhash; };
is(scalar(%entries), 0, "no entries");


# bad userid error
$uid = 999999;
$j = WWW::UsePerl::Journal->new($uid);
isa_ok($j, "WWW::UsePerl::Journal");
$username = $j->user();
is($username, undef, "no user");
$err = $j->error;
like($err, qr/Cannot connect to|Cannot obtain username/, "... error: failed to get user");


# no user details error
%entries = $j->entryhash;
is(scalar(%entries), 0, "no entries");
like($j->error, qr/Could not retrieve user details/, "... error: failed to get entries");


# find title error
my $e = $j->entrytitled('Test');
is($e, undef, 'no entry title found' );
like($j->error, qr/Test does not exist/, "... error: failed to find title");

# missing params
eval { $j = WWW::UsePerl::Journal->new() };
like($@, qr/No user specified!/, "missing params to WWW::UsePerl::Journal->new");

#----

$username = "russell";
my $entryid  = 999999;

$j = WWW::UsePerl::Journal->new($username);
$e = WWW::UsePerl::Journal::Entry->new(j=>$j,author=>$username,eid=>$entryid);
isa_ok($e,'WWW::UsePerl::Journal::Entry');

SKIP: {
	skip "Can't see a network connection", 2	unless($j->connected);

    is($e->_get_content, undef, 'missing entry');
    like($j->error, qr/(does not exist|error getting entry)/, "... error: missing entry");
}
