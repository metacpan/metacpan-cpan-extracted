#!/usr/bin/perl -w
use strict;

use Test::Exception;
use Test::More tests => 23;
use WWW::UsePerl::Journal;

my $j = WWW::UsePerl::Journal->new('testuser');

SKIP: {
	skip "Can't see a network connection", 20	unless($j->connected);

    diag("connected=".$j->connected);

    my $username = "russell";
    my $entryid  = 2376;
    my $userid   = 1413;

    {
        $j = WWW::UsePerl::Journal->new($username);
        isa_ok($j, 'WWW::UsePerl::Journal');

        my $uid = $j->uid();

        is($uid, $userid, 'uid');

        my %entries = $j->entryhash;
        isnt(scalar(keys %entries), 0, 'entryhash');
        if(scalar(keys %entries) == 0) {
            diag("1.url=[http://use.perl.org/_$username/]");
            diag("WUJERR: " . $j->error);
        }
        my %cache = $j->entryhash;
        is(scalar(keys %cache),scalar(keys %entries), 'matching cached/entryhash count');
        #is_deeply(\%cache,\%entries, 'matching cached/entryhash values');

        #use Data::Dumper;
        #diag(Dumper(\%cache));

        # check entry ids
        my @ids = $j->entryids;
        isnt(scalar(@ids), 0, 'entryids');
        if(scalar(@ids) == 0) {
            diag("2.url=[http://use.perl.org/_$username/]");
            diag("WUJERR: " . $j->error);
        }

           @ids = sort {$a <=> $b} @ids;
        my @asc = $j->entryids(ascending  => 1);
        my @des = $j->entryids(descending => 1);
        my @rev = reverse @des;
        is_deeply(\@asc,\@ids,'ascending entryids');
        is_deeply(\@rev,\@ids,'descending entryids');

        # check caching
        my @c_ids = $j->entryids;
        my @c_asc = $j->entryids(ascending  => 1);
        my @c_des = $j->entryids(descending => 1);
        is_deeply(\@c_ids,\@c_ids,'cached threaded entryids');
        is_deeply(\@c_asc,\@asc,'cached ascending entryids');
        is_deeply(\@c_des,\@des,'cached descending entryids');

        #my %c = $j->entryhash;
        #use Data::Dumper;
        #diag(Dumper(\%c));


        # check entry titles
        my @titles = $j->entrytitles;
        isnt(scalar @titles, 0, 'entrytitles');
        if(scalar(@titles) == 0) {
            diag("3.url=[http://use.perl.org/_$username/]");
            diag("WUJERR: " . $j->error);
        }
        @asc = $j->entrytitles(ascending  => 1);
        @des = $j->entrytitles(descending => 1);
        @rev = reverse @des;
        is_deeply(\@rev,\@asc,'ordered entrytitles');

        # check caching
        my @c_titles = $j->entrytitles;
        @c_asc = $j->entrytitles(ascending  => 1);
        @c_des = $j->entrytitles(descending => 1);
        is_deeply(\@c_titles,\@titles,'cached threaded entrytitles');
        is_deeply(\@c_asc,\@asc,'cached ascending entrytitles');
        is_deeply(\@c_des,\@des,'cached descending entrytitles');

        # find another entry
        $j->debug(1);
        my $text = 'I read in <a href="_hfb/journal/index.html" rel="nofollow">hfb\'s journal</a> that there was no module for testing whether something was a pangram. There is now.';
        my $content = $j->entry('2340')->content;
        unless($content) {
            diag("4.url=[http://use.perl.org/_$username/journal/2340.html]");
            diag($j->log());
        }

        cmp_ok($content, 'eq', $text, 'entry compare' );
        $content = $j->entrytitled('Lingua::Pangram')->content;
        cmp_ok($content, 'eq', $text, 'entrytitled compare' );
    }

    {
        my $j = WWW::UsePerl::Journal->new(1662);
        my $user = $j->user;
        is($user, 'richardc', 'username from uid');
        if($user ne 'richardc') {
            diag("5.url=[http://use.perl.org//journal.pl?op=list&uid=1662]");
            diag("WUJERR: " . $j->error);
        }
    }

    {
        my $j = WWW::UsePerl::Journal->new('2shortplanks');
        my %entries = eval { $j->entryhash; };
        is($@, '', 'entryhash doesnt die on titles with trailing newlines');
        isnt(scalar(keys %entries), 0, '...and has found some entries');
        if(scalar(keys %entries) == 0) {
            diag("6.url=[http://use.perl.org/_2shortplanks/]");
            diag("WUJERR: " . $j->error);
        }
    }
}

# catch some errors
{
    my $j;
    dies_ok { $j = WWW::UsePerl::Journal->new(); } 'dies if no username given';

    my $entry = WWW::UsePerl::Journal::Entry->new();
    is($entry,undef,'missing parameters');
    dies_ok { my $entry = WWW::UsePerl::Journal::Entry->new( j => 'journal', eid => 1, author => 'me' ) } 'dies with invalid required parameters are missing';
}
