#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PATH} }

use Test::More tests => 2 * 7;

use Test::Valgrind::Suppressions;

my @Z_tests = (
 [ 'malloc'            => 'malloc', 'not encoded' ],
 [ '_vgrZU_VG_Z_dongs' => qr/Symbol with a "VG_Z_" prefix is invalid/, 'VG_Z' ],
 [ '_vgrZU_dongs'      => qr/Symbol doesn't contain a function name/,
                                                           'no function name' ],
 [ '_vgrZU_libcZdsoZa_malloc'   => 'malloc',   'soname encoded' ],
 [ '_vgrZU_libcZdsoZa_arZZZAel' => 'arZZZAel', 'soname encoded 2' ],
 [ '_vgrZZ_libcZdsoZa_arZZZAel' => 'arZ@el',   'function name encoded' ],
 [ '_vgrZZ_libcZdsoZa_arZdZXZa' => qr/Invalid escape sequence/,
                                         'function name with invalid escapes' ],
);

for (@Z_tests) {
 my ($sym, $exp, $desc) = @$_;
 my $res = eval { Test::Valgrind::Suppressions->maybe_z_demangle($sym) };
 if (ref $exp) {
  like $@,   $exp,  "$desc croaks as expected";
  is   $res, undef, $desc;
 } else {
  is $@,   '',   "$desc does not croak as expected";
  is $res, $exp, $desc;
 }
}
