use t::TestLess tests => 1;

my $tl = test_less_new;

is ref($tl), 'Test::Less';
