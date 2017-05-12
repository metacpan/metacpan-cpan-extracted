#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Carp qw( croak );
BEGIN {
   use_ok('Text::Template::Simple');
}

local $SIG{__WARN__} = sub { # silence stack dumps
   my $msg = shift;
   return if $msg =~ m{DUMPING \s CALLER \s STACK \s FOR}xms;
   return if $msg =~ m{Caller \s stack \s type}xms;
   return if $msg =~ m{\Qttsc-wrapper}xms;
   warn "$msg\n";
};

ok( simple('string'      ), 'String Dumper');
ok( simple('html_comment'), 'HTML Comment Dumper');
ok( simple('html_table'  ), 'HTML Table Dumper');

my $ok = eval { require Text::Table; 1; };

if ( ! $@ && $ok ) {
   ok(simple('text_table'), 'Text Table Dumper');
}

sub simple {
   my $type = shift || croak 'type?';
   my @args = (
      header   => q~my $foo = shift; my $bar = shift;~,
      add_args => ['bar',['baz']],
      stack    => $type,
   );
   ok(my $template = Text::Template::Simple->new( @args ),'object');
   ok(my $result = $template->compile('t/data/test.tts', ['Burak']),'result');
   #warn "[COMPILED] $result\n";
   return $result;
}
