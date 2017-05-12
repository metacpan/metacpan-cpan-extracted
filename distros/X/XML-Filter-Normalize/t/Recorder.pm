#
# A small utility SAX handler to record an event stream.
#
# @(#) $Id: Recorder.pm 1013 2005-10-19 08:24:04Z dom $

package Recorder;

sub new {
    my $class = shift;
    return bless [], $class;
}

sub get_events {
    my $self = shift;
    return @$self;
}

my @methods = qw(
    start_document
    end_document
    start_prefix_mapping
    end_prefix_mapping
    characters
    start_element
    end_element
);

# Make each method record the name of the event and the data that got
# sent.
foreach my $method ( @methods ) {
    no strict 'refs';
    *{ __PACKAGE__ . '::' . $method } = sub {
        my $self = shift;
        push @$self, [ $method, $_[0] ];
        return;
    };
}

1;
__END__
