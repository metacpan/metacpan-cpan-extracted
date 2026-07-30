use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use XML::PugiXML;

# Regression tests for two use-after-free classes fixed in 0.08.
#
# 1. $doc->select_nodes is a PPCODE XSUB, where xsubpp emits "SP -= items"
#    before the body: the first PUSHs overwrites the ST(0) slot. Reading ST(0)
#    inside the push loop handed every result after the first the *previous
#    result's* RV in place of the document, so those handles carried a bogus
#    document pointer.
# 2. pugixml's remove_child/remove_attribute free the storage they unlink
#    (a fully-freed non-top page goes back to the system), so handles into a
#    removed subtree dangled while valid() still reported them usable.

#--------------------------------------------------
# 1. select_nodes results must all belong to the real document
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<r><a/><b/><c/></r>');

    my @n = $doc->select_nodes('/r/*');
    is scalar @n, 3, 'select_nodes returned 3 nodes';
    is join(',', map { $_->name } @n), 'a,b,c', 'names correct';

    # ->root goes through the owning document; with a bogus owner this
    # dereferenced a Node as if it were a PugiDoc and segfaulted.
    is $_->root->name, 'r', 'root() from every result reaches the document'
        for @n;

    # A same-document argument must not be rejected. The stale owner pointer
    # used to make results 2..N look like they lived in another document.
    my $ok = eval { $doc->root->insert_child_before('z', $n[1]); 1 };
    ok $ok, 'same-document result accepted as an insertion anchor'
        or diag "croaked: $@";
}

# Reloading the document must invalidate *every* handle, not just the first
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<r><a/><b/><c/></r>');
    my @n = $doc->select_nodes('/r/*');

    $doc->load_string('<r2><x/></r2>');

    is join(',', map { $_->valid ? 1 : 0 } @n), '0,0,0',
        'all select_nodes results go stale after reload';

    for my $i (0 .. $#n) {
        ok !eval { $n[$i]->name; 1 }, "n[$i]->name croaks after reload";
        like $@, qr/Stale node handle/, "n[$i] reports a stale handle";
    }
}

# The same must hold for attribute results
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<r><i k="1"/><i k="2"/><i k="3"/></r>');
    my @a = $doc->select_nodes('//@k');
    is scalar @a, 3, 'select_nodes returned 3 attributes';
    is join(',', map { $_->value } @a), '1,2,3', 'attribute values correct';
    is $_->element->name, 'i', 'element() works from every attribute result'
        for @a;

    $doc->load_string('<r2/>');
    is join(',', map { $_->valid ? 1 : 0 } @a), '0,0,0',
        'all attribute results go stale after reload';
}

#--------------------------------------------------
# 2. remove_child invalidates the removed subtree only
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<r><keep/><victim><kid a="1">text</kid></victim></r>');
    my $root   = $doc->root;
    my $keep   = $root->child('keep');
    my $victim = $root->child('victim');
    my $kid    = $victim->child('kid');
    my $attr   = $kid->attr('a');

    ok $victim->valid && $kid->valid && $attr->valid, 'handles start valid';

    ok $root->remove_child($victim), 'remove_child returns true';

    ok !$victim->valid, 'removed node is invalid';
    ok !$kid->valid,    'descendant of removed node is invalid';
    ok !$attr->valid,   'attribute of a removed descendant is invalid';

    like +(eval { $victim->name; 1 } ? '' : $@), qr/removed from the document/,
        'using a removed node croaks';
    like +(eval { $kid->text; 1 } ? '' : $@), qr/removed from the document/,
        'using a removed descendant croaks';
    like +(eval { $attr->value; 1 } ? '' : $@), qr/removed from its element/,
        'using an attribute of a removed node croaks';

    # Untouched parts of the document must be unaffected.
    ok $root->valid, 'parent still valid after removing a child';
    ok $keep->valid, 'unrelated sibling still valid';
    is $keep->name, 'keep', 'unrelated sibling still usable';
    is scalar(grep { $_->type == XML::PugiXML::NODE_ELEMENT() } $root->children),
        1, 'document really lost the subtree';
}

# A removal that fails must not invalidate anything
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<r><a><b/></a></r>');
    my $a = $doc->root->child('a');
    my $b = $a->child('b');

    ok !$doc->root->remove_child($b), 'remove_child(non-child) returns false';
    ok $b->valid, 'failed removal leaves the node valid';
    is $b->name, 'b', 'failed removal leaves the node usable';
}

#--------------------------------------------------
# remove_attr invalidates just that attribute
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<r victim="1" keep="2"/>');
    my $root   = $doc->root;
    my $victim = $root->attr('victim');
    my $keep   = $root->attr('keep');

    ok $root->remove_attr('victim'), 'remove_attr returns true';

    ok !$victim->valid, 'removed attribute handle is invalid';
    like +(eval { $victim->value; 1 } ? '' : $@), qr/removed from its element/,
        'using a removed attribute croaks';

    ok $keep->valid, 'sibling attribute still valid';
    is $keep->value, '2', 'sibling attribute still usable';
    ok $root->valid, 'element still valid';
}

{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<r keep="1"/>');
    my $keep = $doc->root->attr('keep');
    ok !$doc->root->remove_attr('absent'), 'remove_attr(missing) returns false';
    ok $keep->valid, 'failed remove_attr invalidates nothing';
}

# Page-spanning removal: this is the shape that made the dangling pointer a
# real heap use-after-free, because pugixml returns whole 32KB pages to the
# system once they are fully freed and no longer the allocator's top page.
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><big/></root>');
    my $big = $doc->root->child('big');
    $big->append_child("x$_")->set_text('PAYLOAD-TO-FILL-WHOLE-PAGES-XXXXXXXX')
        for 1 .. 4000;
    my $deep = $big->child('x2000');

    # allocate after the subtree, so its pages are no longer the top page
    my $after = $doc->root->append_child('after');
    $after->append_child("a$_") for 1 .. 500;

    $doc->root->remove_child($big);
    ok !$deep->valid, 'deep handle in a page-spanning removal is invalid';
    ok !eval { $deep->name; 1 }, 'and croaks instead of reading freed memory';

    # recycle the freed pages; the handle must stay dead, not resurrect as
    # some unrelated node that happens to land on the same address
    $doc->root->append_child("fill$_")->set_text('RECYCLE-THE-FREED-PAGES-XX')
        for 1 .. 4000;
    ok !$deep->valid, 'handle stays invalid after the memory is reused';
}

done_testing;
