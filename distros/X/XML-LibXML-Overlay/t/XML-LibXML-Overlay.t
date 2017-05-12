use Test::More tests => 16;
use XML::LibXML;

BEGIN {
    use_ok('XML::LibXML::Overlay');
    use_ok('XML::LibXML::Overlay::Document');
};

# load overlay and target xml files
my $overlay = XML::LibXML::Overlay->load_xml(
    'location' => 't/xml/overlay.xml',
);

ok( $overlay, 'created overlay document' );
ok( $overlay->isa('XML::LibXML::Overlay::Document'), 'document is a XML::LibXML::Overlay::Document' );

my $target = XML::LibXML->load_xml(
    'location' => 't/xml/target.xml',
);

ok( $target, 'created target document' );

# applay the overlay to the target
$overlay->apply_to($target);

# appendChild
{
    my @nodes = $target->findnodes("/catalog/book[\@id='book2']/author");
    is ( scalar @nodes, 3, 'author node has been appended' );
    is ( $nodes[2]->textContent(), 'Jon Orwant', 'appended node has the correct position' );
    
    @nodes = $target->findnodes("//author[text()='Jon Orwant']");
    is ( scalar @nodes, 1, 'node has been appended only once' );
}

# delete
{
    my @nodes = $target->findnodes("/catalog/book[\@id='book1']/author[text()='Delete Me!']");
    is ( scalar @nodes, 0, 'author node has been deleted' );
}

# insertBefore
{
    my @nodes = $target->findnodes("/catalog/book[\@id='book0']/*");
    is ( scalar @nodes, 3, 'inserted book0' );
    @nodes = $target->findnodes("/catalog/book");
    is ( $nodes[0]->getAttribute('id'), 'book0', 'book0 at the right position' );
}

# insertAfter
{
    my @nodes = $target->findnodes("/catalog/book[\@id='book4']/*");
    is ( scalar @nodes, 3, 'inserted book4' );
    @nodes = $target->findnodes("/catalog/book");
    is ( $nodes[4]->getAttribute('id'), 'book4', 'book4 at the right position' );
}

# setAttribute
{
    my @nodes = $target->findnodes("/catalog/book[\@id='book5']");
    is ( scalar @nodes, 1, 'found book5' );
    is ( $nodes[0]->getAttribute('myAttribute'), 'attr', 'set attribute for book5');
}

# removeAttribute
{
    my @nodes = $target->findnodes("/catalog/book[\@delete]");
    is ( scalar @nodes, 0, 'attributes deleted' );
}

