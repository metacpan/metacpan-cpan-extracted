use Test;

BEGIN { plan tests => 7; }

use XML::LibXML;
use XML::LibXML::Iterator;

my $xmlstr = "<A><B/>T<B/><C><D/></C></A>";
my $libversion;
eval { $libversion = XML::LibXML::LIBXML_VERSION(); };

sub t01_tree_first_element
{
    my $doc = XML::LibXML->new->parse_string('<test><n1/><n2/></test>');

    unless ( defined $doc )
    {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $iterator = XML::LibXML::Iterator->new( $doc->documentElement );

    my $node = $iterator->nextNode();

    unless ( defined $node )
    {
        print "# next did not return a node\n";
        return 0;
    }

    unless ( $node->nodeName() eq 'test' )
    {
        print "# expected 'test' received '" . $node->nodeName() . "'\n";
        return 0;
    }

    return 1;
}

ok( t01_tree_first_element() );

sub t06_set_first
{
    my $doc = XML::LibXML->new->parse_string($xmlstr);

    unless ( defined $doc )
    {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $iterator = XML::LibXML::Iterator->new( $doc->documentElement );

    $iterator->first();

    unless ( defined $iterator->current() )
    {
        print "# there is no first node\n";
        return 0;
    }

    unless ( $iterator->current()->nodeName() eq "A" )
    {
        print "# expected nodeName 'A' received '"
            . $iterator->current()->nodeName() . "'\n";
        return 0;
    }

    return 1;
}
ok( t06_set_first() );

sub t07_set_last
{
    my $doc = XML::LibXML->new->parse_string($xmlstr);

    unless ( defined $doc )
    {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $iterator = XML::LibXML::Iterator->new( $doc->documentElement );

    $iterator->last();

    unless ( defined $iterator->current() )
    {
        print "# there is no last node\n";
        return 0;
    }

    unless ( $iterator->current()->nodeName() eq "D" )
    {
        print "# expected nodeName 'D' received '"
            . $iterator->current()->nodeName() . "'\n";
        return 0;
    }

    return 1;
}

ok( t07_set_last() );

sub t02_loop_forward
{
    my $doc = XML::LibXML->new->parse_string($xmlstr);

    unless ( defined $doc )
    {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $iterator = XML::LibXML::Iterator->new( $doc->documentElement );

    my $i = 0;

    while ( $iterator->nextNode() )
    {
        $i++;
    }

    unless ( $i == 6 )
    {
        print "# expected 6 iterations done " . $i . "\n";
        return 0;
    }

    $iterator->first();
    $i = 0;

    while ( $iterator->nextNode() )
    {
        $i++;
    }

    unless ( $i == 5 )
    {
        print "# expected 5 iterations done " . $i . "\n";
        return 0;
    }

    unless ( defined $iterator->current() )
    {
        print "# wen out of scope\n";
        return 0;
    }

    unless ( $iterator->current()->nodeName() eq "D" )
    {
        print "# expected nodeName 'D' received '"
            . $iterator->current()->nodeName() . "'\n";
        return 0;
    }

    return 1;
}
ok( t02_loop_forward() );

sub t03_loop_backward
{
    my $doc = XML::LibXML->new->parse_string($xmlstr);

    unless ( defined $doc )
    {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $iterator = XML::LibXML::Iterator->new( $doc->documentElement );

    my $i = 0;

    $iterator->last();
    while ( $iterator->previousNode() )
    {
        $i++;
    }

    unless ( $i == 5 )
    {
        print "# expected 5 iterations done " . $i . "\n";
        return 0;
    }

    return 1;
}
ok( t03_loop_backward() );

sub t04_loop_forward_backward
{
    my $doc = XML::LibXML->new->parse_string($xmlstr);

    unless ( defined $doc )
    {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $iterator = XML::LibXML::Iterator->new( $doc->documentElement );

    my $i = 0;

    while ( $iterator->nextNode() )
    {
        $i++;
    }
    while ( $iterator->previousNode() )
    {
        $i++;
    }

    unless ( $i == 11 )
    {
        print "# expected 11 iterations done " . $i . "\n";
        return 0;
    }

    unless ( defined $iterator->current() )
    {
        print "# went out of scope!\n";
        return 0;
    }

    unless ( $iterator->current()->nodeName() eq "A" )
    {
        print "# expected nodeName 'A' received '"
            . $iterator->current()->nodeName() . "'\n";
        return 0;
    }

    return 1;
}
ok( t04_loop_forward_backward() );

sub t05_run_iterate
{
    my $doc = XML::LibXML->new->parse_string($xmlstr);

    unless ( defined $doc )
    {
        print "# XML string was not parsed properly\n";
        return 0;
    }

    my $iterator = XML::LibXML::Iterator->new( $doc->documentElement );

    my $i = 0;
    $iterator->iterate( sub { $i++; } );

    unless ( $i == 6 )
    {
        print "# expected 6 iterations done " . $i . "\n";
        return 0;
    }

    return 1;
}
ok( t05_run_iterate() );
