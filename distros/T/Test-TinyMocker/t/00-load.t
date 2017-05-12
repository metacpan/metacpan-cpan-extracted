use Test::More tests => 1;

BEGIN {
    use_ok('Test::TinyMocker') || print "Bail out!
";
}

diag("Testing Test::TinyMocker $Test::TinyMocker::VERSION, Perl $], $^X");
