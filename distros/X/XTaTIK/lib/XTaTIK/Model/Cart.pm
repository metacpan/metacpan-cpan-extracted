package XTaTIK::Model::Cart;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base -base;
use XTaTIK::Model::Products;
use XTaTIK::Model::Quote;
use Mojo::Pg;
use JSON::Meth;

use experimental 'postderef';

my $Blank_Cart_Data = {
    contents => [],
    total    => '0.00',
};

has [qw/
    pg  products  id   contents  total  dollars  cents
    _is_modified
/];

sub new_cart {
    my $self = shift;

    $self->id(
        $self->pg->db->query(
            'INSERT INTO carts (created_on, data)
                    VALUES (?, ?)
                RETURNING id',
            time(),
            $Blank_Cart_Data->$j,
        )->hash->{id}
    );

    # This is needed, for when we swap carts
    $self->contents([]);
    $self->_recalculate_total;

    return $self->id;
}

sub all_items {
    my $self = shift;

    my @contents = @{ $self->contents };
    my @products = $self->products->get_by_number(map $_->{n}, @contents);

    my %quantities;
    $quantities{ $_->{n} } = $_->{q} for @contents;
    $_->{quantity} = $quantities{ $_->{number} } for @products;

    return \@products;
}

sub all_items_cart_quote {
    my $self = shift;
    my ( @cart, @quote );
    $_->{price} == -1 ? push @quote, $_ : push @cart, $_
        for $self->all_items->@*;

    return \@cart, \@quote;
}

sub all_items_cart_quote_kv {
    my $self = shift;
    my ( $cart, $quote ) = $self->all_items_cart_quote;
    return ( cart => $cart, quote => $quote );
}

sub alter_quantity {
    my ( $self, $num, $qty ) = @_;

    return $self->remove($num)
        if $qty <= 0;

    for ( @{ $self->contents } ) {
        next unless $_->{n} eq $num;
        $_->{q} = $qty;
        $self->_recalculate_total;
        return;
    }
}

sub remove {
    my ( $self, $num ) = @_;
    @{ $self->contents } = grep $_->{n} ne $num, @{ $self->contents };
    $self->_recalculate_total;
    return;
}

sub add {
    my ( $self, $quantity, $number ) = @_;

    my $product = $self->products->get_by_number( $number )
        or return;

    my $added = 0;
    for ( @{ $self->contents } ) {
        if ( $_->{n} eq $product->{number} ) {
            $added = 1;
            $_->{q} += $quantity;
            last;
        }
    }

    $added or push @{ $self->contents }, +{
        n   => $number,
        q   => $quantity,
        p   => $product->{'price'},
    };

    $self->_recalculate_total;
    return $product;
}

sub load {
    my $self = shift;

    my $id = $self->id
        or die "MISSING CART ID on load";

    my $cart_row = $self->pg->db->query(
        'SELECT * FROM "carts" WHERE "id" = ?',
        $id,
    )->hash;

    my $cart = eval { $cart_row->{data}->$j } // $Blank_Cart_Data->$j->$j;

    $self->contents( $cart->{contents} );
    $self->_recalculate_total;

    return 1;
}

sub submit {
    my $self = shift;
    my %customer_data = @_;

    my $id = $self->id or die "MISSING CART ID on submit";

    my @quote_products = map +{ q => $_->{q}, n => $_->{n}, },
        grep $_->{price}//-1 == -1, $self->contents->@*;
    return unless @quote_products;

    $quote_products[$_]{o} = $_ for 0 .. $#quote_products;

    my $quote = XTaTIK::Model::Quote->new( pg => $self->pg );
    $quote->new_quote( $id )->contents(\@quote_products);
    $quote->$_( $customer_data{$_} ) for keys %customer_data;
    $quote->save;
    return 1;
}

sub save {
    my $self = shift;

    return unless $self->_is_modified;

    my $id = $self->id or die "MISSING CART ID on save";

    $self->pg->db->query(
        'UPDATE "carts" SET "data" = ? WHERE "id" = ?',
        {
            contents    => $self->contents,
            total       => $self->total,
        }->$j,
        $id,
    );

    return 1;
}


sub _recalculate_total {
    my $self = shift;

    my $total = 0;
    $total += $_->{p} * $_->{q}
        for grep $_->{p} > 0, @{ $self->contents };

    $self->_is_modified( 1 );

    $total = sprintf '%.2f', $total;
    $self->total( $total );
    $self->dollars( (split /\./, $total)[0] );
    $self->cents(   (split /\./, $total)[1] );
    return $self->total;
}


1;

__END__

CREATE TABLE carts (
    id            SERIAL PRIMARY KEY,
    created_on INT,
    data TEXT
);


