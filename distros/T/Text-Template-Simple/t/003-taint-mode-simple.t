#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
BEGIN {
   use_ok('Text::Template::Simple');
}

ok(simple() , 'Simple test 1');
ok(simple2(), 'Simple test 2');

ok(my $t = Text::Template::Simple->new(), 'Got the object');

is( $t->cache->type, 'OFF', 'Correct cache type is set' );

sub simple {
   ok( my $template = Text::Template::Simple->new(
      header   => q~my $foo = shift; my $bar = shift;~,
      add_args => ['bar',['baz']],
   ), 'simple() object');
   ok( my $result = $template->compile('t/data/test.tts', ['Burak']), 'simple() result');
   return $result;
}

sub simple2 {
   ok(my $template = Text::Template::Simple->new(), 'simple2() object');
   my @args = (
      'Hello <%name%>. Foo is: <%foo%> and bar is <%bar%>.',
      [
         name => 'Burak',
         foo  => 'bar',
         bar  => 'baz',
      ],
      {
         map_keys => 1
      },
   );
   ok( my $result = $template->compile( @args ), 'simple2() result');
   return $result;
}
