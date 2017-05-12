use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        scheduled_time => {time => 1}
    }
);

sub should_fail {
    my ($name, @times) = @_;
    for (@times) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @times) = @_;
    for (@times) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad times';
should_fail 'scheduled_time' => qw(
    aa
    AA
    ab
    Ab
    25
    30
    -14
    3000
    24
    2499
    2399
    2360
    4321
    3:000
    30:00
    :23
    23:
    24:99
    23:99
    23:60
    43:21
);

diag 'validating good times';
should_pass 'scheduled_time' => (
    '23:59',
    '00',
    '00:00',
    '11:11',
    '12:34',
    '11:11 am',
    '11:11 AM',
    '11:11AM',
    '11:11PM',
    '11:11 PM',
    '11:11 pm',
);

done_testing;
