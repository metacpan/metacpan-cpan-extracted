use strict;
use warnings;
use Test::More;
use XML::PugiXML;

sub fresh {
    my $d = XML::PugiXML->new;
    $d->load_string('<a><b/><c/></a>');
    $d;
}

# A handle holds its document, not the variable the document came from.
{
    my $doc  = fresh();
    my $root = $doc->root;
    undef $doc;
    ok $root->valid, 'a node stays valid after undef $doc';
    is $root->name, 'a', 'and still reads its document';
}

{
    my $doc  = fresh();
    my $old  = $doc;
    my $root = $doc->root;
    $doc = fresh();
    my $b = $root->first_child;
    $old->reset;
    ok !$b->valid, 'reset invalidates a handle derived after the variable was rebound';
    ok !$root->valid, 'and the handle it was derived from';
}

{
    my @docs  = (fresh(), fresh());
    my @roots = map { $_->root } @docs;
    my $real  = $docs[0];
    $docs[0]  = $docs[1];
    my $b = $roots[0]->first_child;
    $real->root->remove_child($b);
    ok !$b->valid, 'remove_child invalidates a handle whose array slot was rebound';
}

done_testing;
