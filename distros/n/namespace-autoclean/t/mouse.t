use strict;
use warnings;
use Test::More 0.88;
{
  package Temp1;
  use Test::Requires {
    'Mouse' => 0,
  };
}

my $buzz; BEGIN { $buzz = sub {}; }
my $welp; BEGIN { $welp = sub {}; }

local $TODO = 'Mouse does not seem to be stable in 5.8.x anymore :/'
    if $] < 5.010;

BEGIN {
    package Some::Class;
    use Carp qw(cluck);
    use File::Basename qw(fileparse);
    use Mouse;
    use namespace::autoclean;
    sub bar { }
    BEGIN { *guff = sub {} }
    BEGIN { *welp = $welp }
    BEGIN { __PACKAGE__->meta->add_method(baz => sub { }); }
    BEGIN { __PACKAGE__->meta->add_method(buzz => $buzz); }
    use constant CAT => 'kitten';
    BEGIN { our $DOG = 'puppy' }
    use constant DOG => 'puppy';
}

{
  local $TODO = "meta created by Mouse not seen as method in 5.8 or without XS"
    if $] < 5.010 || $ENV{MOUSE_PUREPERL} || !Mouse::Util::MOUSE_XS;
  ok defined &Some::Class::meta,
    'Some::Class::meta created by Mouse';
}
ok defined &Some::Class::bar,
  'Some::Class::bar created normally';
ok defined &Some::Class::guff,
  'Some::Class::guff added via glob assignment';
ok !defined &Some::Class::welp,
  'Some::Class::welp foreign added via glob assignment was cleaned';
ok defined &Some::Class::baz,
  'Some::Class::baz added via meta->add_method';
{
  local $TODO = "foreign methods via add_methods don't work in 5.8 or without XS"
    if $] < 5.010 || $ENV{MOUSE_PUREPERL} || !Mouse::Util::MOUSE_XS;
  ok defined &Some::Class::buzz,
    'Some::Class::buzz foreign added via meta->add_method';
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
    use Mouse::Role;
    use namespace::autoclean;
    sub bar { }
    BEGIN { *guff = sub {} }
    BEGIN { *welp = $welp }
    BEGIN { __PACKAGE__->meta->add_method(baz => sub { }); }
    BEGIN { __PACKAGE__->meta->add_method(buzz => $buzz); }
    use constant CAT => 'kitten';
    BEGIN { our $DOG = 'puppy' }
    use constant DOG => 'puppy';
}

{
  local $TODO = "meta created by Mouse not seen as method in 5.8 or without XS"
    if $] < 5.010 || $ENV{MOUSE_PUREPERL} || !Mouse::Util::MOUSE_XS;
  ok defined &Some::Role::meta,
    'Some::Role::meta created by Mouse::Role';
}
ok defined &Some::Role::bar,
  'Some::Role::bar created normally';
ok defined &Some::Role::guff,
  'Some::Role::guff added via glob assignment';
ok !defined &Some::Role::welp,
  'Some::Role::welp foreign added via glob assignment was cleaned';
ok defined &Some::Role::baz,
  'Some::Role::baz added via meta->add_method';
{
  local $TODO = "foreign methods via add_methods don't work with Mouse";
  ok defined &Some::Role::buzz,
    'Some::Role::buzz foreign added via meta->add_method';
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
  use Mouse;
  use namespace::autoclean;
  with 'Some::Role';
}

{
  local $TODO = "meta created by Mouse not seen as method in 5.8 or without XS"
    if $] < 5.010 || $ENV{MOUSE_PUREPERL} || !Mouse::Util::MOUSE_XS;
  ok defined &Consuming::Class::meta,
    'Consuming::Class::meta created by Mouse';
}
ok defined &Consuming::Class::bar,
  'Consuming::Class::bar created normally';
ok defined &Consuming::Class::guff,
  'Consuming::Class::guff added via glob assignment';
ok !defined &Consuming::Class::welp,
  'Consuming::Class::welp foreign added via glob assignment was cleaned';
ok defined &Consuming::Class::baz,
  'Consuming::Class::baz added via meta->add_method';
ok defined &Consuming::Class::buzz,
  'Consuming::Class::buzz foreign added via meta->add_method';
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
  use Mouse;
  use namespace::autoclean;
  BEGIN { with 'Some::Role' };
}

{
  local $TODO = "meta created by Mouse not seen as method in 5.8 or without XS"
    if $] < 5.010 || $ENV{MOUSE_PUREPERL} || !Mouse::Util::MOUSE_XS;
  ok defined &Consuming::Class::InBegin::meta,
    'Consuming::Class::InBegin::meta created by Mouse';
}
ok defined &Consuming::Class::InBegin::bar,
  'Consuming::Class::InBegin::bar created normally';
{
  local $TODO = "consumed glob assigned subs not seen as method in 5.10+"
    if $] >= 5.010 && !$INC{'Mouse/PurePerl.pm'};
  ok defined &Consuming::Class::InBegin::guff,
    'Consuming::Class::InBegin::guff added via glob assignment';
}
ok !defined &Consuming::Class::InBegin::welp,
  'Consuming::Class::InBegin::welp foreign added via glob assignment was cleaned';
ok defined &Consuming::Class::InBegin::baz,
  'Consuming::Class::InBegin::baz added via meta->add_method';
{
  local $TODO = "consumed foreign methods via add_methods not seen as method";
  ok defined &Consuming::Class::InBegin::buzz,
    'Consuming::Class::InBegin::buzz foreign added via meta->add_method';
}
ok !defined &Consuming::Class::InBegin::cluck,
  'Consuming::Class::InBegin::cluck imported sub was cleaned';
ok !defined &Consuming::Class::InBegin::fileparse,
  'Consuming::Class::InBegin::fileparse imported sub was cleaned';
ok defined &Consuming::Class::InBegin::CAT,
  'Consuming::Class::InBegin::CAT constant';
{
  local $TODO = "constant with other glob entries not consumed properly"
    if !$INC{'Mouse/PurePerl.pm'};
  ok defined &Consuming::Class::InBegin::DOG,
    'Consuming::Class::InBegin::DOG constant with other glob entry';
}

done_testing;
