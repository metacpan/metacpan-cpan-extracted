use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use XML::PugiXML;

# Embedded NUL in a string argument must croak everywhere, not just in the
# tree-mutation methods. Lookup and removal arguments used to go through a
# plain const char* (SvPV_nolen) and silently truncate, so remove_attr("id\0x")
# quietly removed "id" and child("a\0b") quietly looked up "a".

my $doc = XML::PugiXML->new;
ok $doc->load_string('<r id="1" keep="2"><a><b/></a></r>'), 'doc loaded';
my $root = $doc->root;

my @doc_cases = (
    ['child'         => sub { $doc->child("r\0x") }],
    ['select_node'   => sub { $doc->select_node("/r\0x") }],
    ['select_nodes'  => sub { my @n = $doc->select_nodes("/r\0x"); }],
    ['compile_xpath' => sub { $doc->compile_xpath("/r\0x") }],
    ['load_file'     => sub { $doc->load_file("/nonexistent\0x") }],
    ['save_file'     => sub { $doc->save_file("/nonexistent\0x") }],
    ['to_string'     => sub { $doc->to_string("\t\0x") }],
);

my @node_cases = (
    ['child'                   => sub { $root->child("a\0x") }],
    ['attr'                    => sub { $root->attr("id\0x") }],
    ['children'                => sub { my @c = $root->children("a\0x"); }],
    ['next_sibling'            => sub { $root->next_sibling("a\0x") }],
    ['previous_sibling'        => sub { $root->previous_sibling("a\0x") }],
    ['find_child_by_attribute' => sub { $root->find_child_by_attribute("a\0x", 'k', 'v') }],
    ['remove_attr'             => sub { $root->remove_attr("id\0x") }],
    ['select_node'             => sub { $root->select_node("a\0x") }],
    ['select_nodes'            => sub { my @n = $root->select_nodes("a\0x"); }],
);

for my $case (@doc_cases, @node_cases) {
    my ($name, $code) = @$case;
    ok !eval { $code->(); 1 }, "$name rejects an embedded NUL";
    like $@, qr/embedded NUL byte/, "$name gives the NUL diagnostic";
}

# and the truncation it used to cause must not have happened
ok $root->attr('id')->valid, 'remove_attr("id\0x") did not remove "id"';
is $root->attr('id')->value, '1', 'attribute value intact';

# mutation arguments keep rejecting NUL (unchanged behaviour, guarded here)
for my $case (
    ['append_child' => sub { $root->append_child("a\0b") }],
    ['set_attr'     => sub { $root->set_attr("k\0b", 'v') }],
    ['set_text'     => sub { $root->set_text("t\0b") }],
    ['set_name'     => sub { $root->set_name("n\0b") }],
) {
    my ($name, $code) = @$case;
    ok !eval { $code->(); 1 }, "$name still rejects an embedded NUL";
}

#--------------------------------------------------
# path() delimiter must be exactly one character
#--------------------------------------------------
{
    my $b = $root->child('a')->child('b');

    is $b->path,      '/r/a/b', 'path() defaults to /';
    is $b->path('/'), '/r/a/b', 'path("/") explicit';
    is $b->path(':'), ':r:a:b', 'path(":") uses the given delimiter';

    for my $bad ('', '::', 'abc') {
        ok !eval { $b->path($bad); 1 },
            sprintf('path(%s) croaks instead of truncating', "'$bad'");
        like $@, qr/single character/, 'path() explains the requirement';
    }

    # previously produced a NUL-delimited path with an "uninitialized" warning
    ok !eval { no warnings 'uninitialized'; $b->path(undef); 1 },
        'path(undef) croaks rather than using a NUL delimiter';
}

#--------------------------------------------------
# ithreads safety net: all four classes must decline to be cloned
#--------------------------------------------------
for my $class (qw(XML::PugiXML XML::PugiXML::Node
                  XML::PugiXML::Attr XML::PugiXML::XPath)) {
    can_ok $class, 'CLONE_SKIP';
    ok $class->CLONE_SKIP, "$class sets CLONE_SKIP (no ithreads double-free)";
}

done_testing;
