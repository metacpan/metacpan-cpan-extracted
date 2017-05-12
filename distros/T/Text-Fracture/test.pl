#! /usr/bin/perl -w
#



use ExtUtils::testlib;	# so that we find Fracture here without installing it.
use Text::Fracture qw(init fract);
use Data::Dumper;

my $init = { verbose => 2 };
my $text = qq(

Text-Fracture version 0.01 ========================== Please see perldoc Text::Fracture and test.pl for usage details.  INSTALLATION To install this module type the following: perl Makefile.PL make make test make install DEBUGGING \$ gdb --args /usr/bin/perl "-Iblib/lib" "-Iblib/arch" test.pl foo (gdb) break XS_Text__Fracture_do_fract Function "XS_Text__Fracture_do_fract" not defined.  Make breakpoint pending on future shared library load? (y or [n]) y (gdb) break consume_fragments (gdb) run (gdb) p *f\@6 

DEPENDENCIES

This module was started by running h2xs -A -n Text-Fracture
It has no dependencies.

COPYRIGHT AND LICENCE

Copyright (C) 2007 by Juergen Weigert (jw\@suse.de), Novell Inc.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.  

This text is a test for the
 fracture code. We expect it to chop it in 
in two fragments.

Let us see what will happen.
-------------------------------------

We call init() with a small values, so 
this text can also remain reasonably small);

my $file = shift;
if ($file)
  {
    local $/;
    open IN, "<$file" or die "read $file failed: $!\n";
    $text = join '', <IN>;
    close IN;
  }
init($init);
my $l = fract($text);
# print Dumper $l;

for my $f (@$l)
  {
    print "============= $f->[0],$f->[1],$f->[2],$f->[3] ================\n";
    print substr $text, $f->[0], $f->[1];
    print "\$--\n";
  }
# odd, the above code is cut after the for -line, not before it...
