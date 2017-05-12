#!/usr/bin/perl

use strict;
use warnings;

use Test::More (
  #skip_all => 'just getting started here',
  'no_plan'
);

eval {require dtRdr::Callbacks::Book} or die("load failed $@");

ok(! __PACKAGE__->can('callback'), "not installed here");
ok(! __PACKAGE__->can('get_callbacks'), "not installed here");

{
  package MyBase;
  use dtRdr::Callbacks::Book;
}
ok(MyBase->can('callback'), 'installed here');
ok(MyBase->can('get_callbacks'), 'installed here');
{
  package MyDerived;
  use base 'MyBase';
  use dtRdr::Callbacks::Book;
}
ok(MyDerived->can('callback'), 'installed here');
ok(MyDerived->can('get_callbacks'), 'installed here');

# install from outside the package
@MyAlsoDerived::ISA = 'MyBase';
dtRdr::Callbacks::Book->install_in('MyAlsoDerived');
ok(MyAlsoDerived->can('callback'), 'installed here');
ok(MyAlsoDerived->can('get_callbacks'), 'installed here');

=begin TODO

# something like this would be neat

my $foo = 0;
dtRdr::Callbacks::Book->define('some_thing', sub {$foo++});
dtRdr::Callbacks::Book->define('some_stuff', []);

=end TODO

=cut

{
  my $foo = 0;
  can_ok('dtRdr::Callbacks::Book', 'has');
  ok(! MyBase->callback->has('img_src_rewrite'));
  ok(! MyBase->get_callbacks->has('img_src_rewrite'));
  MyBase->callback->set_img_src_rewrite_sub(sub {$foo=1});

  # cannot do set on the aggregated callbacks
  eval {
    MyBase->get_callbacks->set_img_src_rewrite_sub(sub {});
  };
  ok($@);
  like($@, qr/cannot set on an aggregated callback object/);
  
  ok(MyBase->callback->has('img_src_rewrite'));
  ok(MyBase->get_callbacks->has('img_src_rewrite'));
  ok(! MyDerived->callback->has('img_src_rewrite'));
  ok(! MyAlsoDerived->callback->has('img_src_rewrite'));
  ok(MyDerived->get_callbacks->has('img_src_rewrite'));
  ok(MyAlsoDerived->get_callbacks->has('img_src_rewrite'));

  is($foo, 0);
  MyBase->get_callbacks->img_src_rewrite();
  is($foo, 1);
  $foo = 0;
  MyBase->callback->img_src_rewrite();
  is($foo, 1);
  $foo = 0;
  MyDerived->get_callbacks->img_src_rewrite();
  is($foo, 1);
  $foo = 0;
  MyAlsoDerived->get_callbacks->img_src_rewrite();
  is($foo, 1);

  $foo = 0;
  # then override
  MyDerived->callback->set_img_src_rewrite_sub(sub {$foo = 2});
  MyDerived->get_callbacks->img_src_rewrite();
  is($foo, 2, 'override working');
  MyAlsoDerived->get_callbacks->img_src_rewrite();
  is($foo, 1, 'override working');
}

# vim:ts=2:sw=2:et:sta
