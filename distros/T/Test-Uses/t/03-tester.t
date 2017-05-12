use Test::Tester tests => 28;

use Test::Uses;

check_test(
    sub {
        uses_ok('t/data/test1.pmd', 'strict', "This test file uses strict");
    },
    {
      ok => 1, # expect this to pass
      name => "This test file uses strict",
      diag => "",
    },
    "uses strict"
);

check_test(
    sub {
        uses_ok('t/data/test1.pmd', 'autodie', "This test file uses autodie");
    },
    {
        ok => 0, # expect this to fail
        name => "This test file uses autodie",
        diag => "t/data/test1.pmd was missing: autodie",
    },
    "uses autodie"
);

check_test(
    sub {
        uses_ok('t/data/test1.pmd', {-uses => ['autodie'], -avoids => ['vars', qr/^Win32::*/]}, "This test file uses autodie and avoids vars and Win32::*");
    },
    {
        ok => 0, # expect this to fail
        name => "This test file uses autodie and avoids vars and Win32::*",
        diag => "t/data/test1.pmd was missing: autodie\nt/data/test1.pmd contained: vars",
    },
    "uses autodie, avoids vars, Win32::*"
);

check_test(
    sub {
        avoids_ok('t/data/test1.pmd', ['strict', 'warnings'], "This test file avoids strict and warnings");
    },
    {
        ok => 0, # expect this to fail
        name => "This test file avoids strict and warnings",
        diag => "t/data/test1.pmd contained: strict, warnings",
    },
    "avoids strict, warnings"
);

1;