use Text::Names qw(weakenings);
use Test::More;
use Data::Dumper;

my ($warnings, @weakenings) = weakenings("David J. R.", "Bourget");
ok($#warnings == -1);
ok($#weakenings == 7);

done_testing;
