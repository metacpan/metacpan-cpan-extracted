package YUI::Loader::Source::URI;

use Moose;
extends qw/YUI::Loader::Source/;

use URI;
use Scalar::Util qw/blessed/;

has base => qw/is ro required 1/;

sub BUILD {
    my $self = shift;
    my $given = shift;
    my $base = $given->{base};
    $base = URI->new("$base") unless blessed $base && $base->isa("URI");
}

override uri => sub {
    my $self = shift;
    my $item = shift;
    my $filter = shift;

    $item = $self->catalog->item($item);
    return $item->file_uri($self->base, $filter);
};

1;
