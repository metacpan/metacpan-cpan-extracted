use 5.016000;
use Test::Expectation;
use Test::More;

{
    package BankAccount;
    sub new {
        my ($class, $amount) = @_;
        bless \$amount, $class;
    }
    sub transfer {
        my ($self, $amount, $other) = @_;
        $$self  -= $amount;
        $$other += $amount;
    }
    sub balance {
        my $self = shift;
        return $$self;
    }
}

it_is_a 'BankAccount';

it_should 'withdrawals amount from the source account' => sub {
    my $source = BankAccount->new(100);
    my $target = BankAccount->new(0);
    $source->transfer( 50, $target );
    is( $source->balance, 50 );
};
it_should 'deposits amount into target account' => sub {
    my $source = BankAccount->new(100);
    my $target = BankAccount->new(0);
    $source->transfer( 50, $target );
    is( $target->balance, 50 );
};
