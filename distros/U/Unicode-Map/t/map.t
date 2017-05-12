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

my @test = ( 
   map { ref($_) ? $_ : [$_] }
   ["CP936",          "n->m: CP936"],
   ["GB2312",         "n->m: GB2312 (GB2312-80^8080 + ISO8859-1)"],
   ["DEVANAGA",       "n->m: DEVANAGA"],
   ["EUC_JP",         "n->m: EUC-JP"],
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

sub CP936 {
   my $_locale =
      "\xd5\xe2\xca\xc7\xd2\xbb\xb8\xf6\xc0\xfd\xd7\xd3".
      "\xa3\xac\xc7\xeb\xb2\xe2\xca\xd4\xa1\xa3\x0d\x0d"
   ;
   my $_unicode = 
      "\x8f\xd9\x66\x2f\x4e\x00\x4e\x2a\x4f\x8b\x5b\x50".
      "\xff\x0c\x8b\xf7\x6d\x4b\x8b\xd5\x30\x02\x00\x0d".
      "\00\x0d"
   ;
   return testMapping ( "CP936", $_locale, $_unicode );
}

sub EUC_JP {
   my $_locale =
      "Copyright: \x8f\xa2\xed"                               . # Copyright
      "\x5c"                                                  . # Yen sign 
      "\xa1\xa7"                                              . # fullwidth :
      "\xba\xcf"                                              . # CJK
      "\x8f\xed\xe3"                                            # CJK
   ;
   my $_unicode = 
      "\00C\00o\00p\00y\00r\00i\00g\00h\00t\00:\00 \x00\xa9"  . # Copyright
      "\x00\xa5"                                              . # Yen sign 
      "\xff\x1a"                                              . # fullwidth :
      "\x68\x3d"                                              . # CJK
      "\x9f\xa5"                                                # CJK
   ;
   return testMapping ( "EUC-JP", $_locale, $_unicode );
}



sub GB2312 {
   my $_locale  =
      "<title>".
      "\xc5\xb7\xbd\xf5\xc8\xfc"
      ."</title>"
   ;
   my $_unicode =
      "\00<\00t\00i\00t\00l\00e\00>".
      "\x6b\x27\x95\x26\x8d\x5b"
      ."\00<\00/\00t\00i\00t\00l\00e\00>"
   ;
   return testMapping ( "GB2312", $_locale, $_unicode );
}


sub DEVANAGA {
   my $_locale  =
      "\xa1\xe9"
      ." ABc"
      ."\xa1\xf8"
      ."\xe8\xe8\xe8\xe9"
      ."  "
   ;
   my $_unicode =
      "\x09\x50"
      ."\x00\x20\x00\x41\x00\x42\x00\x63"
      ."\x09\x01\x09\x6d"
      ."\x09\x4d\x20\x0c\x09\x4d\x20\x0d"
      ."\x00\x20\x00\x20"
   ;
   return testMapping ( "APPLE-DEVANAGA", $_locale, $_unicode );
}

sub testMapping {
    my ( $charsetId, $txtLocale, $txtUnicode ) = @_;
    return 0 if ! ( my $Map = new Unicode::Map($charsetId) );
    return 0 if $txtLocale ne $Map -> from_unicode ( $txtUnicode );
    return 0 if $txtUnicode ne $Map -> to_unicode ( $txtLocale );
    my $garbage = $Map -> from_unicode ( $txtLocale );
    return 0 if $garbage && $txtLocale eq $garbage;
1}

