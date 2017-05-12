use Test::More tests => 2;
use Test::Kwalitee::Extra qw(:no_plan !:core !:optional has_manifest);
ok(Test::Builder->new->current_test == 1);
