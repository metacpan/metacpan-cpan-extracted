use strict; use warnings FATAL => 'all';
use Test::More qw(no_plan);

{

  package Foo;
  sub foo {
    use CSS::Declare;
    return (
       '*' => [ color 'red' ],
       'tr, td' => [ margin '1px' ],
    );
  }
}

is(
   CSS::Declare::to_css_string(Foo::foo()),
  '* {color:red} tr, td {margin:1px}',
  'Basic CSS::Declare usage'
);

ok(!Foo->can('color'), 'Death on use of unimported tag');

