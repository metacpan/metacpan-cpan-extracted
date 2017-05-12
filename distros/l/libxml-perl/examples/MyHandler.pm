# This is the example module in doc/UsingPerlSAX.pod

package MyHandler;

sub new {
    my ($type) = @_;
    return bless {}, $type;
}

sub start_element {
    my ($self, $element) = @_;

    print "Start element: $element->{Name}\n";
}

sub end_element {
    my ($self, $element) = @_;

    print "End element: $element->{Name}\n";
}

1;
