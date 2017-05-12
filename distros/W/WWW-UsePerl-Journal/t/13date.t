#!/usr/bin/perl -w
use strict;


# Note:
# All dates coming back from use.perl are stored locally and manipulated by
# Time::Piece. This module is influenced by the timezone. No timezone testing
# is done by this distribution, so all dates are validate to be within 24 hours
# of the expected date.


use Test::More tests => 9;

use_ok('WWW::UsePerl::Journal');

my $j = WWW::UsePerl::Journal->new(147);
isa_ok($j, 'WWW::UsePerl::Journal');

$j->debug(1);
my $e = $j->entry('8028');

SKIP: {
    skip 'WUJERR: ' . ($j->error()||'<none>'), 7   unless($e);
    isa_ok($e, 'WWW::UsePerl::Journal::Entry');
    my $d = eval { $e->date(); };
    is($@, '', 'date() doesnt die on entries posted between noon and 1pm');

    diag($j->log())  if($@);
    $j->log('clear' => 1);

    SKIP: {
        skip 'WUJERR: Unable to parse date string', 2   unless($d);
        isa_ok($d, 'Time::Piece');

        my $s = $d->epoch;
        my $diff = abs($s - 1033030020);
        if($diff < 12 * 3600) {         # +/- 12 hours for a 24 hour period
            ok(1, 'Date matches.');
        } else {
            is $s => 1033030020, 'Date matches.';
            diag("url=[http://use.perl.org/147/journal/8028]");
            diag($j->raw('8028'));
            diag($j->log());
            $j->log('clear' => 1);
        }
    }

    $j = WWW::UsePerl::Journal->new(1296);
    $e = $j->entry('3107');
    $d = eval { $e->date(); };
    is($@, '', 'date() doesnt die on entries posted between noon and 1pm');

    SKIP: {
        skip 'WUJERR: Unable to parse date string', 2   unless($d);
        isa_ok($d, 'Time::Piece');

        my $s = $d->epoch;
        my $diff = abs($s - 1014637200);
        if($diff < 12 * 3600) {         # +/- 12 hours for a 24 hour period
            ok(1, '...and gives the right date');
        } else {
            is $s => 1014637200, '...and gives the right date';
            diag("url=[http://use.perl.org/1296/journal/3107]");
            diag($j->raw('3107'));
            diag($j->log());
            $j->log('clear' => 1);
        }
    }
}
