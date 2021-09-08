use Test::Most;

{
  package Local::Profile;

  use Moo;
  use Valiant::Params;

  has address => (is=>'ro');
  has city => (is=>'ro');
  has zip => (is=>'ro');

  package Local::Role;

  use Moo;
  use Valiant::Params;
  use Types::Standard 'Enum';

  has label => (
    is=>'ro', 
    isa=>Enum['user', 'admin'],
  );

  package Local::Person;

  use Moo;
  use Valiant::Params;

  has full_name => ( is=>'ro' );
  has age => ( is=>'ro' );
  has email => ( is=>'ro' );
  has profile => ( is=>'ro' );
  has roles => ( is=>'ro' );

  param full_name => ( name=>'full-name' );
  param email => ( multi=>1 );
  param profile => ( expand=>1 );
  param role => ( multi=>1, expand=>1 );
}

my %form_params_request => (
  'full_name' => 'John Napiorkowski',
  'age' => 52,
  'email' => 'jjn1056@gmail.com'
  'profile.address' => '15604 Harry Lind Road',
  'profile.city' => 'Elgin',
  'profile.zip' => '78621',
  'role.0.label' => 'admin',
  'role.1.label' => 'user',
);


__END__


{
  package Local::Person;

  use Moo;
  use Valiant::Params;

  has [qw/age email phone arg1 arg2 arg3/] => (is=>'ro', predicate=>1);
  has 'name' => (is=>'ro', predicate=>1, required=>1);

  # If param is named then the incoming is permitted to have that value.  It can be option (if you want required set that on the attribute)
  param 'name',
    name => 'given-name', # default is use the attribute name
    multi => 1; # 0 is the default.   it means will allow scalar only.   if 1 then forces to arrayref (or acceptsref).

  param [qw/age email phone/]; # This form allows no options.

  params 'arg1' => +{ multi=>1 },
    'arg2', 
    'arg3';
}

my $person = Local::Person->new(
  request => +{'given-name'=>'john', email=>'jjn1056@gmail.com', arg1=>['1','2'], arg3=>'3'},
  age => 11,
);

is_deeply +{ $person->params_info },
  {
    age => {
      expand => {
        preserve_index => 0,
      },
      multi => 0,
      name => "age",
    },
    arg1 => {
      expand => {
        preserve_index => 0,
      },
      multi => {
        limit => 10000,
      },
      name => "arg1",
    },
    arg2 => {
      expand => {
        preserve_index => 0,
      },
      multi => 0,
      name => "arg2",
    },
    arg3 => {
      expand => {
        preserve_index => 0,
      },
      multi => 0,
      name => "arg3",
    },
    email => {
      expand => {
        preserve_index => 0,
      },
      multi => 0,
      name => "email",
    },
    name => {
      expand => {
        preserve_index => 0,
      },
      multi => {
        limit => 10000,
      },
      name => "given-name",
    },
    phone => {
      expand => {
        preserve_index => 0,
      },
      multi => 0,
      name => "phone",
    },
  };

is_deeply [sort($person->param_keys)], [  sort "arg3", "email", "arg1", "name"];


is_deeply $person->arg1, [1,2];
is $person->arg3, 3;
is_deeply $person->name, ['john'];
is $person->email, 'jjn1056@gmail.com';

is $person->get_param('email'), 'jjn1056@gmail.com';
ok $person->param_exists('email');
ok !$person->param_exists('arg2');

is_deeply +{ $person->params_as_hash },{
    arg1 => [
      1,
      2,
    ],
    arg3 => 3,
    email => "jjn1056\@gmail.com",
    name => [
      "john",
    ],
  };

done_testing;

__END__


