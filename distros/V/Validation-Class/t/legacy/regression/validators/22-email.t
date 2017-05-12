use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        email_address => {email => 1}
    }
);

sub should_fail {
    my ($name, @emails) = @_;
    for (@emails) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @emails) = @_;
    for (@emails) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad emails';
should_fail 'email_address' => (
    'Abc.example.com',
    'Abc.@example.com',
    'Abc..123@example.com',
    'A@b@c@example.com',
    'a"b(c)d,e:f;g<h>i[j\k]l@example.com',
    'just"not"right@example.com',
    'this#is"not\allowed@example.com',
    'this is"not\allowed@example.com',
    'this\ still\"not\\allowed@example.com',
);

diag 'validating good emails';
should_pass 'email_address' => qw(
    awncorp@cpan.org
);

done_testing;
