
use strict;
use warnings;

use Validate::Tiny ':all';
use Test::More;

$Validate::Tiny::FILTERS{only_digits} = sub {
    my $val = shift;
    return unless defined $val;
    $val =~ s/\D//g;
    return $val;
};

my $rules = {
    fields  => ['a'],
    filters => [ a => filter('trim', 'only_digits') ]
};

my $res = validate({a => undef}, $rules);
is $res->{a}, undef;

$res = validate({ a => " abc123 " }, $rules);
is $res->{data}->{a}, '123';


done_testing;

