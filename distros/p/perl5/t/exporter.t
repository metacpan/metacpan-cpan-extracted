use lib (-e 't' ? 't' : 'test') . '/lib';

use Test::More 0.88;

{
    package test1;
    use TestExporter;
}

{
    package test2;
    use perl5-texp;
}

ok defined(&test1::foo),
    "basic sanity check: TestExporter does export when use'd normally";

ok defined(&test2::foo),
    "ExportTester exports when use'd via perl5";

done_testing;
