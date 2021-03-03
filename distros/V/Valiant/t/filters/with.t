use Test::Lib;
use Test::Most;

{

  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'name' => (is=>'ro', required=>1);

  filters name => (
    with => {
      cb => sub {
        my ($class, $attrs, $name, $opts) = @_;
        return $attrs->{$name}.$opts->{a};
      },
      opts => +{ a=>'foo' },
    },
    with => sub {
        my ($class, $attrs, $name) = @_;
        return $attrs->{$name}.'bar';
    },
    with => [sub {
        my ($class, $attrs, $name, $opts) = @_;
        return $attrs->{$name}.$opts;
    }, 'baz'],


  )
}

my $user = Local::Test::User->new(name=>'john');

is $user->name, 'johnfoobarbaz';

done_testing;
