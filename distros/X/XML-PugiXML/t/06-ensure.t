use strict;
use warnings;
use Test::More;
use XML::PugiXML;

# ensure_child / ensure_attr: get-or-create helpers (pugixml >= 1.16).
# Unlike append_child / append_attr they never duplicate an existing name.

# ensure_child returns an existing child without duplicating it
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/></root>') or die $@;
    my $root = $doc->root;

    my $a = $root->ensure_child('a');
    ok defined $a, 'ensure_child returns a node for an existing child';
    is $a->name, 'a', 'ensure_child returned the existing <a>';
    is scalar(grep { $_->name eq 'a' } $root->children), 1,
        'ensure_child did not duplicate the existing child';
}

# ensure_child creates a missing child and returns it
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>') or die $@;
    my $root = $doc->root;

    my $b = $root->ensure_child('b');
    ok defined $b, 'ensure_child returns a node for a created child';
    is $b->name, 'b', 'ensure_child created <b>';
    is scalar(grep { $_->name eq 'b' } $root->children), 1, 'exactly one <b> child exists';
    like $doc->to_string, qr{<b\s*/>}, 'created child is serialized into the document';
}

# ensure_attr creates a missing attribute, then returns the same one
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>') or die $@;
    my $root = $doc->root;

    my $attr = $root->ensure_attr('id');
    ok defined $attr, 'ensure_attr returns an attribute for a created attr';
    is $attr->name, 'id', 'ensure_attr created the id attribute';
    $attr->set_value('42');

    my $again = $root->ensure_attr('id');
    is $again->value, '42', 'ensure_attr returned the existing attribute (value preserved)';
    like $doc->to_string, qr{id="42"}, 'ensure_attr value is serialized into the document';
    my @attrs = $root->attrs;   # attrs() is list-returning; count via an array
    is scalar(@attrs), 1, 'ensure_attr did not duplicate the attribute';
}

done_testing;
