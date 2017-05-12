use strict;
use Test::More tests => 4;
use URI::Escape::JavaScript qw(escape);

ok(escape('Boofy') eq 'Boofy', 'US-ASCII');
ok(escape('(^o^)/') eq '%28%5Eo%5E%29/', 'Legacy Escaping for some symbols');
ok(escape("\x{30d0}\x{30bd}\x{30ad}\x{30e4}") eq '%u30D0%u30BD%u30AD%u30E4', 'Asian Characters');
ok(escape("KCatch! KCatch! \x{305d}\x{308c} Boofy(ry Plagger\x{3067}\x{3069}\x{3046}\x{3084}\x{308b}\x{304b}\x{306f}\x{ff4b}(ry") eq 'KCatch%21%20KCatch%21%20%u305D%u308C%20Boofy%28ry%20Plagger%u3067%u3069%u3046%u3084%u308B%u304B%u306F%uFF4B%28ry', 'mixed');
