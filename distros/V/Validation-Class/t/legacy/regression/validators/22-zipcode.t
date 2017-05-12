use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        address_zipcode => {zipcode => 1}
    }
);

sub should_fail {
    my ($name, @zipcodes) = @_;
    for (@zipcodes) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @zipcodes) = @_;
    for (@zipcodes) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad zip-codes';
should_fail 'address_zipcode' => qw(
    00000-00
    12345-12
    12345-67
    111114321
    22030-123
);

diag 'validating good zip-codes';
should_pass 'address_zipcode' => qw(
    00000
    00000-0000
    90036
    80954
    75501
    01003
    10003
    22030
    30303
    41876
    55413
    60666
    22030-5565
    22030-1111
);

done_testing;
