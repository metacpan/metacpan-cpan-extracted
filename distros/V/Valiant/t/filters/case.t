use Test::Lib;
use Test::Most;

{
  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'uc_first' => (is=>'ro', required=>1);
  has 'upper' => (is=>'ro', required=>1);
  has 'lower' => (is=>'ro', required=>1);
  has 'title' => (is=>'ro', required=>1);

  filters uc_first => (uc_first => 1);
  filters upper => (upper => 1);
  filters lower => (lower => 1);
  filters title => (title => 1);
}

my $user = Local::Test::User->new(
  uc_first=>'john',
  upper=>'john',
  lower=>'JOHN',
  title=>'john NAPIORKOWSKI',
);

is $user->uc_first, 'John';
is $user->upper, 'JOHN';
is $user->lower, 'john';
is $user->title, 'John Napiorkowski';

done_testing;
