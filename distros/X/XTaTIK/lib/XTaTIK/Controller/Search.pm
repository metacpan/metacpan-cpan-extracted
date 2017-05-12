package XTaTIK::Controller::Search;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base 'Mojolicious::Controller';
use XTaTIK::Common qw/n_to_br  set_product_pic/;

sub search {
    my $self = shift;

    my @prods = $self->products->get_by_id(
        $self->product_search->search( $self->param('term') )
    );

    set_product_pic( $self, @$_{qw/image number/} ) for @prods;

    $self->stash(
        template => 'root/search',
        products => \@prods,
    );
}

1;

__END__