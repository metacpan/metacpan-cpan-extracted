use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use XML::PugiXML;

# The handle registry: exactly the handles into a removed subtree must go
# stale, and nothing else. These cover the cases t/07 does not.

#--------------------------------------------------
# Several handles can name the same node
#--------------------------------------------------
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r><x/></r>');
    my $a = $d->root->child('x');
    my $b = $d->root->child('x');      # distinct wrapper, same node
    ok $a->valid && $b->valid, 'two handles to one node both start valid';
    $d->root->remove_child($a);
    ok !$a->valid, 'the handle passed to remove_child dies';
    ok !$b->valid, 'a second handle to the same node also dies';
}

#--------------------------------------------------
# Attribute handles obtained through XPath
#--------------------------------------------------
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r><e k="1"/></r>');
    my ($at) = $d->select_nodes('//@k');
    ok $at->valid, 'xpath-derived attribute handle is valid';
    $d->root->remove_child($d->root->child('e'));
    ok !$at->valid, 'xpath-derived attribute dies with its element';
}

#--------------------------------------------------
# Depth: a removal several levels up kills everything below
#--------------------------------------------------
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r><a><b><c><e><f k="1">text</f></e></c></b></a></r>');
    my $deep = $d->select_node('//f');
    my $at   = $deep->attr('k');
    $d->root->remove_child($d->root->child('a'));
    ok !$deep->valid, 'handle 5 levels down dies';
    ok !$at->valid,   'its attribute dies too';
}

#--------------------------------------------------
# Interleaving with generation bumps
#--------------------------------------------------
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r><a/><b/></r>');
    my $old = $d->root->child('a');
    $d->load_string('<r2><p/><q/></r2>');       # generation bump
    my $p = $d->root->child('p');
    ok eval { $d->root->remove_child($d->root->child('q')); 1 },
        'removal after a reload does not walk stale handles';
    ok !$old->valid, 'pre-reload handle stays stale';
    ok $p->valid,    'post-reload handle unaffected';
}
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r><a/></r>');
    my $a = $d->root->child('a');
    $d->root->remove_child($a);
    ok eval { $d->reset; 1 }, 'reset after a removal is safe';
    ok !$a->valid, 'removed-then-reset handle stays invalid';
}

#--------------------------------------------------
# A copy living inside the removed subtree
#--------------------------------------------------
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r><src><s/></src><dst/></r>');
    my $dst  = $d->root->child('dst');
    my $copy = $dst->append_copy($d->root->child('src'));
    ok $copy->valid, 'copy is valid';
    $d->root->remove_child($dst);
    ok !$copy->valid, 'copy inside the removed subtree dies';
    ok $d->root->child('src')->valid, 'the copy source survives';
}

#--------------------------------------------------
# Destroying a dead handle must not corrupt the index
#--------------------------------------------------
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r><a/><b/><c/></r>');
    my $a = $d->root->child('a');
    my $b = $d->root->child('b');
    $d->root->remove_child($a);
    undef $a;                                   # DESTROY an already-dead wrapper
    ok eval { $d->root->remove_child($b); 1 }, 'index intact after that';
    ok !$b->valid, 'later removal still works';
    is scalar(grep { $_->type == XML::PugiXML::NODE_ELEMENT() } $d->root->children),
        1, 'document has the expected remaining child';
}

#--------------------------------------------------
# A removal pugixml refuses must invalidate nothing
#--------------------------------------------------
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r><a><b/></a></r>');
    my $a = $d->root->child('a');
    my $b = $a->child('b');
    my $at;
    ok !$d->root->remove_child($b), 'remove_child(non-child) is false';
    ok $b->valid, 'refused removal leaves the node valid';
    is $b->name, 'b', 'and usable';

    $d->load_string('<r keep="1"/>');
    $at = $d->root->attr('keep');
    ok !$d->root->remove_attr('absent'), 'remove_attr(missing) is false';
    ok $at->valid, 'refused attribute removal invalidates nothing';
    is $at->value, '1', 'and the attribute is usable';
}

#--------------------------------------------------
# Index growth: more live handles than the initial bucket count
#--------------------------------------------------
{
    my $d = XML::PugiXML->new;
    $d->load_string('<r>' . ('<c k="v"/>' x 200) . '</r>');
    my @kids  = $d->root->children;             # forces the node index to grow
    my @attrs = map { $_->attrs } @kids;        # and the attribute index
    is scalar @kids,  200, 'held 200 node handles';
    is scalar @attrs, 200, 'held 200 attribute handles';
    $d->root->remove_child($kids[100]);
    ok !$kids[100]->valid,  'the removed one died';
    ok !$attrs[100]->valid, 'its attribute died';
    is scalar(grep { $_->valid } @kids),  199, 'exactly one node handle died';
    is scalar(grep { $_->valid } @attrs), 199, 'exactly one attribute handle died';
}

#--------------------------------------------------
# Bulk removal must not be quadratic in the number of retained handles.
# Timing-based, so opt-in: CPAN Testers runs on wildly varying and sometimes
# emulated hardware, where a wall-clock assertion is a flakiness source.
#--------------------------------------------------
SKIP: {
    skip 'set PUGIXML_TIMING_TESTS=1 to run the scaling check', 1
        unless $ENV{PUGIXML_TIMING_TESTS};
    require Time::HiRes;
    my @t;
    for my $n (1000, 4000) {
        my $d = XML::PugiXML->new;
        $d->load_string('<r>' . ('<c/>' x $n) . '</r>');
        my $root = $d->root;
        my @kids = $root->children;             # retained across every removal
        my $t0 = Time::HiRes::time();
        $root->remove_child($_) for @kids;
        push @t, Time::HiRes::time() - $t0;
    }
    # 4x the work: linear gives ~4, quadratic ~16. Allow a wide margin.
    my $ratio = $t[1] / ($t[0] || 1e-9);
    cmp_ok $ratio, '<', 9,
        sprintf('bulk removal scales linearly (4x work took %.1fx time)', $ratio);
}

done_testing;
