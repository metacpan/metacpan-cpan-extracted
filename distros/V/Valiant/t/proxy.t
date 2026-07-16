use Test::Most;
use Valiant::Proxy::Object;

{
  package Local::Test::User;

  use Moo;

  has ['name', 'age', 'is_active'],
    is=>'ro',
    required=>1;
}

{
  ok my $validator = Valiant::Proxy::Object->new();
  ok my $user = Local::Test::User->new(name=>'xxxxxxxxxxxxxsJohn', age=>15, is_active=>1);

  $validator
    ->validates_with(sub { unless($_[0]->is_active) { $_[0]->errors->add(_base=>'Cannot change inactive user') } })
    ->validates(name => length => [2,15], format => qr/[a-zA-Z ]+/ );

  my $result = $validator->validate($user);

  is_deeply +{ $result->errors->to_hash(1) },
    {
      "name" =>
        [
          "Name is too long (maximum is 15 characters)",
        ]
    };
}

ok my $validator = Valiant::Proxy::Object->new(
  validations => [
    sub { unless($_[0]->is_active) { $_[0]->errors->add(undef, 'Cannot change inactive user') } },
    [ name => length => [2,15], format => qr/[a-zA-Z ]+/ ],
    [ age => numericality => 'positive_integer' ],
  ]
);

{
  ok my $user = Local::Test::User->new(name=>'John', age=>15, is_active=>1);
  ok my $result = $validator->validate($user);
  ok $result->valid;
}

{
  ok my $user = Local::Test::User->new(name=>'01', age=>-15, is_active=>0);
  ok my $result = $validator->validate($user);
  ok $result->invalid;
  is_deeply +{ $result->errors->to_hash(full_messages=>1) },
    {
      '*' => [
                   'Cannot change inactive user'
                 ],
      'age' => [
                 'Age must be a positive integer'
               ],
      'name' => [
                  'Name does not match the required pattern'
                ] 
    };
}

{
  # AUTOLOAD delegates known methods to the wrapped object, and now fails
  # loudly on unknown ones (previously returned undef silently)
  ok my $proxy = Valiant::Proxy::Object->new(validations => []);
  ok my $user = Local::Test::User->new(name=>'John', age=>15, is_active=>1);
  ok my $result = $proxy->validate($user);

  is $result->is_active, 1, 'known method delegates through AUTOLOAD';
  throws_ok { $result->no_such_method } qr/no_such_method/,
    'unknown delegated method fails loudly';
}

done_testing;

