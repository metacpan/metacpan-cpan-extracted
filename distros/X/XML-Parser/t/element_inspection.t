use strict;
use warnings;
use Test::More;

use XML::Parser;

# ===================================================================
# element_index: depth-first visit order
# ===================================================================

{
    my @indices;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp) = @_;
                push @indices, $xp->element_index;
            },
        },
    );

    $p->parse('<root><a/><b><c/></b><d/></root>');

    # depth-first order: root=1, a=2, b=3, c=4, d=5
    is_deeply(\@indices, [1, 2, 3, 4, 5],
        'element_index assigns depth-first visit order');
}

# element_index is 0 outside the root element
{
    my $pre_index;
    my $p = XML::Parser->new(
        Handlers => {
            XMLDecl => sub {
                my ($xp) = @_;
                $pre_index = $xp->element_index;
            },
        },
    );

    $p->parse('<?xml version="1.0"?><root/>');
    is($pre_index, 0, 'element_index is 0 before root element');
}

# element_index is consistent between Start and End for same element
{
    my %start_idx;
    my @end_idx;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                $start_idx{$el} = $xp->element_index;
            },
            End => sub {
                my ($xp, $el) = @_;
                push @end_idx, [$el, $xp->element_index];
            },
        },
    );

    $p->parse('<root><a/><b><c/></b></root>');

    for my $pair (@end_idx) {
        my ($el, $idx) = @$pair;
        is($idx, $start_idx{$el},
            "element_index for <$el> matches in Start and End handlers");
    }
}

# element_index increments across siblings and nested elements
{
    my $prev = 0;
    my $monotonic = 1;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp) = @_;
                my $idx = $xp->element_index;
                $monotonic = 0 if $idx <= $prev;
                $prev = $idx;
            },
        },
    );

    $p->parse('<r><a><a1/><a2/></a><b><b1/></b><c/></r>');
    ok($monotonic, 'element_index is strictly increasing in document order');
}

# ===================================================================
# position_in_context: parse position display
# ===================================================================

{
    my $ctx;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                if ($el eq 'target') {
                    $ctx = $xp->position_in_context(0);
                }
            },
        },
    );

    $p->parse("<root><target/></root>");

    ok(defined $ctx, 'position_in_context returns a string');
    like($ctx, qr/\^/, 'position_in_context contains caret marker');
    like($ctx, qr/target/, 'position_in_context shows element name');
}

# position_in_context with surrounding lines
{
    my $ctx;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                if ($el eq 'b') {
                    $ctx = $xp->position_in_context(2);
                }
            },
        },
    );

    $p->parse("<root>\n<a/>\n<b/>\n<c/>\n</root>");

    ok(defined $ctx, 'position_in_context with lines=2 returns a string');
    # Should contain surrounding lines
    like($ctx, qr/<b/, 'position_in_context includes target line');
}

# position_in_context returns empty string outside parsing
{
    my $p = XML::Parser::Expat->new;
    my $ctx = $p->position_in_context(1);
    # _State_ is not 1 outside parsing, so returns undef
    ok(!defined($ctx) || $ctx eq '',
        'position_in_context returns undef/empty outside active parsing');
    $p->release;
}

# ===================================================================
# specified_attr: count of non-defaulted attributes
# ===================================================================

# All attributes are explicit (no DTD defaults)
{
    my $spec_count;
    my $attr_count;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el, %attrs) = @_;
                if ($el eq 'item') {
                    $spec_count = $xp->specified_attr;
                    # Each attr is name+value pair; specified_attr returns
                    # count of items in the raw list (pairs * 2)
                    $attr_count = scalar(keys %attrs) * 2;
                }
            },
        },
    );

    $p->parse('<root><item x="1" y="2" z="3"/></root>');
    is($spec_count, $attr_count,
        'specified_attr equals total attr count when no defaults');
}

# No attributes at all
{
    my $spec_count;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el) = @_;
                if ($el eq 'empty') {
                    $spec_count = $xp->specified_attr;
                }
            },
        },
    );

    $p->parse('<root><empty/></root>');
    is($spec_count, 0, 'specified_attr is 0 for element with no attributes');
}

# With DTD-defaulted attributes
{
    my $spec_count;
    my $total_attrs;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub {
                my ($xp, $el, %attrs) = @_;
                if ($el eq 'item') {
                    $spec_count = $xp->specified_attr;
                    $total_attrs = scalar(keys %attrs) * 2;
                }
            },
        },
    );

    my $xml = <<'XML';
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ELEMENT root (item*)>
  <!ELEMENT item EMPTY>
  <!ATTLIST item
    color CDATA "red"
    size  CDATA #REQUIRED>
]>
<root><item size="large"/></root>
XML

    $p->parse($xml);

    # size is explicitly specified (1 attr = 2 items in list)
    is($spec_count, 2, 'specified_attr counts only explicitly specified attrs');
    # total includes defaulted color
    is($total_attrs, 4, 'total attr list includes defaulted attributes');
    ok($spec_count < $total_attrs,
        'specified_attr < total when defaults are present');
}

# ===================================================================
# setHandlers: return value and handler replacement
# ===================================================================

# setHandlers returns old handler pairs
{
    my $orig_start = sub { };
    my $p = XML::Parser::Expat->new;
    $p->setHandlers(Start => $orig_start);

    my $new_start = sub { };
    my @old = $p->setHandlers(Start => $new_start);

    is(scalar @old, 2, 'setHandlers returns a pair (type, old_handler)');
    is($old[0], 'Start', 'returned pair has correct handler type');
    is($old[1], $orig_start, 'returned pair has original handler ref');

    $p->release;
}

# setHandlers returns undef for previously unset handler
{
    my $p = XML::Parser::Expat->new;
    my @old = $p->setHandlers(Char => sub { });

    is($old[0], 'Char', 'type name returned for first-time handler');
    ok(!defined($old[1]) || !$old[1],
        'old handler is undef/false when none was previously set');

    $p->release;
}

# setHandlers can clear a handler by passing undef
{
    my @chars;
    my $p = XML::Parser::Expat->new;
    $p->setHandlers(Char => sub { push @chars, $_[1] });

    # Now clear it
    my @old = $p->setHandlers(Char => undef);
    ok(ref $old[1] eq 'CODE', 'clearing returns previous CODE ref');

    $p->release;
}

# setHandlers with multiple pairs
{
    my $p = XML::Parser::Expat->new;
    my @old = $p->setHandlers(
        Start => sub { 'start' },
        End   => sub { 'end' },
        Char  => sub { 'char' },
    );

    is(scalar @old, 6, 'setHandlers returns pairs for all handlers set');
    is($old[0], 'Start', 'first returned type');
    is($old[2], 'End',   'second returned type');
    is($old[4], 'Char',  'third returned type');

    $p->release;
}

# setHandlers croaks on unknown handler type
{
    my $p = XML::Parser::Expat->new;
    eval { $p->setHandlers(Bogus => sub { }) };
    like($@, qr/Unknown Expat handler type/, 'setHandlers croaks on unknown type');
    $p->release;
}

# setHandlers croaks on odd number of arguments
{
    my $p = XML::Parser::Expat->new;
    eval { $p->setHandlers('Start') };
    like($@, qr/Uneven number/, 'setHandlers croaks on odd argument count');
    $p->release;
}

done_testing;
