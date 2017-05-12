#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'WebService::XING::Function';
    use_ok 'WebService::XING::Function::Parameter';
}

my @required = qw(name method resource params_in);
my $f;

dies_ok { $f = WebService::XING::Function->new } 'missing required attributes';

for my $attr (@required) {
    dies_ok {
        $f = WebService::XING::Response->new(map { $_ => 1 } grep { $attr ne $_ } @required)
    } "missing attribute $attr";
}

lives_ok {
    $f = WebService::XING::Function->new(
        name => 'create_foo_bar',
        method => 'POST',
        resource => '/v1/foo/:id/bar',
        params_in => ['!mumble', '@bumble', '@!dumble', '?rumble=1'],
    );
} 'create a WebService::XING::Function object';

is "$f", 'create_foo_bar', 'stringifies correctly';

# is_deeply failed miserably here
my @expect = (
    [
        name => 'id', is_required => 1, is_placeholder => 1, is_list => 0,
        is_boolean => 0, default => undef,
    ],
    [
        name => 'mumble', is_required => 1, is_placeholder => 0, is_list => 0,
        is_boolean => 0, default => undef,
    ],
    [
        name => 'bumble', is_required => 0, is_placeholder => 0, is_list => 1,
        is_boolean => 0, default => undef,
    ],
    [
        name => 'dumble', is_required => 1, is_placeholder => 0, is_list => 1,
        is_boolean => 0, default => undef,
    ],
    [
        name => 'rumble', is_required => 0, is_placeholder => 0, is_list => 0,
        is_boolean => 1, default => 1,
    ],
);

for my $i (0 .. $#{$f->params}) {
    my $c = ($i + 1) . '. parameter';
    isa_ok $f->params->[$i], 'WebService::XING::Function::Parameter', $c;
    while (my ($key, $val) = splice @{$expect[$i]}, 0, 2) {
        if ($key =~ /^is_/) {
            if ($val eq "1") {
                ok $f->params->[$i]->$key, "$c $key";
            }
            elsif ($val eq "0") {
                ok !$f->params->[$i]->$key, "$c not $key";
            }
        }
        else {
            if (defined $val) {
                is $f->params->[$i]->$key, $val, qq{$c $key is "$val"};
            }
            else {
                is $f->params->[$i]->$key, $val, qq{$c does not have a $key};
            }
        }
    }
}

isa_ok $f->code, 'CODE', 'function code';

done_testing;
