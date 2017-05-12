# $Id: wsd.t,v 1.7 2009/02/13 13:53:44 kvarada Exp $
#
# simple test script for wsd.pl

# these tests were written for version 2.0 of WordNet 
# and don't seem to have required changes for version 2.1
# or 3.0. However, do not add to these test cases, create
# a new .t and tailor it to a specific version. We'll
# skip the entire test if we aren't at version 2.0 or better

# set WordNet version constants - these are hashcodes obtained
# from WordNet::Tools because WordNet doesn't keep track of it's
# version reliably

use constant WNver20 => 'US9EUGPpJj2jVr+fRrZqQX6vcGs';
use constant WNver21 => 'LL1BZMsWkr0YOuiewfbiL656+Q4';
use constant WNver30 => 'eOS9lXC6GvMWznF1wkZofDdtbBU';

# find out what version of wordnet we are using and print that 
# the hashcode will tell us the version

use WordNet::SenseRelate::AllWords;
use WordNet::QueryData;
use WordNet::Tools;

my $qd = WordNet::QueryData->new;
my $wntools = WordNet::Tools->new($qd);
$wnHashCode = $wntools->hashCode();

# skip all these tests if Wordnet version is not 2.0 2.1 or 3.0

use Test::More;
if ( !($wnHashCode eq WNver20) && 
     !($wnHashCode eq WNver21) && 
     !($wnHashCode eq WNver30)) {
 	plan skip_all => 'WordNet version is not 2.0 2.1 3.0 -> skip tests'; 
     }
else {
	plan tests => 5;
     }

use File::Spec;
my $tmp = File::Spec->tmpdir;

my $wsd_pl = File::Spec->catfile ('utils', 'wsd.pl');
ok (-e $wsd_pl);

my $inc = "-Iblib/lib";
my $expected = 'parking_tickets#n#1 are#v#1 expensive#a#1 ';

# test the tagged mode
my $t1in = File::Spec->catfile ($tmp, "$$.1in");
ok (open (IN, '>', $t1in));
print IN "parking_tickets/NNS are/VBP expensive/JJ";
close IN;

$output = `$^X $inc $wsd_pl --context $t1in --format tagged --type WordNet::Similarity::lesk`;
chomp $output;
is ($output, $expected);

# test raw mode
my $t2in = File::Spec->catfile ($tmp, "$$.2in");
ok (open (IN, '>', $t2in));

# bad grammar, but it does test the script nicely
print IN "parking_tickets, are expensive.";

close IN;

$output = `$^X $inc $wsd_pl --context $t2in --format raw --type WordNet::Similarity::lesk`;
chomp $output;
is ($output, $expected);

unlink $t1in;
unlink $t2in;

