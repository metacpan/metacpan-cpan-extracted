use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use XML::PugiXML;

# Node-mutating methods that take an insertion anchor / child argument require
# that argument to live in the SAME document as the invocant. A foreign-document
# argument must croak, not silently no-op (pugixml returns a null node otherwise).

my $doc1 = XML::PugiXML->new;
ok $doc1->load_string('<root><a/><b/></root>'), 'doc1 loaded';
my @kids1 = $doc1->root->children;
my $root1 = $doc1->root;

my $doc2 = XML::PugiXML->new;
ok $doc2->load_string('<other><x/></other>'), 'doc2 loaded';
my ($x2) = $doc2->root->children;   # node living in doc2

# --- foreign-document argument must croak (these fail the check before mutating) ---
eval { $root1->insert_child_before('n', $x2) };
like $@, qr/different document/, 'insert_child_before rejects foreign ref_node';

eval { $root1->insert_child_after('n', $x2) };
like $@, qr/different document/, 'insert_child_after rejects foreign ref_node';

eval { $root1->remove_child($x2) };
like $@, qr/different document/, 'remove_child rejects foreign child';

eval { $root1->insert_copy_before($x2, $x2) };  # ref_node ($x2) is foreign
like $@, qr/different document/, 'insert_copy_before rejects foreign ref_node';

eval { $root1->insert_copy_after($x2, $x2) };
like $@, qr/different document/, 'insert_copy_after rejects foreign ref_node';

# --- legitimate same-document operations still work (fresh doc per case) ---
{
    my $d = XML::PugiXML->new;
    $d->load_string('<root><a/><b/></root>');
    my @k = $d->root->children;
    eval { $d->root->insert_child_before('inserted', $k[1]) };
    is $@, '', 'insert_child_before works with a same-document ref_node';
}

# --- cross-document COPY is allowed: the SOURCE may be foreign, only the
#     ref_node anchor must be same-document ---
{
    my $d = XML::PugiXML->new;
    $d->load_string('<root><a/><b/></root>');
    my @k = $d->root->children;
    my $src = XML::PugiXML->new;
    $src->load_string('<imported/>');
    eval { $d->root->insert_copy_before($src->root, $k[1]) };
    is $@, '', 'insert_copy_before allows a foreign SOURCE with same-document ref_node';
}

done_testing;
