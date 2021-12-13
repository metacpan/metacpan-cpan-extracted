package Web::MarketReceipt::Order;
use Mouse;
use Mouse::Util::TypeConstraints;
use utf8;

enum 'OrderState'       => qw/purchased canceled refunded expired pending/;
enum 'OrderEnvironment' => qw/Sandbox Production/;

has product_identifier => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has unique_identifier => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has purchased_epoch => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has state => (
    is  => 'ro',
    isa => 'OrderState',
    required => 1,
);

has quantity => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has environment => (
    is       => 'ro',
    isa      => 'OrderEnvironment',
    required => 1,
);

no Mouse;

sub dump {
    my $self = shift;
    +{
        (map {($_ => $self->$_)}
            qw/product_identifier unique_identifier purchased_epoch state quantity environment/)
    };
}

1;
