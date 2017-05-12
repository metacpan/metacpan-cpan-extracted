#! /usr/bin/perl -w 
use strict;

use Text::Reform;

print form(
  {
    pagewidth => 40,
    pagelen =>  10,
    footer =>   sub {
                    if ($#_) {
                      return "-" x 50 . "\n" .  "Special end of report note";
                    } else {
                      return {
                               center => "\n-- Page $_[0] --\n\n"
                             };
                    }
                  },
    },
  ']]]]]]]]]]]',
  ("hello\n" x 18)
);
