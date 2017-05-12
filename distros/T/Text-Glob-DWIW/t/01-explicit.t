#! /usr/bin/perl -Tw

use v5.10; use strict; use warnings;
use Test::More tests => 8;                    BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW qw':all';
#use Data::Dump; #use Devel::Dwarn;

my $p; my @v; my $sec='explicit anchors & expand';
my $o={default=>1,anchors=>1,anchored=>1};

is_deeply [tg_expand $p='for{$,,ever\-and-}ever',$o],
          [qw'for forever forever-and-ever'],"$sec: $p";
is_deeply [tg_expand $p='flop{^,$}flip',$o],[qw'flip flop'],"$sec: $p";

$sec="anchors & grep";

is +(tg_grep $o,$p='flop{^,$}flip',qw'flip flop')[-1],'flop',"$sec: $p [flop]"; #only a flop
is_deeply [tg_grep $o,$p='*{/a/,^}bla', @v=qw'where/ever/a/bla bla'],\@v,"$sec: $p";

is_deeply [tg_grep $o,$p='for{$,,ever and }ever',
           qw'fora forev fo',@v=('for','forever','forever and ever'),],
           \@v,"$sec: $p";

is_deeply [tg_grep {%$o,rewrite=>0},$p='flop{^,$}flip','flap',@v=qw'flip flop'],\@v,"$sec: $p";

TODO: { local $TODO='documented accordingly anyway';
  is_deeply [tg_grep $o,$p='flop{^,$}flip',@v=qw'flip flop flup'],\@v,"$sec: $p";
}

had_no_warnings();
#done_testing;
