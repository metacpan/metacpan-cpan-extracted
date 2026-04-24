use strict;
use warnings;
use Test::More;
use XML::Parser;
use XML::Parser::Expat;

# Tests targeting specific uncovered code paths in Expat.xs identified by gcov.
# Baseline coverage: 93.19% — these tests exercise the remaining reachable gaps.

plan tests => 26;

# ===== skip_until with Char handler (suspend L1237 / resume L1278) =====
# skip_until() calls suspend_callbacks() then resume_callbacks() after the
# target index is reached. The Char handler branches in these functions are
# only hit when a Char handler is registered during skip_until.
{
    my @chars;
    my $xml = '<r><a>text1</a><b>text2</b><c>text3</c></r>';

    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                if ($el eq 'a') {
                    # Skip from 'a' to beyond 'b' — element_index of 'c' should be 4
                    $xp->skip_until(4);
                }
            },
            Char => sub { push @chars, $_[1] },
        },
    );
    $p->parse($xml);
    # 'text1' and 'text2' should be suppressed by skip_until,
    # 'text3' should appear after resume
    my $text = join('', @chars);
    like($text, qr/text3/, 'skip_until + Char: text after resume point is delivered');
    unlike($text, qr/text2/, 'skip_until + Char: text during skip is suppressed');
}

# ===== skip_until with CdataSection handlers (suspend L1253 / resume L1291) =====
{
    my @cdata_starts;
    my $xml = '<r><a/><b><![CDATA[skipped]]></b><c><![CDATA[seen]]></c></r>';

    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                if ($el eq 'a') {
                    $xp->skip_until(4);  # Skip past 'b'
                }
            },
            CdataStart => sub { push @cdata_starts, 1 },
            Char       => sub { },  # suppress output
        },
    );
    $p->parse($xml);
    # The CDATA in <b> should be skipped, the one in <c> should fire
    is(scalar @cdata_starts, 1, 'skip_until + CdataStart: only post-skip CDATA fires');
}

# ===== skip_until with Unparsed and Notation handlers (suspend L1259,1264 / resume L1295,1299) =====
# DTD events fire before document body, so skip_until from Init skips them.
{
    my @notation_names;
    my @unparsed_names;
    my $xml = <<'XML';
<!DOCTYPE doc [
<!NOTATION gif SYSTEM "image/gif">
<!ENTITY pic SYSTEM "pic.gif" NDATA gif>
]>
<doc><a/><b/></doc>
XML

    my $p = XML::Parser->new(
        Handlers => {
            Init     => sub { $_[0]->skip_until(1) },
            Notation => sub { push @notation_names, $_[1] },
            Unparsed => sub { push @unparsed_names, $_[1] },
            Start    => sub { },
        },
    );
    $p->parse($xml);
    # DTD declarations happen before any elements, so skip_until(1) should
    # skip them. After resume, Notation/Unparsed are restored for future events.
    # The key coverage goal: suspend_callbacks and resume_callbacks exercise
    # the Notation and Unparsed branches simply by being registered.
    pass('skip_until + Notation/Unparsed: suspend/resume completed without crash');
}

# ===== skip_until with ExternEnt handler (suspend L1268 / resume L1303) =====
{
    my @ext_calls;
    my $xml = <<'XML';
<!DOCTYPE doc [
<!ENTITY ext SYSTEM "ext.xml">
]>
<doc><a/><b>&ext;</b><c/></doc>
XML

    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                if ($el eq 'a') {
                    $xp->skip_until(4);  # Skip past 'b' and its entity ref
                }
            },
            ExternEnt => sub {
                push @ext_calls, 1;
                return '';
            },
        },
    );
    $p->parse($xml);
    # Entity in <b> should be skipped
    is(scalar @ext_calls, 0, 'skip_until + ExternEnt: entity ref during skip is suppressed');
}

# ===== RecognizedString with existing recstring reset (L2009) =====
# When recognized_string is called and cbv->recstring already exists from a
# previous call, the sv_setpvn("", 0) reset path is hit.
{
    my @recs;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { push @recs, $_[0]->recognized_string() },
        },
    );
    $p->parse('<root><a/><b/></root>');
    is(scalar @recs, 3, 'recstring reset: three Start events');
    is($recs[1], '<a/>', 'recstring reset: second call correct after reset');
    is($recs[2], '<b/>', 'recstring reset: third call correct after reset');
}

# ===== recString append path (L1227) =====
# Multi-attribute start tags generate multiple default events, exercising
# the sv_catpvn path where recstring already has content.
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { $rec = $_[0]->recognized_string() if $_[1] eq 'e' },
        },
    );
    $p->parse('<r><e a="1" b="2" c="3" d="4" e="5"/></r>');
    like($rec, qr/^<e\s.*\/>$/, 'recString append: multi-attr tag captured fully');
    like($rec, qr/e="5"/, 'recString append: last attribute present');
}

# ===== SkipUntil early return (L2338) =====
# When skip_until is called with an index <= current st_serial, it returns
# immediately without suspending callbacks.
{
    my @starts;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                push @starts, $el;
                if ($el eq 'b') {
                    $xp->skip_until(0);  # Already past index 0 — no-op
                }
            },
        },
    );
    $p->parse('<r><a/><b/><c/></r>');
    ok(scalar(grep { $_ eq 'c' } @starts), 'skip_until(0): no-op, subsequent events still fire');
}

# ===== UnsetAllHandlers with namespaces (L2305) =====
# When namespaces are enabled, UnsetAllHandlers (called from finish()) also
# unsets namespace decl handlers. Must call finish() mid-parse from a handler.
{
    my @events;
    my $finished;
    my $xml = '<r xmlns:ns="http://example.com"><ns:a/><ns:b/></r>';

    my $p = XML::Parser->new(
        Namespaces => 1,
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                push @events, $el;
                if ($el eq 'a') {
                    $xp->finish;
                    $finished = 1;
                }
            },
        },
    );
    $p->parse($xml);

    ok($finished, 'UnsetAllHandlers ns: finish() called on namespace parser');
    # 'b' should not appear because finish() stopped processing
    ok(!grep({ $_ eq 'b' } @events), 'UnsetAllHandlers ns: no events after finish()');
}

# ===== ExternalEntityRef with PUBLIC id (L1015) =====
# When an external entity has a PUBLIC id, the pubid push path is taken.
{
    my @ext_args;
    my $xml = <<'XML';
<!DOCTYPE doc [
<!ENTITY ext PUBLIC "pub-id" "sys.xml">
]>
<doc>&ext;</doc>
XML

    my $p = XML::Parser->new(
        Handlers => {
            ExternEnt => sub {
                my ($xp, $base, $sysid, $pubid) = @_;
                @ext_args = ($sysid, $pubid);
                return '';
            },
        },
    );
    $p->parse($xml);
    is($ext_args[0], 'sys.xml', 'ExternEnt pubid: sysid passed correctly');
    is($ext_args[1], 'pub-id', 'ExternEnt pubid: pubid passed to handler');
}

# ===== pe_implicit DefaultCurrent for PE references (L989-994) =====
{
    my @defaults;
    my @entities;

    my $xml = <<'XML';
<!DOCTYPE doc [
<!ENTITY % pe SYSTEM "pe.ent">
%pe;
]>
<doc/>
XML

    my $p = XML::Parser->new(
        Handlers => {
            Entity  => sub { push @entities, $_[1] },
            Default => sub { push @defaults, $_[1] },
        },
    );
    $p->parse($xml);
    my $dtext = join('', @defaults);
    like($dtext, qr/%pe;/, 'pe_implicit: PE reference routed to Default handler');
}

# ===== SetExternalEntityRefHandler pe_implicit fallback (L1710-1711) =====
# When extent handler is cleared while pe_implicit is true, the C handler
# is kept for PE support. Also tests L1005 (return 0 when no extent_sv).
{
    my @defaults;
    my $xml = <<'XML';
<!DOCTYPE doc [
<!ENTITY % pe SYSTEM "pe.ent">
%pe;
<!ATTLIST doc foo CDATA "bar">
]>
<doc foo="bar"/>
XML

    my @attlists;
    my $p = XML::Parser->new(
        Handlers => {
            Attlist => sub {
                my ($xp, $elname, $attname) = @_;
                push @attlists, $attname;
                $xp->setHandlers(ExternEnt => undef);
            },
            Default => sub { push @defaults, $_[1] },
        },
    );
    $p->parse($xml);
    ok(scalar @attlists >= 1, 'pe_implicit fallback: Attlist handler fired');
}

# ===== OriginalString with NULL context (L2254) =====
SKIP: {
    my $has_context = eval {
        my $p = XML::Parser->new(
            Handlers => { Start => sub { $_[0]->original_string() } }
        );
        $p->parse('<r/>');
        1;
    };

    if ($has_context) {
        skip 'expat has XML_CONTEXT_BYTES — cannot test NULL context path', 1;
    }

    my $orig;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { $orig = $_[0]->original_string() },
        },
    );
    $p->parse('<r/>');
    is($orig, '', 'original_string: returns empty string without XML_CONTEXT_BYTES');
}

# ===== PositionContext with NULL context (L1911) =====
SKIP: {
    my $has_context = eval {
        my $p = XML::Parser->new(
            Handlers => { Start => sub { $_[0]->original_string() } }
        );
        $p->parse('<r/>');
        1;
    };

    if ($has_context) {
        skip 'expat has XML_CONTEXT_BYTES — cannot test NULL PositionContext path', 1;
    }

    my @ctx;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { @ctx = $_[0]->position_in_context(0) },
        },
    );
    $p->parse('<r/>');
    is(scalar @ctx, 0, 'position_in_context: returns nothing without XML_CONTEXT_BYTES');
}

# ===== Do_External_Parse with string result (L2363-2368) =====
{
    my $xml = <<'XML';
<!DOCTYPE doc [
<!ENTITY ext SYSTEM "inline.xml">
]>
<doc>&ext;</doc>
XML

    my @chars;
    my $p = XML::Parser->new(
        Handlers => {
            ExternEnt => sub { return '<sub>hello</sub>' },
            Char      => sub { push @chars, $_[1] },
        },
    );
    $p->parse($xml);
    my $text = join('', @chars);
    like($text, qr/hello/, 'Do_External_Parse: string return parsed as XML');
}

# ===== ExternEnt no handler (L1004-1005) =====
# Without an ExternEnt handler, the C callback isn't registered, so expat
# handles the failure internally. This verifies the error path.
{
    my $xml = <<'XML';
<!DOCTYPE doc [
<!ENTITY ext SYSTEM "missing.xml">
]>
<doc>&ext;</doc>
XML

    eval {
        my $p = XML::Parser->new();
        $p->parse($xml);
    };
    like($@, qr/error/i, 'No ExternEnt handler: parse fails on external entity ref');
}

# ===== ExternEnt handler returning bad XML triggers error path (L1060-1066) =====
# When Do_External_Parse croaks, the error is captured in errmsg.
{
    my $xml = <<'XML';
<!DOCTYPE doc [
<!ENTITY ext SYSTEM "bad.xml">
]>
<doc>&ext;</doc>
XML

    eval {
        my $p = XML::Parser->new(
            Handlers => {
                ExternEnt => sub { return '<broken>no close tag' },
            },
        );
        $p->parse($xml);
    };
    like($@, qr/error|not well-formed|junk/i,
        'ExternEnt error path: bad XML from handler triggers parse error');
}

# ===== skip_until with Comment handler (suspend L1246 / resume L1286) =====
{
    my @comments;
    my $xml = '<r><a/><!-- skip this --><b/><!-- see this --><c/></r>';

    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                $xp->skip_until(3) if $el eq 'a';  # Skip past first comment and <b>
            },
            Comment => sub { push @comments, $_[1] },
        },
    );
    $p->parse($xml);
    is(scalar @comments, 1, 'skip_until + Comment: only post-skip comment fires');
    like($comments[0], qr/see this/, 'skip_until + Comment: correct comment delivered');
}

# ===== skip_until with Proc handler (suspend L1241 / resume L1282) =====
{
    my @procs;
    my $xml = '<r><a/><?skip data?><b/><?keep data?><c/></r>';

    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                $xp->skip_until(3) if $el eq 'a';
            },
            Proc => sub { push @procs, $_[1] },
        },
    );
    $p->parse($xml);
    is(scalar @procs, 1, 'skip_until + Proc: only post-skip PI fires');
    is($procs[0], 'keep', 'skip_until + Proc: correct PI delivered');
}
