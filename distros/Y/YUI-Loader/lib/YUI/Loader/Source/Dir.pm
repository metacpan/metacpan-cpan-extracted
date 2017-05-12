package YUI::Loader::Source::Dir;

use Moose;
extends qw/YUI::Loader::Source/;

use Path::Class;
use YUI::Loader::Carp;

has base => qw/is ro/;

sub BUILD {
    my $self = shift;
    my $given = shift;
    my $base = $self->base || $given->{dir} or croak "Don't have a base dir";
    $self->{base} = Path::Class::Dir->new($base);
}

override file => sub {
    my $self = shift;
    my $item = shift;
    my $filter = shift;

    $item = $self->catalog->item($item);
    return $self->base->file($item->file($filter));
};

1;
