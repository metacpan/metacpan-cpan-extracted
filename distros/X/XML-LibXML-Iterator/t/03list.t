use Test;


BEGIN { plan tests => 9; }

use XML::LibXML;
use XML::LibXML::NodeList::Iterator;

my $xmlstr = "<A><B/><B/>T<C><D/></C></A>";

sub t01_list_first_element {
    my $doc = XML::LibXML->new->parse_string( '<test><n1/><n2/></test>');
    
    unless ( defined $doc ) {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $nodelist = $doc->findnodes( '/test/*' );
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist ); 

    my $node = $iterator->next();

    unless ( defined $node ) {
        print "# next did not return a node\n";
        return 0;
    }

    unless ( $node->nodeName() eq 'n1' ) {
        print "# expected 'n1' received '" . $node->nodeName() . "'\n"; 
        return 0;
    }
    
    return 1;
}

ok(t01_list_first_element());

sub t06_set_first {
    my $doc = XML::LibXML->new->parse_string( $xmlstr );
    
    unless ( defined $doc ) {
        print "# XML string was not parsed properly\n";
        return 0;
    }
    
    my $nodelist = $doc->findnodes( '//A | //B | //C' );
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist ); 

    $iterator->first();

    unless ( defined $iterator->current() ) {
        print "# there is no first node\n";
        return 0;
    }
    
    unless ( $iterator->current()->nodeName() eq "A" ) {
        print "# expected nodeName 'A' received '"
            . $iterator->current()->nodeName()
            . "'\n";
        return 0;
    }

    return 1;
}
ok(t06_set_first());

sub t07_set_last {
    my $doc = XML::LibXML->new->parse_string( $xmlstr );
    
    unless ( defined $doc ) {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $nodelist = $doc->findnodes( '//A | //B | //C' );
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist ); 

    $iterator->last();

    unless ( defined $iterator->current() ) {
        print "# there is no last node\n";
        return 0;
    }
    
    unless ( $iterator->current()->nodeName() eq "C" ) {
        print "# expected nodeName 'C' received '"
            . $iterator->current()->nodeName()
            . "'\n";
        return 0;
    }

    return 1;
}

ok(t07_set_last());

sub t02_loop_forward {
    my $doc = XML::LibXML->new->parse_string( $xmlstr );
    
    unless ( defined $doc ) {
        print "# XML string was not parsed properly\n";
        return 0;
    }
    my $nodelist = $doc->findnodes( '//A|//B|//C' );
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist ); 

    my $i = 0;

    while ( $iterator->nextNode() ) {
        $i++;
    }

    unless ( $i == 4 ) {
        print "# expected 4 iterations done " . $i . "\n";
        return 0;
    }

    unless ( defined $iterator->current() ) {
        print "# wen out of scope\n";
        return 0;
    }
    
    unless ( $iterator->current()->nodeName() eq "C" ) {
        print "# expected nodeName 'C' received '"
            . $iterator->current()->nodeName()
            . "'\n";
        return 0;
    }

    $iterator->first();
    $i = 0;

    while ( $iterator->nextNode() ) {
        $i++;
    }

    unless ( $i == 3 ) {
        print "# expected 3 iterations done " . $i . "\n";
        return 0;
    }

    unless ( defined $iterator->current() ) {
        print "# wen out of scope\n";
        return 0;
    }
    
    unless ( $iterator->current()->nodeName() eq "C" ) {
        print "# expected nodeName 'C' received '"
            . $iterator->current()->nodeName()
            . "'\n";
        return 0;
    }

    return 1;
}
ok(t02_loop_forward());

sub t03_loop_backward {
    my $doc = XML::LibXML->new->parse_string( $xmlstr );
    
    unless ( defined $doc ) {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $nodelist = $doc->findnodes( '//A | //B | //C' );
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist ); 

    my $i = 0;

    $iterator->last();
    while ( $iterator->previousNode() ) {
        $i++;
    }

    unless ( $i == 3 ) {
        print "# expected 3 iterations done " . $i . "\n";
        return 0;
    }

    unless ( defined $iterator->current() ) {
        print "# went out of scope!\n";
        return 0;
    }

    unless ( $iterator->current()->nodeName() eq "A" ) {
        print "# expected nodeName 'A' received '"
            . $iterator->current()->nodeName()
            . "'\n";
        return 0;
    }
    return 1;
}
ok(t03_loop_backward());

sub t04_loop_forward_backward {
    my $doc = XML::LibXML->new->parse_string( $xmlstr );
    
    unless ( defined $doc ) {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $nodelist = $doc->findnodes( '//A | //B | //C' );
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist ); 

    my $i = 0;

    while ( $iterator->nextNode() ) {
        $i++;
    }
    while ( $iterator->previousNode() ) {
        $i++;
    }
    
    unless ( $i == 7 ) {
        print "# expected 7 iterations done " . $i . "\n";
        return 0;
    }

    unless ( defined $iterator->current() ) {
        print "# went out of scope!\n";
        return 0;
    }

    unless ( $iterator->current()->nodeName() eq "A" ) {
        print "# expected nodeName 'A' received '"
            . $iterator->current()->nodeName()
            . "'\n";
        return 0;
    }

    return 1;
}
ok(t04_loop_forward_backward());

sub t05_run_iterate {
    my $doc = XML::LibXML->new->parse_string( $xmlstr );
    
    unless ( defined $doc ) {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $nodelist = $doc->findnodes( '//A | //B | //C' );
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist ); 

    my $i = 0;
    $iterator->iterate( sub { $i++; } );

    unless ( $i == 4 ) {
        print "# expected 4 iterations done " . $i . "\n";
        return 0;
    }

    return 1;
}
ok(t05_run_iterate());

# RT#28688
package MyFilter;

use base qw(XML::NodeFilter);
use XML::NodeFilter qw(:results);
use UNIVERSAL;

sub accept_node {
    my $self = shift;
    my $node = shift;
    if (!UNIVERSAL::isa($node, 'XML::LibXML::Element')) {
        die "invalid node in MyFilter::accept_node()";
    }
    return FILTER_DECLINED;
}

package main;

sub t08_last_with_filter {
    my $doc = XML::LibXML->new->parse_string( $xmlstr );
    
    unless ( defined $doc ) {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $nodelist = $doc->findnodes( '//*' );
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist ); 
    $iterator->add_filter( MyFilter->new() );

    $iterator->last();

    unless ( defined $iterator->current() ) {
        print "# there is no last node\n";
        return 0;
    }
    
    unless ( $iterator->current()->nodeName() eq "D" ) {
        print "# expected nodeName 'D' received '"
            . $iterator->current()->nodeName()
            . "'\n";
        return 0;
    }

    return 1;
}
ok(t08_last_with_filter());

# END RT#28688

# RT#29262

sub t09_pass_nodes {
    my $doc = XML::LibXML->new->parse_string( '<a><b/><c/></a>' );

    my $nodelist = $doc->findnodes('/a/*');
    my $iterator = XML::LibXML::NodeList::Iterator->new( $nodelist );
    
    my $i = 0;
    my $cstr = '';
    $iterator->iterate( sub { my($s, $n) = @_; 
                              if ( defined $n && $n->can('nodeName') ) {
                                  $i++;
                                  $cstr.=$n->nodeName();
                              }
                        });

    unless ( $i == 2 ) {
        print "# wrong number of nodes has been processed! $i\n";
        return 0;
    }
    unless ( $cstr eq 'bc' ) {
        print "# wrong nodes have been processed! '$cstr'\n";
        return 0;
    }
    
    return 1;
}

ok(t09_pass_nodes());

# END RT#29262
