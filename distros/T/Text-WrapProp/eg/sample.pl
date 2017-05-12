#!/usr/bin/perl

   use strict;
   use diagnostics;

   use Text::WrapProp qw(wrap_prop);

   my @width_table = (0.05) x 256;

   for (1..1000) {
       my ($output, $status) = wrap_prop("This is a bit of text that forms a normal book-style paragraph. Supercajafrajalisticexpialadocious!", 4.00, \@width_table);
#       print $output if !$status;
   }

