#!/usr/bin/perl

# Program: wrap_prop-regex_slow.pl
# Author: James Briggs
# Date: Mon Sep 28 09:02:05 1998
# Env: Perl5
# Purpose: alpha version of fast character processing of the Text::WrapProp::wrap_prop subroutine

use strict;
use diagnostics;

use Data::Dumper;

   my $DEBUG = 1;

   my $input = join('', 'a'..'z') . join('', 'A'..'Z') . join('', '0'..'9') . join('', 'a'..'z') . "\n";
   my @width_table = (0.05) x 256;

   print wrap_prop($input, 1.0, \@width_table);

   print "\n";

   $input = join('', 'a'..'z') . ' ' . join('', 'A'..'Z') . ' ' . join('', '0'..'9') . join('', 'a'..'z') . "\n";
   print wrap_prop($input, 1.0, \@width_table);

   $DEBUG = 0;
   my $output;
   for (1..1000) {
       $output = wrap_prop("This is a bit of text that forms a normal book-style paragraph. Supercajafrajalisticexpialadocious!", 4.00, \@width_table);
   }
   print $output;

sub wrap_prop {
   my ($text, $width, $rwidth_table) = @_;

   my $break_chars = ' :;,.()\/-';

   my %bhash = map { ( "$_" => 1) } split(//, $break_chars);

   my $brk = -1;
   my $cursor = 0;
   my $brk_cursor = 0;
   my $out = '';
   my $brkc = '';

   $text =~ s/\n(\n+)/$1/g; # compress duplicate newlines to one less (preserve paragraphs delimited by 2 or more newlines)
   $text =~ s/  +/ /g; # compress duplicate spaces to a single space

   my $ltext = length $text;

   my $start = 0;
   my $i = 0;

   for my $c (split(//, $text)) {
      # don't need leading spaces at start of line
      if ($cursor < 0.0000001 and $c eq ' ') {
         $i+=2;
         $start = $i;
         $cursor = 0.0;
         $brk = -1;
         $brk_cursor = 0.0;
         next;
      }

      if ($c eq "\n") {
         $out .= substr($text, $start, $i-$start);
         $i+=2;
         $start = $i;
         $cursor = 0.0;
         $brk = -1;
         $brk_cursor = 0.0;
         next;
      }

      if (exists $bhash{$c}) {
         $brk = $i;
         $brk_cursor = $cursor;
         $brkc = $c;
      }

      # see if character will fit on line - but don't include if too long
      $cursor += $rwidth_table->[ord $c];
      if ($cursor > $width+0.0000001) {
         if ($brk != -1) { # backtrack
print "c=$c, cursor=$cursor, start=$start, i=$i, brk=$brk, diff=@{[ $brk-$start ]}, ltext=$ltext\n" if $DEBUG;

            $out .= substr($text, $start, $brk-$start) . "\n";
            if ($brkc eq ' ') {
               $start = $brk+1;
               $cursor -= $brk_cursor;
            }
            else {
               $start = $brk;
               $cursor -= $brk_cursor;
            }
         }
         else {
print "c=$c, cursor=$cursor, start=$start, i=$i, brk=$brk, diff=@{[ $i-$start ]}, ltext=$ltext\n" if $DEBUG;
            $out .= substr($text, $start, $i-$start) . "\n";
            if ($c eq ' ') {
               $start = $i+1;
               $cursor = 0.0;
            }
            else {
               $start = $i;
               $cursor = $rwidth_table->[ord $c];
            }
         }

         $brk = -1;
         $brk_cursor = 0.0;
      }

      $i++;
   }

print "cursor=$cursor, start=$start, i=$i, brk=$brk, diff=@{[ $i-$start ]}, ltext=$ltext\n" if $DEBUG;
   if ($start < $ltext) {
      return($out.substr($text, $start));
   }
   else {
      return($out);
   }
}

