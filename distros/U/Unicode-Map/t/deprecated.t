##
## Some functionality of Unicode-Map-0.105 is deprecated now. It is either
## removed from the documentation or explicitly marked deprecated there.
##
## Anyway old code applying Unicode::Map should remain intact. This test
## asserts that:
##    1. The deprecated usage is still available
##    2. Unicode::Map issues warnings if $WARNINGS & WARN_DEPRECATION
##

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Unicode::Map;
$loaded = 1;
print "ok 1\n";
print STDERR "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;

my $locale   = "Käse";
my $utf16    = "\0K\0ä\0s\0e";
my $warnings = 0;

my @test = ( 
   map { ref($_) ? $_ : [$_] }
   ["new_no_id",      "new: joker charset id"],
   ["new_id_select",  "new: preselected charset id"],
   ["reverse",        "reverse unicode"],
   ["noise",          "noise"],
);

{
   my $max = 0;
   my $len;
   for (0..$#test) { 
      $len = length($test[$_]->[$#{$test[$_]}]);
      $max = $len if $len>$max;
   }
      
   my ($name, $desc);
   my $i=2;
   for (sort {$test[$a]->[$#{$test[$a]}] cmp $test[$b]->[$#{$test[$b]}]} 
        0..$#test
   ) {
      ($name, $desc) = @{$test[$_]};
      $desc = $name if !defined $desc;
      _out($max, $i, $desc); 
      test ($i++, eval "&$name($_, \"$name\")");
   }
}

sub _out {
   my $max = shift;
   my $t = sprintf "    #%2d: %s ", @_;
   $t .= "." x (9 + 4 + $max - length($t));
   printf STDERR "$t ";
}

sub test {
   my ($number, $status) = @_;
   if ($status) {
      print STDERR "ok\n";
      print "ok $number\n";
   } else {
      print STDERR "failed!\n";
      print "not ok $number\n";
   }
}

##
## Tests if a construction like this is supported:
##
##     my $Map = new Unicode::Map ( );
##     my $utf16 = $Map -> to_unicode ( "ISO-8859-1", $str );
##
## Correct usage would be:
##
##     my $Map = new Unicode::Map ( "ISO-8859-1" );
##     my $utf16 = $Map -> to_unicode ( $str );
##
sub new_no_id {
   setWarnings ( );
   return 0 unless $warnings == 0;
   my $Map = new Unicode::Map ( );
   return 0 unless $warnings == 1;
   return 0 unless $Map;
   return 0 unless $Map -> to_unicode ( "ISO-8859-1", $locale ) eq $utf16;
   return 0 unless $warnings == 2;
   return 0 unless $Map -> from_unicode ( "ISO-8859-1", $utf16 ) eq $locale;
   return 0 unless $warnings == 3;
   setNoWarnings ( );
1}

##
## Tests if a constructor with this form is supported:
##
##     new Unicode::Map ( {ID => "ISO-8859-1"} );
##
## Correct usage would be:
##
##     new Unicode::Map ( "ISO-8859-1" );
##
sub new_id_select {
   setWarnings ( );
   return 0 unless $warnings == 0;
   return 0 unless my $Map = new Unicode::Map ({ ID => "ISO-8859-1" });
   return 0 unless $warnings == 1;
   return 0 unless $Map -> to_unicode ( $locale ) eq $utf16;
   return 0 unless $Map -> from_unicode ( $utf16 ) eq $locale;
   return 0 unless $warnings == 1;
   setNoWarnings ( );
1}

##
## Tests if this method is supported:
##
##    $utf16 = "\0S\0o\0m\0e";
##    $Map -> reverse_unicode ( $utf16 );
##
## Proposed substitute for this deprecated usage:
##
##    Unicode::String::byteswap ( $utf16 );
##
sub reverse {
   my $utf16 = "K\0ä\0s\0e\0";
   setWarnings ( );
   return 0 unless my $Map = new Unicode::Map ( "ISO-8859-1" );
   return 0 unless $warnings == 0;
   $Map -> reverse_unicode ( $utf16 );
   return 0 unless $warnings == 1;

   # Has the original variable been changed?
   return 0 unless $utf16 eq "\0K\0ä\0s\0e";

   # Did we get a transfored copy?
   return 0 unless $Map -> reverse_unicode ( $utf16 ) eq "K\0ä\0s\0e\0";
   return 0 unless $warnings == 2;

   # Was it really a copy?
   return 0 unless $utf16 eq "\0K\0ä\0s\0e";

   setNoWarnings ( );
1}

##
## Tests if method "noise" is available:
##
sub noise {
   setWarnings ( );
   return 0 unless my $Map = new Unicode::Map ( "ISO-8859-1" );
   return 0 unless $warnings == 0;
   $Map -> noise ( 3 );
   return 0 unless $warnings == 1;
   setNoWarnings ( );
}


#
# utilities
#

sub setWarnings {
   $warnings = 0;
   $SIG{'__WARN__'} = sub {
      $warnings++;
   };
   $Unicode::Map::WARNINGS = Unicode::Map::WARN_DEPRECATION;
1}

sub setNoWarnings {
   $SIG{'__WARN__'} = 0;
   $warnings = 0;
   $Unicode::Map::WARNINGS = Unicode::Map::WARN_DEFAULT;
1}

