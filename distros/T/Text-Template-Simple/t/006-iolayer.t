#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
BEGIN {
   use_ok('Text::Template::Simple');
}

ok( simple() , 'Simple test 1' );
ok( simple2(), 'Simple test 2' );

sub simple {
   my @args = (
      header   => q~my $foo = shift; my $bar = shift;~,
      add_args => ['bar',['baz']],
      iolayer  => 'utf8',
   );
   ok(my $template = Text::Template::Simple->new( @args ), 'object');
   ok(my $result   = $template->compile('t/data/test.tts', ['Burak']),'result');
   return $result;
}

sub simple2 {
   ok(my $template = Text::Template::Simple->new,'object');
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
   ok(my $result = $template->compile( @args ), 'result');
   return $result;
}
