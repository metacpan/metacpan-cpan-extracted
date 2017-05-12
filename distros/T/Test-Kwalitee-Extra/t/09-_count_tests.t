use Test::More tests => 1;

require Test::Kwalitee::Extra;
*Test::Kwalitee::Extra::_do_test = sub { is(Test::Kwalitee::Extra::_count_tests(@_), 2, 'regression gh-13'); };
Test::Kwalitee::Extra->import(qw(:no_plan !:core !:optional prereq_matches_use build_prereq_matches_use));

