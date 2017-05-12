#!/usr/bin/perl -w
use strict;


# Note:
# All dates coming back from use.perl are stored locally and manipulated by
# Time::Piece. This module is influenced by the timezone. No timezone testing
# is done by this distribution, so all dates are validate to be within 24 hours
# of the expected date.


use lib './t/lib';
use PingTest;

use Test::Exception;
use Test::More tests => 39;
use WWW::UsePerl::Journal;
use WWW::UsePerl::Journal::Thread;

my $pingtest = PingTest::pingtest('use.perl.org');

SKIP: {
	skip "Can't see a network connection", 25	if($pingtest);

    my $username  = 'barbie';
    my $entryid   = 13956;		# 
    my $threadid  = 14740;		# these are for the same journal entry
    my $commentid = 22842;      #

    my $journal = WWW::UsePerl::Journal->new($username);
    $journal->debug(1); # turn debugging on
    $journal->log('clear' => 1);

    ##
    ## Tests based on a entryid
    ##

    {
        my $thread = WWW::UsePerl::Journal::Thread->new(
                        eid	=> $entryid,
                        j	=> $journal,
        );

        isa_ok($thread,'WWW::UsePerl::Journal::Thread');

        my @cids = $thread->commentids();
        unless(@cids) {
            diag($journal->log());
            $journal->log('clear'=>1);
        }

        SKIP: {
            skip 'Cannot access comments from entry', 24    unless(@cids);

            is((@cids > 2),1);		# there's at least 3

            is($thread->thread(),$threadid);

            my @desc = $thread->commentids(descending => 1);
            my @thrd = $thread->commentids(threaded => 1);

            is_deeply(\@desc, [ reverse @cids ], 'descending threads');
            is_deeply([sort @thrd], [sort @cids], 'threaded entries');

            # first comment
            $commentid = 22842;
            my $comment = $thread->comment($commentid);
            isa_ok($comment,'WWW::UsePerl::Journal::Comment');

            my %hash_is = (
                cid		=> $commentid,	
                subject	=> 'Locales',
                user	=> 'Dom2',
                uid		=> 2981,
                score   => 3
            );

            my %hash_like = (
                content	=> qr|Turn them off now.|
            );

            for my $item (sort keys %hash_is) {
                my $value = $comment->$item();
                is($value,$hash_is{$item},"... testing $item");
            }
            for my $item (sort keys %hash_like) {
                my $value = $comment->$item();
                like($value,$hash_like{$item},"... testing $item");
            }

            my $d = eval { $comment->date(); };
            is($@, '', 'date() doesnt die on entries posted between noon and 1pm');

            diag($journal->log())   if($@);
            $journal->log('clear'=>1);

            #diag("d=$d, date=".$comment->date);

            SKIP: {
                skip 'Unable to parse date string', 2   unless($d);
                isa_ok($d, 'Time::Piece');

                my $s = $d->epoch;
                my $diff = abs($s - 1060220100);
                if($diff < 12 * 3600) {         # +/- 12 hours for a 24 hour period
                    ok(1, 'Date matches.');
                } else {
                    is $s => 1060220100, 'Date matches.';
                    diag($journal->log());
                    $journal->log('clear'=>1);
                }
            }

            my $text = "$comment";	# stringyfied version
            is($text,$comment->content());


            # subsequent comment
            $commentid = 22847;
            $comment = $thread->comment($commentid);
            isa_ok($comment,'WWW::UsePerl::Journal::Comment');

            %hash_is = (
                cid		=> $commentid,	
                subject	=> 'Re:Locales',
                user	=> 'barbie',
                uid		=> 2653,
                score   => 1
            );

            %hash_like = (
                content	=> qr|From the experience I\'ve just had that would be a good idea.|
            );

            for my $item (sort keys %hash_is) {
                my $value = $comment->$item();
                is($value,$hash_is{$item},"... testing $item");
            }
            for my $item (sort keys %hash_like) {
                my $value = $comment->$item();
                like($value,$hash_like{$item},"... testing $item");
            }

            is($comment->date(),undef,'no date provided');

            $text = "$comment";	# stringyfied version
            is($text,$comment->content());
        }
    }
}

##
## Tests without debug on
##

SKIP: {
	skip "Can't see a network connection", 10	if($pingtest);

    my $username  = 'barbie';
    my $entryid   = 13956;		# 
    my $threadid  = 14740;		# these are for the same journal entry
    my $commentid = 22842;      #

    my $journal = WWW::UsePerl::Journal->new($username);
    $journal->log('clear' => 1);

    ##
    ## Tests based on a entryid
    ##

    {
        my $thread = WWW::UsePerl::Journal::Thread->new(
                        eid	=> $entryid,
                        j	=> $journal,
        );

        isa_ok($thread,'WWW::UsePerl::Journal::Thread');
        is($thread->thread(),$threadid);

        my @cids = $thread->commentids();
        is((@cids > 2),1);		# there's at least 3
        my @cids2 = $thread->commentids();
        is((@cids2 > 2),1);		# there's at least 3
        is_deeply(\@cids,\@cids2, 'cache matches original');

        is($journal->log(),'','no logging');

        my $comment = WWW::UsePerl::Journal::Comment->new( j => $journal, eid => $entryid, cid => 1, extract => '' );
        isa_ok($comment,'WWW::UsePerl::Journal::Comment');
        is($comment->content,undef,'missing content');

        $comment = WWW::UsePerl::Journal::Comment->new( j => $journal, eid => $entryid, cid => 1, extract => 'blah blah blah' );
        isa_ok($comment,'WWW::UsePerl::Journal::Comment');
        is($comment->content,undef,'missing content');
    }
}

##
## Tests for failure
##
{
    my $thread = WWW::UsePerl::Journal::Thread->new();
    is($thread,undef,'missing parameters');
    dies_ok { my $thread = WWW::UsePerl::Journal::Thread->new( j => 'journal', eid => 1 ) } 'dies with invalid required parameters are missing';

    my $comment = WWW::UsePerl::Journal::Comment->new();
    is($comment,undef,'missing parameters');
    dies_ok { my $comment = WWW::UsePerl::Journal::Comment->new( j => 'journal', eid => 1, cid => 1, extract => '' ) } 'dies with invalid required parameters are missing';
}
