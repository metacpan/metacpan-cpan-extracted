use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $s = Validation::Class::Simple->new(
    fields => {
        user_uuid => {uuid => 1}
    }
);

sub should_fail {
    my ($name, @ids) = @_;
    for (@ids) {
        $s->params->{$name} = $_;
        ok !$s->validate($name), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @ids) = @_;
    for (@ids) {
        $s->params->{$name} = $_;
        ok $s->validate($name), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad uuids';
should_fail 'user_uuid' => qw(
    0000A0000AA000B0B00AA00AAA0BB000
    00000000-0000-0000-0000
    0000-0000-0000-000000000000
    00000000-0000-000000000000
);

diag 'validating good uuids';
should_pass 'user_uuid' => qw(
    00000000-0000-0000-0000-000000000000
    4162F712-1DD2-11B2-B17E-C09EFE1DC403
    4162F712-1DD2-11B2-B17E-C09EFE1DC403
);

done_testing;
