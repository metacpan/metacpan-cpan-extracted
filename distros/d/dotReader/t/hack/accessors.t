#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN {use_ok('dtRdr::Accessor') or die};

ok(! __PACKAGE__->isa(__PACKAGE__ . '::--accessors'), 'safe to use()');
{
  package Bar;
  use dtRdr::Accessor;
}
ok(! Bar->isa('Bar::--accessors'), 'safe to use()');

# basic usage:
{
  package Foo;
  use dtRdr::Accessor(
    ro => [qw(fee fie foe)],
    rw => [qw(foo bar baz)],
  );
}
ok(Foo->isa('Foo::--accessors'), 'isa Foo::--accessors');
can_ok('Foo',
  map({$_, 'get_' . $_} qw(fee fie foe foo bar baz)),
  map({'set_' . $_} qw(foo bar baz))
);
ok(! Foo->can("set_$_"), "do not want set_$_") for qw(fee fie foe);

can_ok('dtRdr::Accessor', qw(ro rw));

# later usage
{
  package Deal;
  use dtRdr::Accessor;
  dtRdr::Accessor->ro(qw(a b c));
  dtRdr::Accessor->rw(qw(d e f));
}

ok(Deal->isa('Deal::--accessors'), 'isa Deal::--accessors');
can_ok('Deal',
  map({$_, 'get_' . $_} qw(a b c d e f)),
  map({'set_' . $_} qw(d e f))
);
ok(! Deal->can("set_$_"), "do not want set_$_") for qw(a b c);

{
my $secret_setter;
{
  package ClassifyMe;

  use dtRdr::Accessor;
  dtRdr::Accessor->class_ro(qw(a 1 b 2 c 3));
  dtRdr::Accessor->class_rw(qw(d 4 e 5 f 6));
  $secret_setter = dtRdr::Accessor->class_ro_w(g => 7);
}
ok(ClassifyMe->isa('ClassifyMe::--accessors'), 'isa ...--accessors');
can_ok('ClassifyMe',
  map({$_, 'get_' . $_} qw(a b c d e f g)),
  map({'set_' . $_} qw(d e f))
);
ok(! ClassifyMe->can('set_1'), 'cannot 1');
ok(! ClassifyMe->can('get_1'), 'cannot 1');
ok(! ClassifyMe->can('1'), 'cannot 1');
ok(! ClassifyMe->can("set_$_"), "do not want set_$_") for qw(a b c g);
ok(ClassifyMe->$_ == ord($_) - 96, "class data for $_") for qw(a b c d e f);
for(qw(d e f)) {
  my $setter = 'set_' . $_;
  ok(ClassifyMe->$setter(ord($_)), "set data for $_");
  ok(ClassifyMe->$_ == ord($_),    "setter check for $_");
}
ok(ClassifyMe->g == 7, 'bingo');
ok(ref($secret_setter), 'gots us a setter');
ok($secret_setter->(17));
ok(ClassifyMe->g == 17, 'ding!');
}

{
my $setter;
{
  package SecretSetter;
  use dtRdr::Accessor;
  dtRdr::Accessor->ro(qw(a b));
  dtRdr::Accessor->rw(qw(c d));
  $setter = dtRdr::Accessor->ro_w('e');
}
ok(SecretSetter->isa('SecretSetter::--accessors'), 'isa ...--accessors');
can_ok('SecretSetter',
  map({$_, 'get_' . $_} qw(a b c d e)),
  map({'set_' . $_} qw(c d))
);
ok(! SecretSetter->can("set_$_"), "do not want set_$_") for qw(a b e);
is($setter, '--set_e', 'got the name right');
ok(SecretSetter->can($setter), "has method $setter");
my $obj = SecretSetter->new;
ok($obj, 'constructor');
ok($obj->isa('SecretSetter'), 'isa ok');
ok(! defined($obj->c), 'nothing there yet');
$obj->set_c(5);
is($obj->c, 5, 'ordinary setter');
ok(! defined($obj->e), 'nothing there yet');
$obj->$setter(7);
is($obj->e, 7, 'setter worked');
}
