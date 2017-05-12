#!/usr/bin/perl

# Program: wrap_prop-regex_slow.pl
# Author: James Briggs
# Date: Mon Sep 28 09:02:05 1998
# Env: Perl5
# Purpose: regex-powerered but slow version of the Text::WrapProp::wrap_prop subroutine

   use strict;
   use diagnostics;

   my @width_table = (0.05) x 256;

   for (1..1000) {
       my $s = wrap_prop("This is a bit of text that forms a normal book-style paragraph. Supercajafrajalisticexpialadocious!", 4.00, \@width_table);
   }

sub wrap_prop {
   my ($text, $width, $ref_width_table) = @_;

   my @width_table = @$ref_width_table;

   return '' if $text eq '';

   # simplify whitespace, including newlines
   $text =~ s/\s+/ /gs;

   my $cursor = 0; # width so far of line
   my $out;        # output buffer
   my $nextline = '';

   while ($text =~ /(.)/gcs) {
         
         # don't need leading spaces at start of line
         next if $nextline eq '' and $1 eq ' ';

         # see if character will fit on line - but don't include if too long
         if ($cursor + $width_table[ord $1] <= $width) {
            # another character fits
            $nextline .= $1;
            $cursor += $width_table[ord $1];
         }
         else {
            # find where we can wrap by checking backwards for separator
            my $j = length($nextline);
            foreach (split '', reverse $nextline) { # find separator
               $j--;
               last if /( |:|;|,|\.|-|\(|\)|\/)/o; # separator characters
            }

            # see if no separator found
            if (!$j) { # no separator, so just truncate line right here
               pos($text)--; # rerun on $1
               $out .= $nextline."\n";
            }
            # 
            else { # separator found, so break line at separator
               pos($text) -= length($nextline) - $j; # rerun characters after separator
               $out .= substr($nextline, 0, $j+1)."\n";
            }

            $nextline = '';
            $cursor = 0;
         }
   }

   $out.$nextline;
}

