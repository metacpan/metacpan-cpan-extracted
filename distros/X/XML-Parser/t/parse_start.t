use strict;
use warnings;
use Test::More tests => 14;
use XML::Parser;

# Test the non-blocking (ExpatNB) parser API: parse_start, parse_more,
# parse_done.  The partial.t test covers basic incremental parsing;
# this file focuses on the Init/Final handler integration, return value
# propagation, and error paths.

my $xml = '<root><child attr="val">text</child></root>';

# --- Init handler is called by parse_start ---
{
    my $init_called = 0;
    my $p = XML::Parser->new(
        Handlers => {
            Init => sub { $init_called = 1 },
        },
    );
    my $nb = $p->parse_start;
    ok($init_called, 'Init handler called during parse_start');
    $nb->parse_more($xml);
    $nb->parse_done;
}

# --- Final handler return value in scalar context ---
{
    my $p = XML::Parser->new(
        Handlers => {
            Final => sub { return 'final_result' },
        },
    );
    my $nb = $p->parse_start;
    $nb->parse_more($xml);
    my $result = $nb->parse_done;
    is($result, 'final_result', 'parse_done returns Final handler result in scalar context');
}

# --- Final handler return value in list context ---
{
    my $p = XML::Parser->new(
        Handlers => {
            Final => sub { return ('a', 'b', 'c') },
        },
    );
    my $nb = $p->parse_start;
    $nb->parse_more($xml);
    my @result = $nb->parse_done;
    is_deeply(\@result, ['a', 'b', 'c'], 'parse_done returns Final handler list in list context');
}

# --- Without Final handler, parse_done returns 1 in scalar context ---
{
    my $p = XML::Parser->new;
    my $nb = $p->parse_start;
    $nb->parse_more($xml);
    my $result = $nb->parse_done;
    is($result, 1, 'parse_done returns 1 (success) without Final handler');
}

# --- Start/End/Char handlers work through parse_start ---
{
    my @events;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { push @events, "start:$_[1]" },
            End   => sub { push @events, "end:$_[1]" },
            Char  => sub { push @events, "char:$_[1]" },
        },
    );
    my $nb = $p->parse_start;
    $nb->parse_more($xml);
    $nb->parse_done;
    is_deeply(\@events,
        ['start:root', 'start:child', 'char:text', 'end:child', 'end:root'],
        'Start/End/Char handlers fire correctly via parse_more');
}

# --- Incremental feeding: split XML across multiple parse_more calls ---
{
    my @starts;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { push @starts, $_[1] },
        },
    );
    my $nb = $p->parse_start;
    $nb->parse_more('<root>');
    $nb->parse_more('<a/>');
    $nb->parse_more('<b/>');
    $nb->parse_more('</root>');
    $nb->parse_done;
    is_deeply(\@starts, ['root', 'a', 'b'],
        'incremental parse_more across multiple chunks works');
}

# --- parse_more with malformed XML dies ---
{
    my $p = XML::Parser->new;
    my $nb = $p->parse_start;
    eval { $nb->parse_more('<root><unclosed>') };
    is($@, '', 'incomplete XML in parse_more does not die (not yet final)');

    # Finalizing incomplete XML should die
    eval { $nb->parse_done };
    like($@, qr/./, 'parse_done on incomplete XML dies with error');
}

# --- parse_more with invalid XML dies immediately ---
{
    my $p = XML::Parser->new;
    my $nb = $p->parse_start;
    $nb->parse_more('<root>');
    eval { $nb->parse_more('</wrong>') };
    like($@, qr/./, 'mismatched end tag in parse_more dies');
}

# --- ExpatNB rejects parse/parsestring/parsefile ---
{
    my $p = XML::Parser->new;
    my $nb = $p->parse_start;
    eval { $nb->parse('<root/>') };
    like($@, qr/not supported/i, 'ExpatNB->parse() is rejected');

    eval { $nb->parsestring('<root/>') };
    like($@, qr/not supported/i, 'ExpatNB->parsestring() is rejected');

    eval { $nb->parsefile('/dev/null') };
    like($@, qr/not supported/i, 'ExpatNB->parsefile() is rejected');

    # Clean up the parse state
    $nb->parse_more('<root/>');
    $nb->parse_done;
}

# --- Final handler receives the expat object ---
{
    my $got_expat;
    my $p = XML::Parser->new(
        Handlers => {
            Final => sub { $got_expat = ref $_[0]; return 1 },
        },
    );
    my $nb = $p->parse_start;
    $nb->parse_more($xml);
    $nb->parse_done;
    is($got_expat, 'XML::Parser::ExpatNB',
        'Final handler receives ExpatNB object');
}

# --- parse_start passes extra options to Expat ---
{
    my $got_context;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                $got_context = $_[0]->{ErrorContext};
            },
        },
    );
    my $nb = $p->parse_start(ErrorContext => 5);
    $nb->parse_more('<root/>');
    $nb->parse_done;
    is($got_context, 5, 'parse_start passes extra options to Expat');
}
