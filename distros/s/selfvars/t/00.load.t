use Test::More tests => 1;

BEGIN {
    use_ok('selfvars');
}

diag("Testing selfvars $selfvars::VERSION");
