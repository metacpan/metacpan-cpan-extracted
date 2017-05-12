# -*- perl -*-

use strict;


package XML::EP::Response;

$XML::EP::Response = '0.01';

sub new {
    my $proto = shift;
    my $self = { @_ == 1 ? %{shift()} : @_ };
    bless($self, (ref($proto) || $proto))
}

sub ContentType {
    my $self = shift;
    @_ ? ($self->{'content-type'} = shift) : $self->{'content-type'};
}

sub Headers {
    my $self = shift;
    "content-type: " . $self->ContentType() . "\n\n";
}
