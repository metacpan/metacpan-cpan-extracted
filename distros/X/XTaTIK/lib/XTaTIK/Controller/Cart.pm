package XTaTIK::Controller::Cart;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base 'Mojolicious::Controller';
use XTaTIK::Common qw/n_to_br  set_product_pic/;
use experimental 'postderef';

sub index {
    my $self = shift;

    my %items = $self->cart->all_items_cart_quote_kv;
    for ( $items{cart}->@*, $items{quote}->@*) {
        set_product_pic( $self, @$_{qw/image number/} );
    }
    $self->stash( %items );
};

sub add {
    my $self = shift;

    my $p = $self->cart
        ->add( $self->param('quantity'), $self->param('number') );

    $self->cart_dollars('refresh'); $self->cart_cents('refresh');
    $self->cart->save;
    $self->stash(
        number    => $self->param('number'),
        quantity  => $self->param('quantity'),
        is_quote  => $p->{price}//-1 == -1 ? 1 : 0,
        return_to => $self->req->headers->referrer || '/products',
    );
};





1;
