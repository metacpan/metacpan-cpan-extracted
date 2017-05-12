#!/usr/bin/perl -w
use strict;

use Test::More tests => 16;
use WWW::UsePerl::Journal;
use WWW::UsePerl::Journal::Entry;

my $j = WWW::UsePerl::Journal->new('testuser');

SKIP: {
	skip "Can't see a network connection", 16	unless($j->connected);

    my $username = "russell";
    my $entryid  = 2376;
    my $userid   = 1413;

    $j = WWW::UsePerl::Journal->new($username);
    isa_ok($j,'WWW::UsePerl::Journal');
    my $e = WWW::UsePerl::Journal::Entry->new(j=>$j);
    is($e,undef);
    $e = WWW::UsePerl::Journal::Entry->new(j=>$j,author=>$username,eid=>$entryid);
    isa_ok($e,'WWW::UsePerl::Journal::Entry');

    diag('WUJERR: ' . ($j->error()||'<none>'))  unless($e);

    $j->debug(1);
    is($e->eid,       $entryid, 'entry id');
    is($e->author,    $username,'user name');

    if($e->eid) {
        is($e->subject,   'WWW::UsePerl::Journal',       'subject');
        like($e->date,    qr/Thu Jan 24 \d+:10:00 2002/, 'date');
        like($e->content, qr/^Get it from CPAN now/,     'content');

        # can we find after a refresh?
        $j->refresh;
        $e = $j->entrytitled(qr/^WWW::UsePerl::Journal$/);
        isa_ok($e,'WWW::UsePerl::Journal::Entry');

        is($e->eid,       $entryid, 'entry id after refresh');
        like($e->content, qr/^Get it from CPAN now/,     'content');
        is($e->subject,   'WWW::UsePerl::Journal',       'subject');
        like($e->date,    qr/Thu Jan 24 \d+:10:00 2002/, 'date');

        $e = $j->entrytitled(qr/^Does Not Exist$/);
        is($e,undef);

        $e = $j->entrytitled('Lingua::Pangram');
        isa_ok($e,'WWW::UsePerl::Journal::Entry');

        $e = $j->entrytitled('Does Not Exist');
        is($e,undef);

    } else {
        diag("url=[http://use.perl.org/_$username/journal/$entryid.html]");
        diag('raw=[' . $j->raw($entryid) . ']');
        diag('log=[' . $j->log() . ']');
        ok(0) for(1..5);
    }
}
