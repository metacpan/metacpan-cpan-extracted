use strict;
use warnings;
use Test::More;
use XML::Parser;

# Test recognized_string(), original_string(), and default_current() —
# the string introspection methods available inside handlers.

plan tests => 24;

# ===== recognized_string() in Start handler =====
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { $rec = $_[0]->recognized_string() },
        }
    );
    $p->parse('<root attr="val"/>');
    is($rec, '<root attr="val"/>', 'recognized_string: start tag with attribute');
}

{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { $rec = $_[0]->recognized_string() if $_[1] eq 'child' },
        }
    );
    $p->parse('<root><child/></root>');
    is($rec, '<child/>', 'recognized_string: nested empty element');
}

# ===== recognized_string() in End handler =====
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            End => sub { $rec = $_[0]->recognized_string() if $_[1] eq 'item' },
        }
    );
    $p->parse('<root><item>text</item></root>');
    is($rec, '</item>', 'recognized_string: end tag');
}

# ===== recognized_string() in Char handler =====
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            Char => sub { $rec = $_[0]->recognized_string() },
        }
    );
    $p->parse('<r>hello</r>');
    is($rec, 'hello', 'recognized_string: character data');
}

# ===== recognized_string() in Comment handler =====
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            Comment => sub { $rec = $_[0]->recognized_string() },
        }
    );
    $p->parse('<r><!-- a comment --></r>');
    is($rec, '<!-- a comment -->', 'recognized_string: comment');
}

# ===== recognized_string() in Proc handler =====
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            Proc => sub { $rec = $_[0]->recognized_string() },
        }
    );
    $p->parse('<r><?mypi data?></r>');
    is($rec, '<?mypi data?>', 'recognized_string: processing instruction');
}

# ===== recognized_string() with predefined entity =====
# recognized_string returns the XML markup that triggered the event.
# For predefined entities like &amp;, the Char handler receives '&',
# but recognized_string returns the original markup '&amp;'.
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            Char => sub { $rec = $_[0]->recognized_string() },
        }
    );
    $p->parse('<r>&amp;</r>');
    is($rec, '&amp;', 'recognized_string: returns markup form of entity');
}

# ===== recognized_string() with NoExpand =====
# When NoExpand is set, recognized_string preserves entity references
{
    my $rec;
    my $p = XML::Parser->new(
        NoExpand => 1,
        Handlers => {
            Default => sub { $rec = $_[0]->recognized_string() if $_[1] =~ /&amp;/ },
        }
    );
    $p->parse('<r>&amp;</r>');
    is($rec, '&amp;', 'recognized_string: NoExpand preserves entity reference');
}

# ===== recognized_string() preserves attribute order =====
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { $rec = $_[0]->recognized_string() if $_[1] eq 'e' },
        }
    );
    $p->parse('<r><e a="1" b="2" c="3"/></r>');
    like($rec, qr/^<e\s/, 'recognized_string: multi-attr tag starts correctly');
    like($rec, qr{/>$}, 'recognized_string: multi-attr tag ends correctly');
    like($rec, qr/a="1"/, 'recognized_string: contains first attribute');
    like($rec, qr/c="3"/, 'recognized_string: contains last attribute');
}

# ===== original_string() returns raw bytes =====
SKIP: {
    # original_string requires XML_CONTEXT_BYTES (XML_GetInputContext)
    my $has_context = eval {
        my $p = XML::Parser->new(
            Handlers => { Start => sub { $_[0]->original_string() } }
        );
        $p->parse('<r/>');
        1;
    };
    skip 'expat compiled without XML_CONTEXT_BYTES', 3 unless $has_context;

    my $orig;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { $orig = $_[0]->original_string() if $_[1] eq 'root' },
        }
    );
    $p->parse('<root foo="bar"/>');
    is($orig, '<root foo="bar"/>', 'original_string: start tag');

    $orig = undef;
    $p = XML::Parser->new(
        Handlers => {
            Char => sub { $orig = $_[0]->original_string() },
        }
    );
    $p->parse('<r>&amp;</r>');
    is($orig, '&amp;', 'original_string: entity not expanded');

    $orig = undef;
    $p = XML::Parser->new(
        Handlers => {
            Comment => sub { $orig = $_[0]->original_string() },
        }
    );
    $p->parse('<r><!-- test --></r>');
    is($orig, '<!-- test -->', 'original_string: comment');
}

# ===== default_current() passes event to Default handler =====
{
    my @defaults;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                $xp->default_current if $el eq 'passthru';
            },
            Default => sub {
                my ($xp, $str) = @_;
                push @defaults, $str;
            },
        }
    );
    $p->parse('<root><passthru/><keep/></root>');
    # default_current on <passthru/> should send its markup to the Default handler
    my $joined = join('', @defaults);
    like($joined, qr/<passthru/, 'default_current: start tag forwarded to Default handler');
}

# ===== default_current() does not forward when not called =====
{
    my @defaults;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                # don't call default_current — event should NOT reach Default
            },
            Default => sub {
                my ($xp, $str) = @_;
                push @defaults, $str if $str =~ /<child/;
            },
        }
    );
    $p->parse('<root><child/></root>');
    is(scalar @defaults, 0, 'default_current: start tag not forwarded when not called');
}

# ===== default_current() in End handler =====
{
    my @defaults;
    my $p = XML::Parser->new(
        Handlers => {
            End => sub {
                my ($xp, $el) = @_;
                $xp->default_current if $el eq 'relay';
            },
            Default => sub {
                my ($xp, $str) = @_;
                push @defaults, $str;
            },
        }
    );
    $p->parse('<root><relay>text</relay></root>');
    my $joined = join('', @defaults);
    like($joined, qr{</relay>}, 'default_current: end tag forwarded to Default handler');
}

# ===== recognized_string() outside parse returns falsy =====
{
    my $p = XML::Parser::Expat->new;
    my $result = $p->recognized_string;
    ok(!$result, 'recognized_string: returns falsy outside active parse');
    $p->release;
}

# ===== recognized_string() with CDATA section =====
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            CdataStart => sub { $rec = $_[0]->recognized_string() },
        }
    );
    $p->parse('<r><![CDATA[some data]]></r>');
    is($rec, '<![CDATA[', 'recognized_string: CDATA start marker');
}

{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            CdataEnd => sub { $rec = $_[0]->recognized_string() },
        }
    );
    $p->parse('<r><![CDATA[some data]]></r>');
    is($rec, ']]>', 'recognized_string: CDATA end marker');
}

# ===== recognized_string() with XMLDecl =====
{
    my $rec;
    my $p = XML::Parser->new(
        Handlers => {
            XMLDecl => sub { $rec = $_[0]->recognized_string() },
        }
    );
    $p->parse(qq{<?xml version="1.0" encoding="UTF-8"?>\n<r/>});
    is($rec, '<?xml version="1.0" encoding="UTF-8"?>',
       'recognized_string: XML declaration');
}

# ===== original_string() vs recognized_string() for entities =====
SKIP: {
    my $has_context = eval {
        my $p = XML::Parser->new(
            Handlers => { Start => sub { $_[0]->original_string() } }
        );
        $p->parse('<r/>');
        1;
    };
    skip 'expat compiled without XML_CONTEXT_BYTES', 2 unless $has_context;

    my ($orig, $rec);
    my $p = XML::Parser->new(
        Handlers => {
            Char => sub {
                $orig = $_[0]->original_string();
                $rec  = $_[0]->recognized_string();
            },
        }
    );
    $p->parse('<r>&lt;</r>');
    is($orig, '&lt;', 'original_string: preserves entity reference');
    is($rec,  '&lt;', 'recognized_string: also preserves predefined entity markup');
}
