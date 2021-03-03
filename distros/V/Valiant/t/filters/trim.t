use Test::Lib;
use Test::Most;

{
  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'name' => (is=>'ro', required=>1);

  filters name => (
    trim =>  1,
  );
}

my $user = Local::Test::User->new(name=>'  john    ');

is $user->name, 'john';

done_testing;
