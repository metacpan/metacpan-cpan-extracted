use Test::Lib;
use Test::Most;

{
  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'name' => (is=>'ro', required=>1);

  filters name => (
    html_escape =>  1,
  );
}

my $user = Local::Test::User->new(name=>'<a>john</a>');

is $user->name, '&lt;a&gt;john&lt;/a&gt;';

done_testing;
