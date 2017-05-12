#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use WWW::Lipsum;

my $l_test = WWW::Lipsum->new;
isa_ok($l_test, 'WWW::Lipsum');
can_ok($l_test, qw/what  amount  html  start  generate  lipsum  error/);

is( $l_test->what,   'paras', 'Default `what` is `paras`');
is( $l_test->amount, 5,       'Default `amount` is `5`'  );
is( $l_test->html,   0,       'Default `html` is `0`'    );
is( $l_test->start,  1,       'Default `start` is `1`'   );

my $l = WWW::Lipsum->new(
    what    => 'bytes',
    amount  => 1000,
    html    => 1,
    start   => 0,
);

is( $l->what,   'bytes', 'can change `what` arg in ->new'  );
is( $l->amount, 1000,    'can change `amount` arg in ->new');
is( $l->html,   1,       'can change `html` arg in ->new'  );
is( $l->start,  0,       'can change `start` arg in ->new' );

SKIP: {
    $l->start(1);
    $l->html(0);
    my $text = $l->generate;
    unless ( $text ) {
        if ( $l->error =~ /^Network/ ) {
            diag "Got error: " . ($l->error ? $l->error : '[undefined]');
            skip 'Got network error: ' . $l->error, 1;
        }
        else {
            BAIL_OUT 'Got weird error! ' . $l->error;
        }
    }
    like( $text, qr/^Lorem ipsum/, 'The text we got matches Lipsum' );
}

SKIP: {
    $l->start(1);
    $l->html(0);
    my $text = "$l";
    if ( $text =~ /\[Error/ ) {
        if ( $l->error =~ /Network/ ) {
            diag "Got error: " . ($l->error ? $l->error : '[undefined]');
            skip 'Got network error: ' . $l->error, 1;
        }
        else {
            BAIL_OUT 'Got weird error! ' . $l->error;
        }
    }

    like( $text, qr/^Lorem ipsum/,
        'The text we got matches Lipsum; when using overloading'
    );
}

###### Sometimes we'd get a Lorem ipsum start simply by chance
###### and this test would fail
###### This is really a bug in www.lipsum.com
###### So let's make a few requests, and see if ALL of them start
###### with Lorem Ipsum; only then fail.
{
    my $lipsum_count = 0;
    for ( 1..3 ) {
        $l->start(0);
        $l->html(0);
        my $text = "$l";
        if ( $text =~ /\[Error/ ) {
            if ( $l->error =~ /^Network/ ) {
                diag "Got error: " . ($l->error ? $l->error : '[undefined]');
                next;
            }
            else {
                BAIL_OUT 'Got weird error! ' . $l->error;
            }
        }

        if ( $text =~ /^Lorem ipsum/i ) {
            diag "Uhoh.. We got text starting with Lorem Ipsum, when we"
            . " shouldn't have. Maybe it's just a coincidence; retrying.";
            $lipsum_count++;
        }
    }

    ok( $lipsum_count <= 1, 'Out of three no-lipsum-at-start tests, 1 or fewer returned Lipsum as start');
}

SKIP: {
    $l->html(1);
    $l->what('lists');
    my $text = "$l";
    if ( $text =~ /^\[Error/ ) {
        if ( $l->error =~ /^Network/ ) {
            diag "Got error: " . ($l->error ? $l->error : '[undefined]');
            skip 'Got network error: ' . $l->error, 1;
        }
        else {
            BAIL_OUT 'Got weird error! ' . $l->error;
        }
    }

    like( $text, qr/^\s*<ul>/,
        'The text we got must have some semblance to <ul> markup'
    );
}

SKIP: {
    $l->html(1);
    $l->what('paras');
    my $text = "$l";
    if ( $text =~ /^\[Error/ ) {
        if ( $l->error =~ /^Network/ ) {
            diag "Got error: " . ($l->error ? $l->error : '[undefined]');
            skip 'Got network error: ' . $l->error, 1;
        }
        else {
            BAIL_OUT 'Got weird error! ' . $l->error;
        }
    }

    like( $text, qr/^\s*<p>/,
        'The text we got must have some semblance to <p> markup'
    );
}

done_testing();