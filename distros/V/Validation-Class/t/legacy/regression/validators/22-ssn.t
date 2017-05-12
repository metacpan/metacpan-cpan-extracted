use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        user_ssn => {ssn => 1}
    }
);

sub should_fail {
    my ($name, @ssns) = @_;
    for (@ssns) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @ssns) = @_;
    for (@ssns) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad social security numbers';
should_fail 'user_ssn' => qw(
    000000000
    111111111
    123456789
    000-00-0000
    203-303-698
    203-303-6988
);

diag 'validating good social security numbers';
should_pass 'user_ssn' => qw(
    203-00-6988
    987-65-4321
    001-11-1111
    211-10-1234
    209-20-1811
    207-65-9878
    303-17-2345
    416-33-0693
);

done_testing;
