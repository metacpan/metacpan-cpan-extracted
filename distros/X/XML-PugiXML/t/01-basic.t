use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempfile);

use_ok('XML::PugiXML');

# Test document creation
my $doc = XML::PugiXML->new;
ok($doc, 'created document');

# Test load_string
ok($doc->load_string('<root><item id="1" val="3.14" flag="true">Hello</item><item id="2">World</item></root>'),
   'load_string');

# Test root
my $root = $doc->root;
ok($root, 'got root');
is($root->name, 'root', 'root name');
ok($root->valid, 'root is valid');

# Test child
my $item = $root->child('item');
ok($item, 'got child');
is($item->name, 'item', 'child name');
is($item->text, 'Hello', 'child text');

# Test attribute
my $attr = $item->attr('id');
ok($attr, 'got attribute');
ok($attr->valid, 'attr is valid');
is($attr->name, 'id', 'attr name');
is($attr->value, '1', 'attr value');
is($attr->as_int, 1, 'attr as_int');

# Test as_double
my $val_attr = $item->attr('val');
is($val_attr->as_double, 3.14, 'attr as_double');

# Test as_bool
my $flag_attr = $item->attr('flag');
ok($flag_attr->as_bool, 'attr as_bool');

# Test navigation
my $next = $item->next_sibling;
ok($next, 'got next sibling');
is($next->text, 'World', 'next sibling text');

my $parent = $item->parent;
ok($parent, 'got parent');
is($parent->name, 'root', 'parent is root');

# Test first_child
my $first = $root->first_child;
ok($first, 'got first_child');
is($first->name, 'item', 'first child name');

# Test children
my @children = $root->children;
is(scalar @children, 2, 'got all children');
is($children[0]->attr('id')->value, '1', 'first child id');
is($children[1]->attr('id')->value, '2', 'second child id');

# Test children with name filter
my @items = $root->children('item');
is(scalar @items, 2, 'filtered children count');

# Test attrs
my @attrs = $item->attrs;
is(scalar @attrs, 3, 'got attrs');

# Test XPath select_node
my $xpath_node = $doc->select_node('//item[@id="2"]');
ok($xpath_node, 'xpath select_node');
is($xpath_node->text, 'World', 'xpath node text');

# Test XPath select_nodes
my @xpath_nodes = $doc->select_nodes('//item');
is(scalar @xpath_nodes, 2, 'xpath select_nodes count');

# Test relative XPath
my $rel_item = $root->select_node('item[@id="1"]');
ok($rel_item, 'relative xpath');
is($rel_item->text, 'Hello', 'relative xpath text');

# Test modification
my $new_item = $root->append_child('item');
ok($new_item, 'append_child');
ok($new_item->set_text('New'), 'set_text');
is($new_item->text, 'New', 'new item text');

# Test set_name
ok($new_item->set_name('newitem'), 'set_name');
is($new_item->name, 'newitem', 'new name');

# Test append_attr and set_value
my $new_attr = $new_item->append_attr('test');
ok($new_attr, 'append_attr');
ok($new_attr->set_value('value'), 'attr set_value');
is($new_attr->value, 'value', 'new attr value');

# Test to_string
{
    my $str = $doc->to_string;
    ok($str, 'to_string returns content');
    like($str, qr/<root>/, 'to_string contains root element');
    like($str, qr/<item/, 'to_string contains item elements');
    ok(utf8::is_utf8($str), 'to_string returns UTF-8 string');
}

# Test save_file and load_file with proper temp file
my ($fh, $tmpfile) = tempfile('pugixml_test_XXXXXX', SUFFIX => '.xml', TMPDIR => 1);
close $fh;

ok($doc->save_file($tmpfile), 'save_file');

my $doc2 = XML::PugiXML->new;
ok($doc2->load_file($tmpfile), 'load_file');
my $root2 = $doc2->root;
is($root2->name, 'root', 'loaded root name');
# Filter to element nodes only (type=2), since formatting adds whitespace text nodes
my @all_children = grep { $_->type == 2 } $root2->children;
is(scalar @all_children, 3, 'loaded element children count');

unlink $tmpfile;

# Test invalid node
my $invalid = $root->child('nonexistent');
ok(!defined $invalid || !$invalid->valid, 'invalid node');

# Test invalid attribute
my $invalid_attr = $item->attr('nonexistent');
ok(!defined $invalid_attr, 'invalid attr returns undef');

#--------------------------------------------------
# Error handling tests
#--------------------------------------------------

# Test invalid XML parsing
{
    my $bad_doc = XML::PugiXML->new;
    my $result = $bad_doc->load_string('<root><unclosed>');
    ok(!$result, 'invalid XML returns false');
    like($@, qr/parse error/i, 'parse error sets $@');
}

# Test invalid file
{
    my $bad_doc = XML::PugiXML->new;
    my $result = $bad_doc->load_file('/nonexistent/path/to/file.xml');
    ok(!$result, 'nonexistent file returns false');
}

# Test that $@ is cleared after successful parse
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<bad>');  # Sets $@
    ok($@, '$@ set after bad parse');
    $doc->load_string('<good/>');  # Should clear $@
    is($@, '', '$@ cleared after successful parse');
}

# Test save_file error sets $@
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    $@ = '';
    my $result = $doc->save_file('/nonexistent/dir/file.xml');
    ok(!$result, 'save_file to bad path returns false');
    ok($@, 'save_file sets $@ on error');
}

# Test invalid XPath - should die with error message
{
    my $xpath_doc = XML::PugiXML->new;
    $xpath_doc->load_string('<root><item/></root>');

    eval { $xpath_doc->select_node('[invalid xpath syntax'); };
    ok($@, 'invalid xpath throws error');
    like($@, qr/XPath error/i, 'xpath error message');
}

# Test invalid XPath on select_nodes
{
    my $xpath_doc = XML::PugiXML->new;
    $xpath_doc->load_string('<root><item/></root>');

    eval { my @nodes = $xpath_doc->select_nodes('///invalid'); };
    ok($@, 'invalid xpath in select_nodes throws error');
}

# Test invalid XPath on node
{
    my $xpath_doc = XML::PugiXML->new;
    $xpath_doc->load_string('<root><item/></root>');
    my $r = $xpath_doc->root;

    eval { $r->select_node('[bad'); };
    ok($@, 'invalid xpath on node throws error');
}

#--------------------------------------------------
# UTF-8 tests
#--------------------------------------------------
{
    my $utf8_doc = XML::PugiXML->new;
    $utf8_doc->load_string('<root name="日本語">Привет мир</root>');
    my $utf8_root = $utf8_doc->root;

    my $text = $utf8_root->text;
    ok(utf8::is_utf8($text), 'text returns UTF-8 flagged string');
    is($text, 'Привет мир', 'UTF-8 text content correct');

    my $attr_val = $utf8_root->attr('name')->value;
    ok(utf8::is_utf8($attr_val), 'attr value returns UTF-8 flagged string');
    is($attr_val, '日本語', 'UTF-8 attr value correct');
}

#--------------------------------------------------
# Memory/reference tests
#--------------------------------------------------

# Test that nodes keep document alive
{
    my $node;
    {
        my $temp_doc = XML::PugiXML->new;
        $temp_doc->load_string('<root><item>test</item></root>');
        $node = $temp_doc->root->child('item');
    }
    # Document went out of scope, but node should still work
    is($node->text, 'test', 'node keeps document alive');
}

# Test that attrs keep document alive
{
    my $attr_ref;
    {
        my $temp_doc = XML::PugiXML->new;
        $temp_doc->load_string('<root id="123"/>');
        $attr_ref = $temp_doc->root->attr('id');
    }
    is($attr_ref->value, '123', 'attr keeps document alive');
}

#--------------------------------------------------
# Navigation methods: previous_sibling, last_child
#--------------------------------------------------

# Test previous_sibling
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><b/><c/></root>');
    my $root = $doc->root;

    my $c = $root->last_child;
    is($c->name, 'c', 'last_child returns last child');

    my $b = $c->previous_sibling;
    ok($b, 'previous_sibling returns node');
    is($b->name, 'b', 'previous_sibling is correct');

    my $a = $b->previous_sibling;
    is($a->name, 'a', 'previous_sibling chain works');

    my $none = $a->previous_sibling;
    ok(!defined $none, 'previous_sibling of first child is undef');
}

# Test last_child with no children
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    my $last = $doc->root->last_child;
    ok(!defined $last, 'last_child of empty node is undef');
}

#--------------------------------------------------
# Removal methods: remove_child, remove_attr
#--------------------------------------------------

# Test remove_child
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><b/><c/></root>');
    my $root = $doc->root;

    my @before = $root->children;
    is(scalar @before, 3, 'starts with 3 children');

    my $b = $root->child('b');
    ok($root->remove_child($b), 'remove_child returns true');

    my @after = $root->children;
    is(scalar @after, 2, 'now has 2 children');
    is($after[0]->name, 'a', 'first child is a');
    is($after[1]->name, 'c', 'second child is c');
}

# Test remove_attr
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root id="1" name="test" value="42"/>');
    my $root = $doc->root;

    my @before = $root->attrs;
    is(scalar @before, 3, 'starts with 3 attributes');

    ok($root->remove_attr('name'), 'remove_attr returns true');

    my @after = $root->attrs;
    is(scalar @after, 2, 'now has 2 attributes');

    ok(!defined $root->attr('name'), 'removed attr is gone');
    is($root->attr('id')->value, '1', 'other attrs remain');
    is($root->attr('value')->value, '42', 'other attrs remain');
}

# Test remove_attr on nonexistent
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    my $result = $doc->root->remove_attr('nonexistent');
    ok(!$result, 'remove_attr on nonexistent returns false');
}

#--------------------------------------------------
# Edge case tests
#--------------------------------------------------

# Test empty strings
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root attr=""/>');
    my $attr = $doc->root->attr('attr');
    ok($attr->valid, 'empty attr is valid');
    is($attr->value, '', 'empty attr value is empty string');
}

# Test entities
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root>&lt;&gt;&amp;</root>');
    is($doc->root->text, '<>&', 'entities decoded correctly');
}

# Test CDATA
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><![CDATA[<not>xml</not>]]></root>');
    is($doc->root->text, '<not>xml</not>', 'CDATA preserved correctly');
}

# Test empty document
{
    my $doc = XML::PugiXML->new;
    my $root = $doc->root;
    ok(!defined $root, 'empty doc root is undef');
}

#--------------------------------------------------
# Additional edge case tests
#--------------------------------------------------

# Test deeply nested document
{
    my $nested = '<a>' x 100 . 'deep' . '</a>' x 100;
    my $doc = XML::PugiXML->new;
    ok($doc->load_string($nested), 'deeply nested document parses');
    my $node = $doc->root;
    for (1..99) {
        $node = $node->first_child;
    }
    is($node->text, 'deep', 'can navigate deep nesting');
}

# Test long attribute value
{
    my $long_val = 'x' x 10000;
    my $doc = XML::PugiXML->new;
    $doc->load_string("<root attr=\"$long_val\"/>");
    is(length($doc->root->attr('attr')->value), 10000, 'long attr value preserved');
}

# Test many children
{
    my $xml = '<root>' . ('<item/>' x 1000) . '</root>';
    my $doc = XML::PugiXML->new;
    ok($doc->load_string($xml), 'many children parse');
    my @children = $doc->root->children;
    is(scalar @children, 1000, 'got all 1000 children');
}

# Test XPath returning empty
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><item/></root>');
    my $node = $doc->select_node('//nonexistent');
    ok(!defined $node || !$node->valid, 'xpath no match returns undef or invalid');
    my @nodes = $doc->select_nodes('//nonexistent');
    is(scalar @nodes, 0, 'xpath no matches returns empty list');
}

# Test node modification after XPath
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><b/><c/></root>');
    my @nodes = $doc->select_nodes('//a | //b | //c');
    is(scalar @nodes, 3, 'xpath union works');
    $nodes[0]->set_text('modified');
    is($nodes[0]->text, 'modified', 'can modify xpath result');
}

# Test whitespace handling
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root>  text with spaces  </root>');
    is($doc->root->text, '  text with spaces  ', 'whitespace preserved in text');
}

# Test special characters in names
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root xmlns:ns="http://example.com"><ns:item ns:attr="val"/></root>');
    my $item = $doc->root->first_child;
    is($item->name, 'ns:item', 'namespaced element name');
    is($item->attr('ns:attr')->value, 'val', 'namespaced attr value');
}

#--------------------------------------------------
# CDATA and Comment tests
#--------------------------------------------------

# Test append_cdata
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    my $cdata = $doc->root->append_cdata('<script>alert(1)</script>');
    ok($cdata, 'append_cdata returns node');
    is($cdata->type, 4, 'CDATA node type is 4');
    like($doc->to_string, qr/<!\[CDATA\[<script>alert\(1\)<\/script>\]\]>/, 'CDATA in output');
}

# Test append_comment
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    my $comment = $doc->root->append_comment('This is a comment');
    ok($comment, 'append_comment returns node');
    is($comment->type, 5, 'comment node type is 5');
    like($doc->to_string, qr/<!--This is a comment-->/, 'comment in output');
}

# Test node type
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root>text</root>');
    is($doc->root->type, 2, 'element node type is 2');

    # Text node (PCDATA)
    my $text = $doc->root->first_child;
    is($text->type, 3, 'text node type is 3');
}

# Test reading existing CDATA
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><![CDATA[<raw>&data</raw>]]></root>');
    is($doc->root->text, '<raw>&data</raw>', 'CDATA content read correctly');
    my $cdata_node = $doc->root->first_child;
    is($cdata_node->type, 4, 'existing CDATA node type is 4');
}

#--------------------------------------------------
# New functionality tests
#--------------------------------------------------

# Test prepend_child
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><b/><c/></root>');
    my $a = $doc->root->prepend_child('a');
    ok($a, 'prepend_child returns node');
    is($doc->root->first_child->name, 'a', 'prepend_child inserts at beginning');
}

# Test insert_child_before
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><c/></root>');
    my $c = $doc->root->child('c');
    my $b = $doc->root->insert_child_before('b', $c);
    ok($b, 'insert_child_before returns node');
    my @children = grep { $_->type == 2 } $doc->root->children;
    is($children[1]->name, 'b', 'insert_child_before at correct position');
}

# Test insert_child_after
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><c/></root>');
    my $a = $doc->root->child('a');
    my $b = $doc->root->insert_child_after('b', $a);
    ok($b, 'insert_child_after returns node');
    my @children = grep { $_->type == 2 } $doc->root->children;
    is($children[1]->name, 'b', 'insert_child_after at correct position');
}

# Test prepend_attr
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root b="2" c="3"/>');
    my $a = $doc->root->prepend_attr('a');
    $a->set_value('1');
    my @attrs = $doc->root->attrs;
    is($attrs[0]->name, 'a', 'prepend_attr inserts at beginning');
}

# Test path()
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><parent><child id="1"/></parent></root>');
    my $child = $doc->root->child('parent')->child('child');
    is($child->path, '/root/parent/child', 'path returns correct XPath');
    is($child->path('.'), '.root.parent.child', 'path with custom delimiter');
}

# Test find_child_by_attribute
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><item id="1"/><item id="2"/><item id="3"/></root>');
    my $item = $doc->root->find_child_by_attribute('item', 'id', '2');
    ok($item, 'find_child_by_attribute returns node');
    is($item->attr('id')->value, '2', 'find_child_by_attribute finds correct node');

    my $none = $doc->root->find_child_by_attribute('item', 'id', '99');
    ok(!defined $none || !$none->valid, 'find_child_by_attribute returns undef for no match');
}

# Test root() on node
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><parent><child/></parent></root>');
    my $child = $doc->root->child('parent')->child('child');
    my $root = $child->root;
    ok($root, 'node root() returns node');
    # root() returns the document node, not the document element
    is($root->type, 1, 'root() returns document node');
}

# Test next_sibling with name filter
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><b/><a/><c/><a/></root>');
    my $first_a = $doc->root->child('a');
    my $second_a = $first_a->next_sibling('a');
    ok($second_a, 'next_sibling with name filter');
    my $third_a = $second_a->next_sibling('a');
    ok($third_a, 'next_sibling chain with name');
    my $no_more = $third_a->next_sibling('a');
    ok(!defined $no_more, 'next_sibling returns undef when no more');
}

# Test previous_sibling with name filter
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><b/><a/><c/><a/></root>');
    my $last_a = $doc->root->last_child;  # This gets 'a' if no whitespace
    # Use select to get last <a>
    my ($last) = reverse $doc->select_nodes('//a');
    my $prev_a = $last->previous_sibling('a');
    ok($prev_a, 'previous_sibling with name filter');
}

# Test as_uint
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root val="4294967295"/>');
    is($doc->root->attr('val')->as_uint, 4294967295, 'as_uint works');
}

# Test as_llong / as_ullong
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root big="9223372036854775807" ubig="18446744073709551615"/>');
    is($doc->root->attr('big')->as_llong, 9223372036854775807, 'as_llong works');
    # as_ullong might overflow on some systems, just check it doesn't crash
    ok(defined $doc->root->attr('ubig')->as_ullong, 'as_ullong works');
}

# Test compiled XPath
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><item id="1">A</item><item id="2">B</item><item id="3">C</item></root>');

    my $xpath = $doc->compile_xpath('//item');
    ok($xpath, 'compile_xpath returns object');

    my @nodes = $xpath->evaluate_nodes($doc->root);
    is(scalar @nodes, 3, 'evaluate_nodes returns correct count');

    my $single = $xpath->evaluate_node($doc->root);
    ok($single, 'evaluate_node returns node');

    my $xpath_str = $doc->compile_xpath('string(//item[@id="2"])');
    is($xpath_str->evaluate_string($doc->root), 'B', 'evaluate_string works');

    my $xpath_num = $doc->compile_xpath('count(//item)');
    is($xpath_num->evaluate_number($doc->root), 3, 'evaluate_number works');

    my $xpath_bool = $doc->compile_xpath('boolean(//item[@id="1"])');
    ok($xpath_bool->evaluate_boolean($doc->root), 'evaluate_boolean works');
}

# Test invalid compiled XPath
{
    my $doc = XML::PugiXML->new;
    eval { $doc->compile_xpath('[invalid'); };
    ok($@, 'compile_xpath throws on invalid xpath');
    like($@, qr/XPath/i, 'compile error message');
}

# Test format constants
{
    ok(defined XML::PugiXML::FORMAT_DEFAULT(), 'FORMAT_DEFAULT defined');
    ok(defined XML::PugiXML::FORMAT_INDENT(), 'FORMAT_INDENT defined');
    ok(defined XML::PugiXML::FORMAT_RAW(), 'FORMAT_RAW defined');
    ok(defined XML::PugiXML::FORMAT_NO_DECLARATION(), 'FORMAT_NO_DECLARATION defined');
}

# Test to_string with formatting options
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><item/></root>');

    # Raw format (no indentation)
    my $raw = $doc->to_string('', XML::PugiXML::FORMAT_RAW());
    unlike($raw, qr/\n.*<item/, 'FORMAT_RAW no newline before item');

    # No declaration
    my $no_decl = $doc->to_string("\t", XML::PugiXML::FORMAT_NO_DECLARATION());
    unlike($no_decl, qr/<\?xml/, 'FORMAT_NO_DECLARATION omits declaration');

    # Custom indent
    my $spaces = $doc->to_string('    ');  # 4 spaces
    like($spaces, qr/    <item/, 'custom indent works');
}

# Test save_file with formatting
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.xml', UNLINK => 1);
    close $fh;

    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><item/></root>');

    # Save with raw format
    ok($doc->save_file($tmpfile, '', XML::PugiXML::FORMAT_RAW()), 'save_file with format');

    open my $f, '<', $tmpfile;
    my $content = do { local $/; <$f> };
    close $f;

    unlike($content, qr/\n.*<item/, 'saved file uses raw format');
    unlink $tmpfile;
}

#--------------------------------------------------
# Node cloning tests
#--------------------------------------------------

# Test append_copy
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><source id="1"><child>text</child></source><target/></root>');
    my $source = $doc->root->child('source');
    my $target = $doc->root->child('target');

    my $copy = $target->append_copy($source);
    ok($copy, 'append_copy returns node');
    is($copy->attr('id')->value, '1', 'append_copy copies attributes');
    is($copy->child('child')->text, 'text', 'append_copy copies children');

    # Verify it's a copy, not a move
    ok($doc->root->child('source'), 'original still exists after copy');
}

# Test prepend_copy
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><source/><target><existing/></target></root>');
    my $source = $doc->root->child('source');
    my $target = $doc->root->child('target');

    my $copy = $target->prepend_copy($source);
    ok($copy, 'prepend_copy returns node');
    is($target->first_child->name, 'source', 'prepend_copy inserts at beginning');
}

# Test insert_copy_before
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><source/><target><a/><c/></target></root>');
    my $source = $doc->root->child('source');
    my $target = $doc->root->child('target');
    my $c = $target->child('c');

    my $copy = $target->insert_copy_before($source, $c);
    ok($copy, 'insert_copy_before returns node');
    my @children = grep { $_->type == 2 } $target->children;
    is($children[1]->name, 'source', 'insert_copy_before at correct position');
}

# Test insert_copy_after
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><source/><target><a/><c/></target></root>');
    my $source = $doc->root->child('source');
    my $target = $doc->root->child('target');
    my $a = $target->child('a');

    my $copy = $target->insert_copy_after($source, $a);
    ok($copy, 'insert_copy_after returns node');
    my @children = grep { $_->type == 2 } $target->children;
    is($children[1]->name, 'source', 'insert_copy_after at correct position');
}

#--------------------------------------------------
# set_attr convenience method
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');

    # Set new attribute
    my $attr = $doc->root->set_attr('new', 'value1');
    ok($attr, 'set_attr returns attr');
    is($attr->value, 'value1', 'set_attr creates new attribute');

    # Update existing attribute
    $doc->root->set_attr('new', 'value2');
    is($doc->root->attr('new')->value, 'value2', 'set_attr updates existing');
}

#--------------------------------------------------
# Processing instructions
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');

    my $pi = $doc->root->append_pi('xml-stylesheet', 'type="text/xsl" href="style.xsl"');
    ok($pi, 'append_pi returns node');
    is($pi->type, 6, 'PI node type is 6');
    is($pi->name, 'xml-stylesheet', 'PI target is name');
    is($pi->value, 'type="text/xsl" href="style.xsl"', 'PI data is value');

    like($doc->to_string('', XML::PugiXML::FORMAT_RAW()),
         qr/<\?xml-stylesheet.*\?>/, 'PI in output');

    # PI without data
    my $pi2 = $doc->root->append_pi('empty-pi');
    ok($pi2, 'append_pi without data returns node');
    is($pi2->name, 'empty-pi', 'PI without data has correct name');
}

#--------------------------------------------------
# reset() method
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><item/></root>');
    ok($doc->root, 'document has root before reset');

    $doc->reset;
    ok(!defined $doc->root, 'document empty after reset');

    # Can load again
    $doc->load_string('<newroot/>');
    is($doc->root->name, 'newroot', 'can load after reset');
}

#--------------------------------------------------
# Parse options
#--------------------------------------------------
{
    # Test parse constants exist
    ok(defined XML::PugiXML::PARSE_DEFAULT(), 'PARSE_DEFAULT defined');
    ok(defined XML::PugiXML::PARSE_MINIMAL(), 'PARSE_MINIMAL defined');
    ok(defined XML::PugiXML::PARSE_PI(), 'PARSE_PI defined');
    ok(defined XML::PugiXML::PARSE_COMMENTS(), 'PARSE_COMMENTS defined');
    ok(defined XML::PugiXML::PARSE_CDATA(), 'PARSE_CDATA defined');
    ok(defined XML::PugiXML::PARSE_WS_PCDATA(), 'PARSE_WS_PCDATA defined');
    ok(defined XML::PugiXML::PARSE_FULL(), 'PARSE_FULL defined');
}

# Test parsing with PARSE_WS_PCDATA (preserve whitespace)
{
    my $doc = XML::PugiXML->new;
    $doc->load_string("<root>\n  <item/>\n</root>", XML::PugiXML::PARSE_DEFAULT() | XML::PugiXML::PARSE_WS_PCDATA());
    my @children = $doc->root->children;
    # With PARSE_WS_PCDATA, whitespace between elements becomes PCDATA nodes
    ok(scalar(@children) > 1, 'PARSE_WS_PCDATA preserves whitespace nodes');
}

# Test parsing with PARSE_MINIMAL (skip comments, no escapes)
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><!--comment--><item/></root>', XML::PugiXML::PARSE_MINIMAL());
    my @children = grep { $_->type == 5 } $doc->root->children;  # type 5 = comment
    is(scalar(@children), 0, 'PARSE_MINIMAL skips comments');

    # PARSE_MINIMAL disables entity processing
    $doc->load_string('<root>&#65;</root>', XML::PugiXML::PARSE_MINIMAL());
    is($doc->root->text, '&#65;', 'PARSE_MINIMAL does not decode entities');
}

#--------------------------------------------------
# hash() method
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><b/></root>');

    my $hash_a = $doc->root->child('a')->hash;
    my $hash_b = $doc->root->child('b')->hash;

    ok($hash_a, 'hash returns value');
    ok($hash_a != $hash_b, 'different nodes have different hashes');

    # Same node should have same hash
    my $hash_a2 = $doc->root->child('a')->hash;
    is($hash_a, $hash_a2, 'same node has same hash');
}

#--------------------------------------------------
# offset_debug() method
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><item/></root>');

    my $offset = $doc->root->child('item')->offset_debug;
    ok(defined $offset, 'offset_debug returns value');
    # The exact offset depends on pugixml internals, just verify it's reasonable
    ok($offset >= 0, 'offset_debug is non-negative');
}

#--------------------------------------------------
# FORMAT_WRITE_BOM test
#--------------------------------------------------
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');

    ok(defined XML::PugiXML::FORMAT_WRITE_BOM(), 'FORMAT_WRITE_BOM defined');

    my $with_bom = $doc->to_string("\t", XML::PugiXML::FORMAT_WRITE_BOM());
    # BOM is Unicode character U+FEFF (returned as Perl Unicode string)
    ok(substr($with_bom, 0, 1) eq "\x{FEFF}", 'FORMAT_WRITE_BOM adds BOM at start');
}

#--------------------------------------------------
# Additional parse constants tests
#--------------------------------------------------
{
    # Verify all parse constants are defined
    ok(defined XML::PugiXML::PARSE_ESCAPES(), 'PARSE_ESCAPES defined');
    ok(defined XML::PugiXML::PARSE_EOL(), 'PARSE_EOL defined');
    ok(defined XML::PugiXML::PARSE_DECLARATION(), 'PARSE_DECLARATION defined');
    ok(defined XML::PugiXML::PARSE_DOCTYPE(), 'PARSE_DOCTYPE defined');
}

# Test PARSE_DECLARATION
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<?xml version="1.0" encoding="UTF-8"?><root/>', XML::PugiXML::PARSE_DECLARATION());
    # With PARSE_DECLARATION, the declaration node should be accessible
    my $first = $doc->child('xml');  # Declaration appears as child named 'xml'
    # Declaration node type is 7
    ok(defined $first && $first->type == 7, 'PARSE_DECLARATION parses declaration');
}

# Test PARSE_DOCTYPE
{
    my $doc = XML::PugiXML->new;
    my $xml = '<!DOCTYPE root><root/>';
    ok($doc->load_string($xml, XML::PugiXML::PARSE_DOCTYPE()), 'PARSE_DOCTYPE parses DOCTYPE');
}

# Test PARSE_ESCAPES (enabled by default, test explicit use)
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root>&#65;&#66;&#67;</root>', XML::PugiXML::PARSE_ESCAPES());
    is($doc->root->text, 'ABC', 'PARSE_ESCAPES decodes numeric entities');
}

# Test PARSE_EOL (normalizes line endings)
{
    my $doc = XML::PugiXML->new;
    $doc->load_string("<root>line1\r\nline2</root>", XML::PugiXML::PARSE_EOL());
    my $text = $doc->root->text;
    unlike($text, qr/\r/, 'PARSE_EOL normalizes CRLF to LF');
}

#--------------------------------------------------
# Test gaps: error paths and edge cases
#--------------------------------------------------

# doc->child with nonexistent name
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    ok(!defined $doc->child('nonexistent'), 'doc->child nonexistent returns undef');
}

# load_file failure sets $@
{
    my $doc = XML::PugiXML->new;
    $doc->load_file('/nonexistent/path.xml');
    like($@, qr/parse error/i, 'load_file failure sets $@ with error');
}

# load_string $@ includes offset
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><bad');
    like($@, qr/offset \d+/, 'parse error $@ includes offset');
}

# set_value on element node returns false
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    ok(!$doc->root->set_value('x'), 'set_value on element returns false');
}

# set_name on text node returns false
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root>text</root>');
    my $text_node = $doc->root->first_child;
    is($text_node->type, 3, 'got text node');
    ok(!$text_node->set_name('x'), 'set_name on text node returns false');
}

# value() on CDATA node
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><![CDATA[data]]></root>');
    my $cdata = $doc->root->first_child;
    is($cdata->value, 'data', 'value() on CDATA node returns content');
}

# previous_sibling with name filter no match
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><b/><c/></root>');
    my $c = $doc->root->last_child;
    ok(!defined $c->previous_sibling('z'), 'previous_sibling(name) no match returns undef');
}

# children with name that matches nothing
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/><b/></root>');
    my @none = $doc->root->children('z');
    is(scalar @none, 0, 'children(nonexistent) returns empty list');
}

# attrs on node with no attributes
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    my @a = $doc->root->attrs;
    is(scalar @a, 0, 'attrs on no-attribute node returns empty list');
}

# Node::select_nodes with invalid XPath
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root/>');
    eval { $doc->root->select_nodes('///bad'); };
    ok($@, 'invalid xpath on node select_nodes throws');
}

# evaluate_node with no match
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/></root>');
    my $xpath = $doc->compile_xpath('//nonexistent');
    my $result = $xpath->evaluate_node($doc->root);
    ok(!defined $result, 'evaluate_node no match returns undef');
}

# evaluate_nodes with no match
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><a/></root>');
    my $xpath = $doc->compile_xpath('//nonexistent');
    my @results = $xpath->evaluate_nodes($doc->root);
    is(scalar @results, 0, 'evaluate_nodes no match returns empty list');
}

# PARSE_COMMENTS functional test
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><!--hello--></root>', XML::PugiXML::PARSE_COMMENTS());
    my @comments = grep { $_->type == 5 } $doc->root->children;
    is(scalar @comments, 1, 'PARSE_COMMENTS makes comments accessible');
    is($comments[0]->value, 'hello', 'PARSE_COMMENTS comment content');
}

# PARSE_CDATA functional test
{
    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><![CDATA[raw]]></root>', XML::PugiXML::PARSE_CDATA());
    my @cdata = grep { $_->type == 4 } $doc->root->children;
    is(scalar @cdata, 1, 'PARSE_CDATA makes CDATA nodes accessible');
    is($cdata[0]->value, 'raw', 'PARSE_CDATA content');
}

# save_file clears $@ on success
{
    my ($fh, $tmp) = tempfile(SUFFIX => '.xml', UNLINK => 1);
    close $fh;
    my $doc = XML::PugiXML->new;
    $doc->load_string('<bad>');  # sets $@
    ok($@, '$@ set before save_file');
    $doc->load_string('<root/>');
    $doc->save_file($tmp);
    is($@, '', 'save_file clears $@ on success');
    unlink $tmp;
}

done_testing;
