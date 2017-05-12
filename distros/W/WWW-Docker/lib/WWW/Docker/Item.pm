package WWW::Docker::Item;
use Moose;
use namespace::autoclean;
use WWW::Docker::Item::Container;
use WWW::Docker::Item::Image;

with 'WWW::Docker::Client';

sub search {
    my ($invocant, %options) = @_;
    my $self = $invocant->new();
    return $self->get('//images/search', %options);
}

__PACKAGE__->meta->make_immutable();

1;
