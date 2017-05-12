# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-WrapProp.t'

use strict;
use diagnostics;

use Data::Dumper;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN { use_ok('Text::WrapProp', qw(wrap_prop), ) };

   my $DEBUG = 1;

   my @width_table = (0.05) x 256;

# test input parameters

   my $input  = '';
   my ($output, $nstatus) = wrap_prop($input, 1.00, \@width_table);
   ok(($output eq '' and $nstatus == 0), 'empty input check');

   $input  = undef;
   ($output, $nstatus) = wrap_prop($input, 1.00, \@width_table);
   ok(($output eq '' and $nstatus == 1), 'null input check');

   $input  = '';
   ($output, $nstatus) = wrap_prop($input, undef, \@width_table);
   ok(($output eq '' and $nstatus == 2), 'null width check');

   $input  = '';
   ($output, $nstatus) = wrap_prop($input, 0, \@width_table);
   ok(($output eq '' and $nstatus == 2), 'zero int width check');

   $input  = '';
   ($output, $nstatus) = wrap_prop($input, 0.0, \@width_table);
   ok(($output eq '' and $nstatus == 2), 'zero float width check');

   $input  = '';
   ($output, $nstatus) = wrap_prop($input, 1.0, undef);
   ok(($output eq '' and $nstatus == 3), 'missing width_table check');

   $input  = '';
   ($output, $nstatus) = wrap_prop($input, 1.0, (0.5));
   ok(($output eq '' and $nstatus == 3), 'bogus width_table check');

   $input  = '';
   ($output, $nstatus) = wrap_prop($input, 1.0, [ 0.5 ]);
   ok(($output eq '' and $nstatus == 3), 'truncated width_table check');

# test wrap functions

   $input  = 'a';
   ($output, $nstatus) = wrap_prop($input, 1.0, \@width_table);
   ok(($output eq 'a' and $nstatus == 0), '1-character string wrap check');

   $input  = join('', 'a'..'t');
   ($output, $nstatus) = wrap_prop($input, 1.0, \@width_table);
   ok(($output eq join('', 'a'..'t') and $nstatus == 0), '20-character string wrap check');

   $input  = join('', 'a'..'u');
   ($output, $nstatus) = wrap_prop($input, 1.0, \@width_table);
   ok(($output eq join('', 'a'..'t') . "\nu" and $nstatus == 0), '21-character string wrap check');

   $input  = join('', 'a'..'s') . "t\n u";
   ($output, $nstatus) = wrap_prop($input, 1.0, \@width_table);
   ok(($output eq join('', 'a'..'t') . "\nu" and $nstatus == 0), '21-character string wrap check with leading space omitted');
print Dumper($output);

   my $truth = join('', 'a'..'t') . "\n" . join('', 'u' .. 'z') . join('', 'A'..'N') . "\n" . join('', 'O'..'Z');

   $input  = join('', 'a'..'z') . join('', 'A'..'Z');
   ($output, $nstatus) = wrap_prop($input, 1.0, \@width_table);
   ok(($output eq $truth and $nstatus == 0), 'medium string wrap check');
print Dumper($output);

   $input = "The quick brown fox jumped over the lazy red log. This is the next sentence.  Supercajafrajalisticexpialadocious 1!.  Super-cajafrajalistic-expialadocious 2!.  Supercajafrajal-isticexpialadocious 3!.  Supercajafrajalisticexpialado-cious 4!. The End.";
   ($output, $nstatus) = wrap_prop($input, 1.0, \@width_table);
   ok((substr($output, 0, 3) eq 'The' and $output =~ /End.\n?$/ and $nstatus == 0), 'long words check');
   if ($DEBUG) {
      print "width_table elements: " . scalar(@width_table) . "\n";
      print $output . "\n";
   }

# end

