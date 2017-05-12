use strict;
use warnings;

use Validate::Tiny ':all';
use Test::More;

my $rules = {
    fields  => ['a'],
    filters => [ a => filter('strip') ]
};

my $res = validate({a => undef}, $rules);
is $res->{a}, undef;

for ('a b', 'a  b', 'a   b') {
    my $res = validate({ a => $_ }, $rules);
    is $res->{data}->{a}, 'a b', "OK for $_ [space]";
}

for ("a\nb", "a\n\nb", "a\n\n\nb") {
    my $res = validate({ a => $_ }, $rules);
    is $res->{data}->{a}, "a\nb", "OK for $_ [new line]";
}

for ("a\rb", "a\r\rb", "a\r\r\rb") {
    my $res = validate({ a => $_ }, $rules);
    is $res->{data}->{a}, "a\rb", "OK for $_ [line feed]";
}

done_testing;
