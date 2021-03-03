use Test::Lib;
use Test::Most;

{
  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'age' => (is=>'ro', required=>1);

  filters age => (
    numberize =>  1,
  );
}

my $user1 = Local::Test::User->new(age=>'25');
is $user1->age, 25;
my $user2 = Local::Test::User->new(age=>'a25sdfsdfs');
is $user2->age, 0;
my $user3 = Local::Test::User->new(age=>'25sdfsdfs');
is $user3->age, 25;

done_testing;
