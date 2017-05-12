use Test::More;
use warnings::pedantic;

eval <<'EOP';
use warnings FATAL => 'pedantic';
grep /42/, 1, 2, 3;
();
EOP

like(
    $@,
    qr/Unusual use of grep/,
    "fatalized pedantic category"
);

eval <<'EOP';
use warnings FATAL => 'void_grep';
grep /42/, 1, 2, 3;
();
EOP

like(
    $@,
    qr/Unusual use of grep/,
    "fatalized pedantic category"
);

eval <<'EOP';
use warnings FATAL => 'pedantic';
sub foo (&$) {1}
sort foo @INC;
EOP

like(
    $@,
    qr/\QSubroutine main::foo() used as first argument to sort, but has a &\E\$ prototype/,
    "fatalized pedantic category, sort"
);



done_testing;
