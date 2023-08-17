use Test::Most;
use Valiant::JSON::JSONBuilder;

# SYNOPSIS
{
  package Local::Test::User;

  use Moo;

  has username => (is=>'ro');
  has active => (is=>'ro');
  has age => (is=>'ro');
}

ok my $user = Local::Test::User->new(
  username => 'bob',
  active => 1,
  age => 42,
);

{
  my $jb = Valiant::JSON::JSONBuilder->new(model=>$user);

  is_deeply $jb->string('username')
    ->boolean('active')
    ->number('age')
    ->render_perl, +{
      local_test_user => {
      username => 'bob',
      active => 1,
      age => 42,
    }};
}

{
  my $jb = Valiant::JSON::JSONBuilder->new(model=>$user, namespace=>'');

  is_deeply $jb->string('username')
    ->boolean('active')
    ->number('age')
    ->render_perl, +{
      username => 'bob',
      active => 1,
      age => 42,
    };
}

{
  {
    package Local::Test::List;
    use Moo;

    has numbers => (is=>'ro');
  }

  my $list_of_numbers = Local::Test::List->new(numbers=>[1,2,3]);
  my $jb = Valiant::JSON::JSONBuilder->new(model=>$list_of_numbers);
  my $perl = $jb->array([1,2,3], {namespace=>'numbers'}, sub {
    my ($jb, $item) = @_;
    $jb->value($item);
  })->render_perl;

  is_deeply $perl, +{
  local_test_list => {
    numbers => [
      1,
      2,
      3,
    ],
  },
};
}

done_testing