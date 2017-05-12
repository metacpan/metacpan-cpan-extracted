use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        date_created => {date => 'mdy'}
    }
);

sub should_fail {
    my ($name, @dates) = @_;
    for (@dates) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @dates) = @_;
    for (@dates) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad dates';
should_fail 'date_created' => qw(
    00/00/0000 11/11/1111 123456
);

diag 'validating good dates';
should_pass 'date_created' => qw(
    01/01/1980 12/29/2020
);

done_testing;
