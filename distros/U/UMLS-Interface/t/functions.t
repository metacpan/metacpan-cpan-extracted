#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

#  This scripts tests all of the functions in Interface.pm


BEGIN { $| = 1; print "1..28\n"; }
END {print "not ok 1\n" unless $loaded;}

use UMLS::Interface;
$loaded = 1;
print "ok 1\n";

use strict;
use warnings;

#  initialize option hash
my %option_hash = ();

#  set the option hash
$option_hash{"realtime"} = 1;
$option_hash{"t"} = 1;

#  connect to the UMLS-Interface
my $umls = UMLS::Interface->new(\%option_hash);
if(!$umls) { print "not ok 2\n"; }
else       { print "ok 2\n";     }


######################################################################
#  test each function in the Interface.pm package
#
#  CUIs used in testing:
#    C0018563 = hand       (in MSH)
#    C0456081 = adjustment (not in MSH)
#    C0002807 = anatomy    (in MSH)
#    C0015385 = limbs      (in MSH)
#    C0000005 = i-maa      (in MSH but has no PAR/CHD relations)
#    C0005768 = blood      (in MSH with a definition)
#    C0016504 = feet
######################################################################
my $expected = "";
my $obtained = "";

#  check the root() function
$expected = "C0000000";
my @roots = $umls->root();
$obtained = shift @roots;
if($obtained ne $expected) { print "no ok 3\n"; }
else                       { print "ok 3\n";    }
    
#  check the depth() function
$expected = 0;
$obtained = $umls->depth();
if($obtained < $expected) { print "no ok 4\n"; }
else                      { print "ok 4\n";    }

#  check the version() function
$obtained = "";
$obtained = $umls->version();
if($obtained eq "") { print "no ok 5\n"; }
else                { print "ok 5\n";    }

#  check the exists() function
$expected = 1;
$obtained = $umls->exists("C0018563");
if($obtained != $expected) { print "no ok 6\n"; }
else                       { print "ok 6\n";    }
$expected = 0;
$obtained = $umls->exists("C0456081");
if($obtained != $expected) { print "no ok 7\n"; }
else                       { print "ok 7\n";    }

#  check the getRelated() function
my @siblings = $umls->getRelated("C0018563", "SIB");
if($#siblings < 0) { print "no ok 8\n"; }
else               { print "ok 8\n";    }
    
#  check the getTermList() function
my @terms = $umls->getTermList("C0018563");
if($#terms < 0) { print "no ok 9\n"; }
else            { print "ok 9\n";    }

#  check the getAllTerms() function
@terms = $umls->getAllTerms("C0018563");
if($#terms < 0) { print "no ok 10\n"; }
else            { print "ok 10\n";    }

#  check the getConceptList() function
my @cuis = $umls->getConceptList("hand");
if($#cuis < 0) { print "no ok 11\n"; }
else           { print "ok 11\n";    }

#  check the pathsToRoot() function
my @paths = $umls->pathsToRoot("C0002807");
if($#paths < 0) { print "no ok 12\n"; }
else            { print "ok 12\n";    }

#  check the getSab() function
my @sabs = $umls->getSab("C0018563");
if($#sabs < 0) { print "no ok 13\n"; }
else           { print "ok 13\n";    }

#  check the getChildren() function
my @children = $umls->getSab("C0018563");
if($#children < 0) { print "no ok 14\n"; }
else               { print "ok 14\n";    }

#  check the getParents() function
my @parents = $umls->getParents("C0018563");
if($#parents < 0) { print "no ok 15\n"; }
else              { print "ok 15\n";    }

#  check the getRelations() function
my @relations = $umls->getRelations("C0018563");
if($#relations < 0) { print "no ok 16\n"; }
else                { print "ok 16\n";    }

#  check the findMinimumDepth() function
my $mindepth = $umls->findMinimumDepth("C0018563");
if($mindepth=~/[0-9]+/) { print "ok 17\n";    }
else                    { print "no ok 17\n"; }

#  check the findMaximumDepth() function
my $maxdepth = $umls->findMaximumDepth("C0018563");
if($maxdepth=~/[0-9]+/) { print "ok 18\n";    }
else                    { print "no ok 18\n"; }

#  check the findShortestPath() function
my @spaths = $umls->findShortestPath("C0015385", "C0018563");
if($#spaths < 0) { print "no ok 19\n"; }
else             { print "ok 19\n";    }

#  check the findLeastCommonSubsumer() function
$expected = "C0015385";
my $lcses = $umls->findLeastCommonSubsumer("C0015385", "C0018563");
my $lcs = join " ", @{$lcses};
if($lcs=~/$expected/) { print "ok 20\n"; }
else                  { print "no ok 20\n";    }


#  check the exists() function
$expected = 1;
$obtained = $umls->exists("C0000005");
if($obtained ne $expected) { print "no ok 21\n"; }
else                       { print "ok 21\n";    }
$expected = 1;
$obtained = $umls->exists("C0015385");
if($obtained != $expected) { print "no ok 22\n"; }
else                       { print "ok 22\n";    }

#  check the getSt() function
$expected = "T023";
my $sts = $umls->getSt("C0018563");
$obtained = join " ", @{$sts};
if($obtained ne $expected) { print "no ok 23\n"; }
else                       { print "ok 23\n";    }

#  check the getStAbr() function
$expected = "bpoc";
$obtained = $umls->getStAbr("T023");
if($obtained ne $expected) { print "no ok 24\n"; }
else                       { print "ok 24\n";    }

#  check the getStString() function
$expected = "Body Part, Organ, or Organ Component";
$obtained = $umls->getStString("bpoc");
if($obtained ne $expected) { print "no ok 25\n"; }
else                       { print "ok 25\n";    }

#  check the getStDef() function
$obtained = "";
$obtained = $umls->getStDef("bpoc");
if($obtained eq "") { print "no ok 26\n"; }
else                { print "ok 26\n";    }

#  check the getCuiDef() function
$obtained = "";
$obtained = $umls->getCuiDef("C0005768");
if($obtained eq "") { print "no ok 27\n"; }
else                { print "ok 27\n";    }

#  check the returnTableNames() function
$obtained = $umls->returnTableNames();
my $keys = keys %{$obtained};
if($keys >= 0) { print "ok 28\n";    }
else           { print "no ok 28\n"; }


