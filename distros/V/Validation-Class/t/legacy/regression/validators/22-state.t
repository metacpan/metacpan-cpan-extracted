use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        address_state => {state => 1}
    }
);

sub should_fail {
    my ($name, @states) = @_;
    for (@states) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @states) = @_;
    for (@states) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad states';
should_fail 'address_state' => qw(
    zz
    xx
    XX
    a
    w
    do
    fu
    FU
    F.U.
    prison
    nowhere
    jail
    hole
    heaven
    hell
    PURGATORY
    Goergia
    goergia
);

diag 'validating good states';
should_pass 'address_state' => (
    'VA',
    'va',
    'PA',
    'pa',
    'GA',
    'ga',
    'CA',
    'ca',
    'MA',
    'ma',
    'VIRGINIA',
    'Virginia',
    'virginia',
    'Pennsylvania',
    'pennsylvania',
    'Georgia',
    'georgia',
    'California',
    'california',
    'Massachusetts',
    'massachusetts',
    'DC',
    'District of Columbia',
    'Washington',
    'washington',
    'WASHINGTON'

);

done_testing;
