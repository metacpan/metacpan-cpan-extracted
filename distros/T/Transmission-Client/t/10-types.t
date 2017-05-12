# ex:ts=4:sw=4:sts=4:et
# Tests for helper functions in Transmission::Types
use warnings;
use strict;
use Test::More tests => 11;
use Transmission::Types;

ok  Transmission::Types::_is_num(10), '_is_num(10)';
ok  Transmission::Types::_is_num(10.0), '_is_num(10.0)';
ok !Transmission::Types::_is_num("foo"), 'not _is_num("foo")';
ok !Transmission::Types::_is_num("10.0"), 'not _is_num("10.0")';

is Transmission::Types::_coerce_num("10"), 10,
   'coerced numeric str "10" should become 10';
is Transmission::Types::_coerce_num("10.1"), 10.1,
   'coerced numeric str "10.1" should become 10.1';
is Transmission::Types::_coerce_num("foo"), -1,
   'coerced non-numeric str "foo" should become -1';

ok Transmission::Types::_is_num(Transmission::Types::_coerce_num("10")),
   'coerced numeric str should become num';
ok Transmission::Types::_is_num(Transmission::Types::_coerce_num(10)),
   'coerced integer should still be num';
ok Transmission::Types::_is_num(Transmission::Types::_coerce_num(10.0)),
   'coerced double should still be num';
ok Transmission::Types::_is_num(Transmission::Types::_coerce_num("foo")),
   'coerced non-numeric str "foo" should become num';
