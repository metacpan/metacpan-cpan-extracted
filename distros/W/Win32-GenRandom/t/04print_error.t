use strict;
use warnings;
use Win32::GenRandom qw(:all);

use Test::More;
use Test::Warn;

warnings_like {error_test()} qr/specified module|angegebene Modul|найден указанный|\x8e\x77\x92\xe8\x82\xb3\x82\xea\x82\xbd\x83\x82\x83\x57\x83\x85\x81\x5b\x83\x8b/i, 'error test emits expected warning';

sub error_test {
  is(Win32::GenRandom::_error_test(), 42, '_error_test() returns 42');
}

done_testing();

# Should emit warning:
# The specified module could not be found at ....
# Das angegebene Modul wurde nicht gefunden at ....
# Ќе найден указанный модуль at ....
# siteisareta mozyuru ga mitukarimasen. at ....
