package Type::Guess::Role::Date;

use Mojo::Base -role;

around '_type' => sub {
    my $orig = shift;
    my $ret = $orig->(@_);
    return $ret;
};

1;
