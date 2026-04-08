#!/usr/bin/perl

# Test the context-tracking API methods: context(), current_element(),
# in_element(), within_element(), and depth().  These are the primary
# tools for handler code to know where it is in the document tree.
#
# Key semantics verified:
#   - In a Start handler, the new element is NOT yet on the context stack.
#     context/depth reflect the ancestors only.
#   - In an End handler, the closing element has ALREADY been popped.
#   - In a Char handler, the enclosing element IS on the stack.

use strict;
use warnings;

use Test::More tests => 25;
use XML::Parser;

# --- Nested document for stack tracking ---
# Structure:  root > items > item > sub > leaf
#             root > items > item (second)

my $doc = <<'XML';
<?xml version="1.0"?>
<root>
  <items>
    <item>
      <sub>
        <leaf>deep</leaf>
      </sub>
    </item>
    <item>shallow</item>
  </items>
</root>
XML

# Capture context state at various points during parsing
my %at_leaf;
my %at_sub;
my %at_root_end;
my @root_context;
my $root_depth;
my $within_item_at_leaf;
my $within_root_at_leaf;
my $within_missing;
my $in_leaf_at_leaf_char;
my $in_item_at_leaf_char;

my $p = XML::Parser->new(
    Handlers => {
        Start => sub {
            my ($xp, $el) = @_;

            if ($el eq 'root') {
                @root_context = $xp->context;
                $root_depth   = $xp->depth;
            }
            elsif ($el eq 'sub') {
                $at_sub{depth}           = $xp->depth;
                $at_sub{current_element} = $xp->current_element;
                # In Start handler, current_element is the parent (top of stack)
                $at_sub{in_item}         = $xp->in_element('item');
                $at_sub{in_sub}          = $xp->in_element('sub');
            }
            elsif ($el eq 'leaf') {
                $at_leaf{depth}           = $xp->depth;
                $at_leaf{current_element} = $xp->current_element;
                my @ctx = $xp->context;
                $at_leaf{context}         = \@ctx;
                $within_item_at_leaf      = $xp->within_element('item');
                $within_root_at_leaf      = $xp->within_element('root');
                $within_missing           = $xp->within_element('nonexistent');
            }
        },
        Char => sub {
            my ($xp, $str) = @_;
            if ($str eq 'deep') {
                $in_leaf_at_leaf_char = $xp->in_element('leaf');
                $in_item_at_leaf_char = $xp->in_element('item');
            }
        },
        End => sub {
            my ($xp, $el) = @_;
            if ($el eq 'root') {
                $at_root_end{depth}           = $xp->depth;
                $at_root_end{current_element} = $xp->current_element;
            }
        },
    }
);
$p->parse($doc);

# --- depth() ---
# In Start handler, the new element is not yet pushed.

is($root_depth, 0, 'depth is 0 at root Start (empty stack)');

# Path to <sub>: root > items > item > sub.  Stack = [root, items, item]
is($at_sub{depth}, 3, 'depth is 3 at <sub> Start (root, items, item on stack)');

# Path to <leaf>: root > items > item > sub > leaf.  Stack = [root, items, item, sub]
is($at_leaf{depth}, 4, 'depth is 4 at <leaf> Start (root, items, item, sub on stack)');

# --- context() ---

is_deeply(\@root_context, [], 'context is empty at root Start');

is($at_leaf{context}[0], 'root',  'context[0] is root at <leaf>');
is($at_leaf{context}[1], 'items', 'context[1] is items at <leaf>');
is($at_leaf{context}[2], 'item',  'context[2] is item at <leaf>');
is($at_leaf{context}[3], 'sub',   'context[3] is sub at <leaf>');
is(scalar @{$at_leaf{context}}, 4, 'context has 4 ancestors at <leaf>');

# --- current_element() ---
# Returns the top of the context stack (innermost ancestor in Start, self in Char/End).

is($at_leaf{current_element}, 'sub',
    'current_element at <leaf> Start is parent (sub)');
is($at_sub{current_element}, 'item',
    'current_element at <sub> Start is parent (item)');

# In End handler, the closing element has been popped already.
is($at_root_end{depth}, 0,
    'depth at </root> End is 0 (root already popped)');
is($at_root_end{current_element}, undef,
    'current_element at </root> End is undef (stack empty after pop)');

# --- in_element() ---
# Checks whether the top of the context stack matches the given name.

ok($at_sub{in_item}, 'in_element(item) is true at <sub> Start (item is top of stack)');
ok(!$at_sub{in_sub}, 'in_element(sub) is false at <sub> Start (sub not yet on stack)');
ok($in_leaf_at_leaf_char, 'in_element(leaf) is true inside Char handler under <leaf>');
ok(!$in_item_at_leaf_char, 'in_element(item) is false inside Char handler under <leaf>');

# --- within_element() ---
# Counts occurrences of an element name anywhere in the context stack.

is($within_item_at_leaf, 1,
    'within_element(item) is 1 at <leaf> (one item ancestor)');
is($within_root_at_leaf, 1,
    'within_element(root) is 1 at <leaf> (one root ancestor)');
is($within_missing, 0,
    'within_element(nonexistent) is 0');

# --- within_element with repeated ancestors ---
# Same element name at multiple nesting levels.

my $nested_doc = <<'XML';
<div>
  <div>
    <div>
      <span>target</span>
    </div>
  </div>
</div>
XML

my $within_div_at_span;
my $within_span_at_span;
my $depth_at_span;

my $p2 = XML::Parser->new(
    Handlers => {
        Start => sub {
            my ($xp, $el) = @_;
            if ($el eq 'span') {
                $within_div_at_span  = $xp->within_element('div');
                $within_span_at_span = $xp->within_element('span');
                $depth_at_span       = $xp->depth;
            }
        },
    }
);
$p2->parse($nested_doc);

is($within_div_at_span, 3,
    'within_element(div) counts all 3 div ancestors');
is($within_span_at_span, 0,
    'within_element(span) is 0 at <span> Start (self not on stack yet)');
is($depth_at_span, 3,
    'depth is 3 at <span> (3 divs on stack)');

# --- depth at End handler ---
# At End, the element has already been popped from the context stack.

my $depth_at_inner_div_end;
my $ctx_len_at_inner_div_end;

my $p3 = XML::Parser->new(
    Handlers => {
        End => sub {
            my ($xp, $el) = @_;
            # Capture only the innermost div's End
            if ($el eq 'div' && !defined $depth_at_inner_div_end) {
                $depth_at_inner_div_end   = $xp->depth;
                $ctx_len_at_inner_div_end = scalar($xp->context);
            }
        },
    }
);
$p3->parse($nested_doc);

is($depth_at_inner_div_end, 2,
    'depth at innermost </div> End is 2 (element already popped)');
is($ctx_len_at_inner_div_end, 2,
    'context length at innermost </div> End is 2 (element already popped)');
