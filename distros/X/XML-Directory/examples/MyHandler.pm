# An example of simple SAX handler

package MyHandler;

sub new {
    my $type = shift;
    return bless {}, $type;
}

sub start_document {
    my ($self, $document) = @_;
    
    print "Starting document\n";
}

sub end_document {
    my ($self, $document) = @_;
    
    print "Ending document\n";
    return 1;
}

sub start_element {
    my ($self, $element) = @_;
    
    print "<$element->{Name} ";
#   print "xmlns:$element->{Prefix}=\"$element->{NamespaceURI}\" ";
    foreach (keys %{$element->{Attributes}}) {
#   SAX2 way
    print "$element->{Attributes}->{$_}->{Name}=\"$element->{Attributes}->{$_}->{Value}\" ";
#   SAX1 alternative way
#   print "$_=\"$element->{Attributes}->{$_}\" ";
    }
    print ">\n";
}

sub end_element {
    my ($self, $element) = @_;
    
    print "</$element->{Name}>\n";
}

sub characters {
    my ($self, $characters) = @_;
    
    print "$characters->{Data}\n";
}

1;
