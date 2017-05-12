#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap

use strict;
use warnings;

use Test::More ('no_plan');

BEGIN { use_ok('Regexp::PosIterator') };

{
  #             01234567890123456
  my $string = "abcaaaabcbffffabc";
  my $regexp = qr/(a)(b)(c)/;

  my $finder = Regexp::PosIterator->new($regexp, $string);
  ok($finder, 'constructor');
  isa_ok($finder, 'Regexp::PosIterator');

  my @matches;
  my @submatches;

  while(my @match = $finder->match) {
    #warn "matched: @match\n";
    my $got = substr($string, $match[0], $match[1]-$match[0]);
    is($got, 'abc', 'got what I needed');
    push(@matches, \@match);
    push(@submatches, [$finder->submatches]);
  }
  is_deeply(\@matches, [
    [0, 3],
    [6, 9],
    [14, 17],
  ], 'the match positions match');
  is_deeply(\@submatches, [
    [[0, 1], [1, 2], [2, 3]],
    [[6, 7], [7, 8], [8, 9]],
    [[14, 15], [15, 16], [16, 17]],
  ], 'the submatch positions match');
}
{
  #             01234567890123456
  my $string = "abcaaaabcbffffabc";
  my $regexp = qr/a/;

  my $finder = Regexp::PosIterator->new($regexp, $string);
  ok($finder, 'constructor');
  isa_ok($finder, 'Regexp::PosIterator');

  my @matches;
  my @submatches;

  while(my @match = $finder->match) {
    #warn "matched: @match\n";
    my $got = substr($string, $match[0], $match[1]-$match[0]);
    is($got, 'a', 'got what I needed');
    push(@matches, \@match);
  }
  is(scalar(@matches), 6, 'match count');
}
{ # here with a possibly zero-width submatch
  #             01234567890123456
  my $string = "abcacaaabcbfffabc";
  my $regexp = qr/(a)(b?)(c)/;

  my $finder = Regexp::PosIterator->new($regexp, $string);
  ok($finder, 'constructor');
  isa_ok($finder, 'Regexp::PosIterator');

  my @matches;
  my @submatches;

  my $matchnum = 0;
  while(my @match = $finder->match) {
    #warn "matched: @match\n";
    $matchnum++;
    my $got = substr($string, $match[0], $match[1]-$match[0]);
    is($got, ($matchnum == 2 ? 'ac' : 'abc'), 'got what I needed');
    push(@matches, \@match);
    push(@submatches, [$finder->submatches]);
  }
  is_deeply(\@matches, [
    [0, 3],
    [3, 5],
    [7, 10],
    [14, 17],
  ], 'the match positions match');
  is_deeply(\@submatches, [
    [[0, 1], [1, 2], [2, 3]],
    [[3, 4], [4,4],  [4, 5]],
    [[7, 8], [8, 9], [9, 10]],
    [[14, 15], [15, 16], [16, 17]],
  ], 'the submatch positions match');
}
{ # now with a possibly undef submatch match
  #             01234567890123456
  my $string = "abcacaaabcbfffabc";
  my $regexp = qr/(a)(b)?(c)/;

  my $finder = Regexp::PosIterator->new($regexp, $string);
  ok($finder, 'constructor');
  isa_ok($finder, 'Regexp::PosIterator');

  my @matches;
  my @submatches;

  my $matchnum = 0;
  while(my @match = $finder->match) {
    #warn "matched: @match\n";
    $matchnum++;
    my $got = substr($string, $match[0], $match[1]-$match[0]);
    is($got, ($matchnum == 2 ? 'ac' : 'abc'), 'got what I needed');
    push(@matches, \@match);
    push(@submatches, [$finder->submatches]);
  }
  is_deeply(\@matches, [
    [0, 3],
    [3, 5],
    [7, 10],
    [14, 17],
  ], 'the match positions match');
  is_deeply(\@submatches, [
    [[0, 1], [1, 2], [2, 3]],
    [[3, 4], [   ],  [4, 5]],
    [[7, 8], [8, 9], [9, 10]],
    [[14, 15], [15, 16], [16, 17]],
  ], 'the submatch positions match');
}
