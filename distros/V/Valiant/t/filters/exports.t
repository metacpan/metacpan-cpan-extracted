use Test::Lib;
use Test::Most;

{
  package Local::Test::Filter::Foo;

  use Moo;
  has ['a','b'] => (is=>'ro');

  with 'Valiant::Filter';

  sub filter {
    my ($self, $class, $attrs) = @_;
    $attrs->{name} = uc $attrs->{name};
    return $attrs;
  }

  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'name' => (is=>'ro', required=>1);
  has 'last' => (is=>'ro', required=>1);
  has 'another' => (is=>'ro', required=>1);

  filters last => (Trim=>1);

  filters_with sub {
    my ($class, $attrs, $opts) = @_;
    $attrs = +{
      map {
        my $value = $attrs->{$_};
        $value =~ s/^\s+|\s+$//g;
        $_ => $value;
      } keys %$attrs
    };
    $attrs->{name} = "$opts->{a}$attrs->{name}$opts->{b}";
    return $attrs;
  }, a=>1, b=>2;

  filters_with Foo => (a=>1,b=>2);

  filters last => (
    uc_first => 1,
    with => sub {
      my ($class, $attrs, $name) = @_;
      return $attrs->{$name} . "XXX";
    },
    sub {
      my ($class, $attrs, $name) = @_;
      return $attrs->{$name} . "AAA";
    },
  );

  filters_with 'Trim';
}

my $user = Local::Test::User->new(
  name => '  john ',
  last => '  napiorkowski  ',
  another => '  dd  '
);

is $user->name, '1JOHN2';
is $user->last, 'NapiorkowskiXXXAAA';
is $user->another, 'dd';

done_testing;
