use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        domain_name => {hostname => 1}
    }
);

sub should_fail {
    my ($name, @domains) = @_;
    for (@domains) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @domains) = @_;
    for (@domains) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad hostnames';
should_fail 'domain_name' => (
    '.example.com',
    'Abc.example.',
    'Abc..example.com',
    'A~b~c~example.com',
    'a#b[j\k]example.com',
    'just"not"right.example.com',
    'this!is.example.com',
    'this is.example.com',
    'this\ still\"not\\allowed.example.com',
);

diag 'validating good hostnames';
should_pass 'domain_name' => qw(
    example.com
    cpan.org
    us.gov
);

done_testing;
