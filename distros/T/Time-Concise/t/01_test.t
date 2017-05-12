BEGIN {
    use Test::More tests => 5;
    use_ok 'Time::Concise';
}

ok from_concise("5y4d3h2m1s") == 158141171;
ok   to_concise( 158141171  ) eq "5y4d3h2m1s";
ok ! defined from_concise "foo bar";
ok ! defined   to_concise "foo bar";
