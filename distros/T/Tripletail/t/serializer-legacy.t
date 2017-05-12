# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;
use Tripletail qw(/dev/null);

my $ser;
lives_ok {
    $ser = $TL->newSerializer({-type => 'legacy'});
};
isa_ok $ser, 'Tripletail::Serializer::Legacy';

lives_and {
    my $val = {a => -5000, b => ['bar', 'baz'], c => 3.1415};
    is_deeply $ser->deserialize($ser->serialize($val)), $val;
};
