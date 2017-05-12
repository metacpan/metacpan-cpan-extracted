
#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

#  This scripts tests all of the functions in Association.pm


BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use UMLS::Association;
$loaded = 1;
print "ok 1\n";

use strict;
use warnings;

#  initialize option hash
my %option_hash = ();

#  connect to the UMLS-Association
my $mmb = UMLS::Association->new(\%option_hash); 
die "Unable to create UMLS::Association object.\n" if(!$mmb);
if(!$mmb) { print "not ok 2\n"; }
else          { print "ok 2\n";     }

######################################################################
#  test each function in the Association.pm package
######################################################################
my $expected = "";
my $obtained = "";

#  check the exists function
$expected = "1";
$obtained = $mmb->exists("C0018081"); 
if($obtained ne $expected) { print "no ok 3\n"; }
else                       { print "ok 3\n";    }
    
#  check the getFrequency function
$obtained = $mmb->getFrequency("C0018081", "C0439665");
if(! ($obtained=~/[0-9]+/)) { print "no ok 4\n"; }
else                    { print "ok 4\n";    }

