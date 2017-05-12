use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        payment_amount => {decimal => 1}
    }
);

sub should_fail {
    my ($name, @amounts) = @_;
    for (@amounts) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @amounts) = @_;
    for (@amounts) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad decimals';
should_fail 'payment_amount' => qw(
    12345 54321
);

diag 'validating good decimals';
should_pass 'payment_amount' => qw(
    123.45 543.21
);

done_testing;
