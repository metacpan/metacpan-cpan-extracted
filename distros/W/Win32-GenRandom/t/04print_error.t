use strict;
use warnings;
use Win32::GenRandom qw(:all);

use Test::More;
use Test::Warn;

warnings_like {error_test()} qr/specified module|angegebene Modul|найден указанный/i, 'error test emits expected warning';

sub error_test {
  is(Win32::GenRandom::_error_test(), 42, '_error_test() returns 42');
}

done_testing();

# Should emit warning:
# The specified module could not be found at ....
# Das angegebene Modul wurde nicht gefunden at ....
# Ќе найден указанный модуль at ....
