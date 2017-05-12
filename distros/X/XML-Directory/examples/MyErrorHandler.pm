# An example of simple SAX error handler
# XML::Directory throws fatal errors only

package MyErrorHandler;

sub new {
    my $type = shift;
    return bless {}, $type;
}

sub warning {
    my ($self, $exception) = @_;
    
    print "Warning: $exception->{Message}\n";
}

sub error {
    my ($self, $exception) = @_;
    
    print "Error: $exception->{Message}\n";
}

sub fatal_error {
    my ($self, $exception) = @_;
    
    print "Fatal Error: $exception->{Message}\n";
}

1;
