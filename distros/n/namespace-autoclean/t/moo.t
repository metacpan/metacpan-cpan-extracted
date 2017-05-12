use strict;
use warnings;
use Test::More 0.88;

# see moo-with-moose.t
use constant WITH_MOOSE => !!$INC{'Moose.pm'};

# blech! but Test::Requires does a stringy eval, so this works...
use Test::Requires { 'Moo' => '()', 'Moo::Role' => '()' };

plan skip_all => 'this combination of Moo/Sub::Util is unstable'
    if Moo->VERSION >= 2 and not eval { Moo->VERSION('2.000002') }
        and $INC{"Sub/Util.pm"} and not defined &Sub::Util::set_subname;

my $buzz; BEGIN { $buzz = sub {}; }
my $welp; BEGIN { $welp = sub {}; }

BEGIN {
    package Some::Class;
    use Carp qw(cluck);
    use File::Basename qw(fileparse);
    use Moo;
    use namespace::autoclean;
    sub bar { }
    BEGIN { *guff = sub {} }
    BEGIN { *welp = $welp }
    use constant CAT => 'kitten';
    BEGIN { our $DOG = 'puppy' }
    use constant DOG => 'puppy';
}

ok defined &Some::Class::bar,
  'Some::Class::bar created normally';
ok defined &Some::Class::guff,
  'Some::Class::guff added via glob assignment';
{
  local $TODO = 'not working if Moose loaded'
    if WITH_MOOSE;
  ok !defined &Some::Class::welp,
    'Some::Class::welp foreign added via glob assignment was cleaned';
}
ok !defined &Some::Class::cluck,
  'Some::Class::cluck imported sub was cleaned';
ok !defined &Some::Class::fileparse,
  'Some::Class::fileparse imported sub was cleaned';
ok defined &Some::Class::CAT,
  'Some::Class::CAT constant';
ok defined &Some::Class::DOG,
  'Some::Class::DOG constant with other glob entry';

BEGIN {
    package Some::Role;
    use Carp qw(cluck);
    use File::Basename qw(fileparse);
    use Moo::Role;
    use namespace::autoclean;
    sub bar { }
    BEGIN { *guff = sub {} }
    BEGIN { *welp = $welp }
    use constant CAT => 'kitten';
    BEGIN { our $DOG = 'puppy' }
    use constant DOG => 'puppy';
}

{
  local $TODO = "Moo::Role's meta not seen as method";
  ok defined &Some::Role::meta,
    'Some::Role::meta created by Moo::Role';
}
ok defined &Some::Role::bar,
  'Some::Role::bar created normally';
ok defined &Some::Role::guff,
  'Some::Role::guff added via glob assignment';
{
  local $TODO = 'not working if Moose loaded';
  ok !defined &Some::Role::welp,
    'Some::Role::welp foreign added via glob assignment was cleaned';
}
ok !defined &Some::Role::cluck,
  'Some::Role::cluck imported sub was cleaned';
ok !defined &Some::Role::fileparse,
  'Some::Role::fileparse imported sub was cleaned';
ok defined &Some::Role::CAT,
  'Some::Role::CAT constant';
ok defined &Some::Role::DOG,
  'Some::Role::DOG constant with other glob entry';

BEGIN {
  package Consuming::Class;
  use Moo;
  use namespace::autoclean;
  with 'Some::Role';
}

ok defined &Consuming::Class::bar,
  'Consuming::Class::bar created normally';
ok defined &Consuming::Class::guff,
  'Consuming::Class::guff added via glob assignment';
{
  local $TODO = 'not working if Moose loaded'
    if WITH_MOOSE;
  ok !defined &Consuming::Class::welp,
    'Consuming::Class::welp foreign added via glob assignment was cleaned';
}
ok !defined &Consuming::Class::cluck,
  'Consuming::Class::cluck imported sub was cleaned';
ok !defined &Consuming::Class::fileparse,
  'Consuming::Class::fileparse imported sub was cleaned';
ok defined &Consuming::Class::CAT,
  'Consuming::Class::CAT constant';
ok defined &Consuming::Class::DOG,
  'Consuming::Class::DOG constant with other glob entry';

BEGIN {
  package Consuming::Class::InBegin;
  use Moo;
  use namespace::autoclean;
  BEGIN { with 'Some::Role' };
}

ok defined &Consuming::Class::InBegin::bar,
  'Consuming::Class::InBegin::bar created normally';
ok defined &Consuming::Class::InBegin::guff,
  'Consuming::Class::InBegin::guff added via glob assignment';
{
  local $TODO = 'not working if Moose loaded'
    if WITH_MOOSE;
  ok !defined &Consuming::Class::InBegin::welp,
    'Consuming::Class::InBegin::welp foreign added via glob assignment was cleaned';
}
ok !defined &Consuming::Class::InBegin::cluck,
  'Consuming::Class::InBegin::cluck imported sub was cleaned';
ok !defined &Consuming::Class::InBegin::fileparse,
  'Consuming::Class::InBegin::fileparse imported sub was cleaned';
ok defined &Consuming::Class::InBegin::CAT,
  'Consuming::Class::InBegin::CAT constant';
ok defined &Consuming::Class::InBegin::DOG,
  'Consuming::Class::InBegin::DOG constant with other glob entry';

if (!WITH_MOOSE) {
  is $INC{'Class/MOP/Class.pm'}, undef, 'Class::MOP not loaded';
}

done_testing;
