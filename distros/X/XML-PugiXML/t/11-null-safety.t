use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use XML::PugiXML;

# Test 1: Instantiation of empty/null handles must not segfault on DESTROY
for my $class (qw(XML::PugiXML XML::PugiXML::Node XML::PugiXML::Attr XML::PugiXML::XPath)) {
    my $fake = bless \do { my $x = 0 }, $class;
    undef $fake;
    pass("$class: NULL handle destroyed safely without segfault");
}

# Test 2: Double DESTROY must not cause double-free or heap corruption
{
    my $doc = XML::PugiXML->new;
    ok $doc->load_string('<r><a k="1"/></r>'), 'loaded document';
    my $node = $doc->root->child('a');
    my $attr = $node->attr('k');
    my $xp   = $doc->compile_xpath('//a');

    # Explicitly invoke DESTROY twice on each object
    eval { $doc->DESTROY; 1 };
    is $@, '', 'first doc DESTROY succeeds';
    eval { $doc->DESTROY; 1 };
    is $@, '', 'second doc DESTROY is a safe no-op';

    eval { $node->DESTROY; 1 };
    is $@, '', 'first node DESTROY succeeds';
    eval { $node->DESTROY; 1 };
    is $@, '', 'second node DESTROY is a safe no-op';

    eval { $attr->DESTROY; 1 };
    is $@, '', 'first attr DESTROY succeeds';
    eval { $attr->DESTROY; 1 };
    is $@, '', 'second attr DESTROY is a safe no-op';

    eval { $xp->DESTROY; 1 };
    is $@, '', 'first xpath DESTROY succeeds';
    eval { $xp->DESTROY; 1 };
    is $@, '', 'second xpath DESTROY is a safe no-op';
}

# Test 3: Calling valid() on null or destroyed handles must return false
{
    my $fake_node = bless \do { my $x = 0 }, 'XML::PugiXML::Node';
    ok !$fake_node->valid, 'null node valid() returns false';

    my $fake_attr = bless \do { my $x = 0 }, 'XML::PugiXML::Attr';
    ok !$fake_attr->valid, 'null attr valid() returns false';

    my $doc = XML::PugiXML->new;
    $doc->load_string('<r><a k="1"/></r>');
    my $node = $doc->root->child('a');
    my $attr = $node->attr('k');
    $node->DESTROY;
    $attr->DESTROY;

    ok !$node->valid, 'destroyed node valid() returns false';
    ok !$attr->valid, 'destroyed attr valid() returns false';
}

# Test 4: Methods called on destroyed or null objects croak cleanly
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<r><a k="1"/></r>');
    my $node = $doc->root->child('a');
    my $attr = $node->attr('k');
    my $xp   = $doc->compile_xpath('//a');

    $doc->DESTROY;
    $node->DESTROY;
    $attr->DESTROY;
    $xp->DESTROY;

    my @cases = (
        ['doc load_file'     => sub { $doc->load_file('foo.xml') }],
        ['doc load_string'   => sub { $doc->load_string('<x/>') }],
        ['doc reset'         => sub { $doc->reset }],
        ['doc save_file'     => sub { $doc->save_file('foo.xml') }],
        ['doc to_string'     => sub { $doc->to_string }],
        ['doc root'          => sub { $doc->root }],
        ['doc child'         => sub { $doc->child('a') }],
        ['doc select_node'   => sub { $doc->select_node('//a') }],
        ['doc select_nodes'  => sub { my @n = $doc->select_nodes('//a') }],
        ['doc compile_xpath' => sub { $doc->compile_xpath('//a') }],
        ['node name'         => sub { $node->name }],
        ['node text'         => sub { $node->text }],
        ['attr name'         => sub { $attr->name }],
        ['attr value'        => sub { $attr->value }],
        ['xp eval_node'      => sub { $xp->evaluate_node($node) }],
        ['xp eval_nodes'     => sub { my @n = $xp->evaluate_nodes($node) }],
        ['xp eval_string'    => sub { $xp->evaluate_string($node) }],
        ['xp eval_number'    => sub { $xp->evaluate_number($node) }],
        ['xp eval_boolean'   => sub { $xp->evaluate_boolean($node) }],
    );

    for my $case (@cases) {
        my ($label, $code) = @$case;
        ok !eval { $code->(); 1 }, "$label croaks on destroyed object";
        like $@, qr/(?:uninitialized or has been destroyed|reference is invalid)/,
            "$label gives uninitialized/destroyed diagnostic";
    }
}

done_testing;
