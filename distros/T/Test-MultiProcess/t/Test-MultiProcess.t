use Test::More tests => 3;
use Data::Dumper;

BEGIN { use_ok('Test::MultiProcess') };

## just test 10 forked processes

my $results1 = run_forked(
    code => sub { return "hi"; },
    forks => 10
);

is($$results1{hi}, 10, "10 forks");

## 20

my $results2 = run_forked(
    code => sub { return "hi"; },
    forks => 20
);

is($$results2{hi}, 20, "20 forks");

