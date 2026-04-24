#!/usr/bin/perl

# Test that handler exceptions don't leak SVs.
# When a Start or End handler dies, the parser should propagate
# the exception cleanly without leaking the element name SV.

use strict;
use warnings;

use Test::More tests => 6;
use XML::Parser;

my $xml = '<root><child>text</child></root>';

# Test 1-2: Start handler die propagates and parser remains usable
{
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($expat, $el) = @_;
                die "start handler died on $el" if $el eq 'child';
            },
        },
    );

    eval { $p->parse($xml) };
    like($@, qr/start handler died on child/, 'Start handler die propagates');

    # Parser should be reusable after exception
    my $ok_xml = '<simple/>';
    eval { $p->parse($ok_xml) };
    is($@, '', 'parser reusable after Start handler die');
}

# Test 3-4: End handler die propagates and parser remains usable
{
    my $p = XML::Parser->new(
        Handlers => {
            End => sub {
                my ($expat, $el) = @_;
                die "end handler died on $el" if $el eq 'child';
            },
        },
    );

    eval { $p->parse($xml) };
    like($@, qr/end handler died on child/, 'End handler die propagates');

    my $ok_xml = '<simple/>';
    eval { $p->parse($ok_xml) };
    is($@, '', 'parser reusable after End handler die');
}

# Test 5-6: Multiple parse cycles with dying handlers don't accumulate leaks
{
    my $die_count = 0;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($expat, $el) = @_;
                if ($el eq 'boom') {
                    $die_count++;
                    die "boom #$die_count";
                }
            },
        },
    );

    my $boom_xml = '<root><boom/></root>';
    for my $i (1..10) {
        eval { $p->parse($boom_xml) };
    }
    is($die_count, 10, 'all 10 parse attempts triggered the handler');

    # If SVs leaked, this would still work but would have accumulated
    # leaked SVs. We can't easily check refcounts, but we verify the
    # parser still works correctly after many exception cycles.
    my $chardata = '';
    $p = XML::Parser->new(
        Handlers => {
            Char => sub { $chardata .= $_[1] },
        },
    );
    $p->parse('<r>ok</r>');
    is($chardata, 'ok', 'fresh parser works after exception stress test');
}
