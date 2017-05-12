package XML::Filter::Chucker;
use strict;
use warnings;
use base 'XML::SAX::Base';
use XML::SAX::Exception;

sub new {
    my ($pkg, $when) = @_;
    my $self = $pkg->SUPER::new();
    $self->{when} = $when;
    return $self;
}

sub start_element {
    my $self = shift;
    my $data = shift;
    if ($data->{LocalName} eq $self->{when}) {
        XML::SAX::Exception->throw(Message => "Found a <$self->{when}>!");
    }
    return $self->SUPER::start_element($data);
}

1;
