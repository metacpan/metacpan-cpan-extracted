# An example of simple SAX lexical handler

package MyLexicalHandler;

sub new {
    my $type = shift;
    return bless {}, $type;
}

sub start_dtd {
    my ($self, $options) = @_;
    
    print "Starting DTD...\n";
    print "->Name: $options->{Name}\n";
    print "->PublicId: $options->{PublicId}\n";
    print "->SystemId: $options->{SystemId}\n";
}

sub end_dtd {
    my ($self, $options) = @_;
    print "Ending DTD.\n";
}

1;
