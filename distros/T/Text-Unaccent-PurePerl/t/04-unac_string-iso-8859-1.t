# -*- mode: perl; coding: iso-8859-1 -*-
#
# Author:      Peter John Acklam
# Time-stamp:  2013-03-02 12:40:43 +00:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

#########################

#use 5.008;              # for UTF-8 support
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
#use utf8;               # enable/disable UTF-8 (or UTF-EBCDIC) in source code

use lib 't';            # manipulate @INC at compile time

#########################

use Text::Unaccent::PurePerl;

#########################

my $data =
  [
   [
    "",
    "",
   ],
   [
    "naive",
    "naïve",
   ],
   [
    "deja vu",
    "déjà vu",
   ],
   [
    "Espana",
    "España",
   ],
   [
    "Francais",
    "Français",
   ],
   [
    "Citroen",
    "Citroën",
   ],
   [
    "Njal Saebo",
    "Njål Sæbø",
   ],
  ];

print "1..14\n";

my $testno = 0;

for (my $i = 0 ; $i <= $#$data ; ++ $i) {
    for (my $j = 0 ; $j <= 1 ; ++ $j) {
        ++ $testno;

        my $in           = $data->[$i][$j];
        my $out_expected = $data->[$i][0];

        my $out_actual   = unac_string($in);

        unless (defined $out_actual) {
            print "not ok ", $testno, "\n";
            print "  input ......: ", TestUtil::nice_string($in), "\n";
            print "  got ........: <UNDEF>\n";
            print "  expected ...: ", TestUtil::nice_string($out_expected), "\n";
            print "  error ......: the output is undefined\n";
            next;
        }

        unless ($out_actual eq $out_expected) {
            print "not ok ", $testno, "\n";
            print "  input ......: ", TestUtil::nice_string($in), "\n";
            print "  got ........: ", TestUtil::nice_string($out_actual), "\n";
            print "  expected ...: ", TestUtil::nice_string($out_expected), "\n";
            print "  error ......: the actual output is not identical to",
              " the expected output\n";
            next;
        }

        print "ok ", $testno, "\n";
    }
}
