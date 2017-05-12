package # hide from PAUSE
    Local::TOH;

use parent qw(Tree::ObjectXS::Hash);

sub id {
    my $self = shift;
    $self->{id} = $_[0] if @_;
    $self->{id};
}

1;
