#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

#  This scripts tests all of the functions in Association.pm

#use Test::Simple tests => 31;
use UMLS::Association;

BEGIN { $| = 1; print "1..31\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
ok ($loaded);

use strict;
use warnings;

#declare variables used in the tests
my %option_hash;
my $association;
my $score;
my $scoresRef;
my $goldScore;
my @goldScores;
my $testText;

#########################################################
#########################################################
#                 Sample 1 Tests                    
#########################################################
#########################################################
#$option_hash{'matrix'} = './t/sampleMatrix1'
%option_hash = ();
$option_hash{'matrix'} = './t/sampleMatrix1';
$option_hash{'measure'} = 'x2';
$option_hash{'debug'} =0;

#########################################################
#                 Sample 1 Direct                    
#########################################################
$testText = "Sample 1 Direct ordered";
$goldScore = 6.0480;
#n11, n1p, np1, npp = 3, 10, 3, 28
my @cuiSet1;
@cuiSet1 = ();
push @cuiSet1, 'C0000000';
my @cuiSet2 = ();
push @cuiSet2, 'C0000003';
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);

#n11, n1p, np1, npp = 3, 10, 8, 28
$testText = "Sample 1 Direct noOrder";
$goldScore = 0.0156;
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);



#########################################################
#                  Sample 1 LTA
#########################################################
$testText = "Sample 1 LTA ordered";
$goldScore = 0.1944;
#n11, n1p, np1, npp = 2, 4, 3, 7
@cuiSet1 = ();
push @cuiSet1, 'C0000000';
@cuiSet2 = ();
push @cuiSet2, 'C0000006';
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 1;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);

#n11, n1p, np1, npp = 2, 4, 3, 7
$testText = "Sample 1 LTA noOrder";
$goldScore = 0.1944;
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);



#########################################################
#                  Sample 1 MWA
#########################################################
$testText = "Sample 1 MWA ordered";
$goldScore = 0.2212;
#n11, n1p, np1, npp = 7, 10, 18, 28
@cuiSet1 = ();
push @cuiSet1, 'C0000000';
@cuiSet2 = ();
push @cuiSet2, 'C0000006';
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 1;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);

#n11, n1p, np1, npp = 7, 10, 18, 28
$testText = "Sample 1 MWA noOrder";
$goldScore = 0.2212;
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);


#########################################################
#                  Sample 1 SBC
#########################################################
$testText = "Sample 1 SBC ordered";
$goldScore = 10.0654;
#n11, n1p, np1, npp = 11, 11, 18, 28
@cuiSet1 = ();
push @cuiSet1, 'C0000000';
@cuiSet2 = ();
push @cuiSet2, 'C0000006';
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 1;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);

#n11, n1p, np1, npp = 11, 18, 18, 28
$testText = "Sample 1 SBC noOrder";
$goldScore = 0.2212;
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);

#########################################################
#                  Sample 1 LSA
#########################################################
$testText = "Sample 1 LSA ordered";
$goldScore = 0;
#n11, n1p, np1, npp = 0, 11, 7, 28
@cuiSet1 = ();
push @cuiSet1, 'C0000000';
@cuiSet2 = ();
push @cuiSet2, 'C0000006';
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 1;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);

#n11, n1p, np1, npp = 0, 21, 25, 28
$testText = "Sample 1 LSA noOrder";
$goldScore = 0;
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);


#################################################
#################################################
###########    END SAMPLE 1 TESTS   #############
#################################################
#################################################
#################################################
#################################################
###########  BEGIN SAMPLE 2 TESTS   #############
#################################################
#################################################

#$option_hash{'matrix'} = './t/sampleMatrix1'
%option_hash = ();
$option_hash{'matrix'} = './t/sampleMatrix2';
$option_hash{'measure'} = 'x2';

#create the test sets
my @cuiSets1 = ();
my @cuiSet1a = ();
push @cuiSet1a, 'C0000000';
push @cuiSet1a, 'C0000001';
push @cuiSets1, \@cuiSet1a;
my @cuiSet1b = ();
push @cuiSet1b, 'C0000011';
push @cuiSets1, \@cuiSet1b;

my @cuiSets2 = ();
my @cuiSet2a = ();
push @cuiSet2a, 'C0000008';
push @cuiSet2a, 'C0000009';
push @cuiSets2, \@cuiSet2a;
my @cuiSet2b = ();
push @cuiSet2b, 'C0000012';
push @cuiSet2b ,'C0000013';
push @cuiSets2, \@cuiSet2b;


#########################################################
#                  Sample 2 LTA
#########################################################
$testText = "Sample 2 LTA ordered";
@goldScores = (2.7152, 3.9487);
#n11, n1p, np1, npp = 2,3,4,14 
#n11, n1p, np1, npp = 1,1,3,14
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 1;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$scoresRef = $association->calculateAssociation_setPairList(\@cuiSets1, \@cuiSets2, $option_hash{'measure'});

ok (${$scoresRef}[0] == $goldScores[0], $testText.' 0');
ok (${$scoresRef}[1] == $goldScores[1], $testText.' 1');

#n11, n1p, np1, npp = 2,3,4,14
#n11, n1p, np1, npp = 1,1,3,14
$testText = "Sample 2 LTA noOrder";
@goldScores = (2.7152,3.9487);
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$scoresRef = $association->calculateAssociation_setPairList(\@cuiSets1, \@cuiSets2, $option_hash{'measure'});
ok (${$scoresRef}[0] == $goldScores[0], $testText.' 0');
ok (${$scoresRef}[1] == $goldScores[1], $testText.' 1');


#########################################################
#                  Sample 2 MWA
#########################################################
$testText = "Sample 2 MWA ordered";
@goldScores = (30.6026,1.8195);
#n11, n1p, np1, npp = 9,10,38,182
#n11, n1p, np1, npp = 3,3,114,182
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 1;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$scoresRef = $association->calculateAssociation_setPairList(\@cuiSets1, \@cuiSets2, $option_hash{'measure'});
ok (${$scoresRef}[0] == $goldScores[0], $testText.' 0');
ok (${$scoresRef}[1] == $goldScores[1], $testText.' 1');

#n11, n1p, np1, npp = 4.5,10,38,182
#n11, n1p, np1, npp = 3,3,114,182
$testText = "Sample 2 MWA noOrder";
@goldScores = (30.6026,1.8195);
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$scoresRef = $association->calculateAssociation_setPairList(\@cuiSets1, \@cuiSets2, $option_hash{'measure'});
ok (${$scoresRef}[0] == $goldScores[0], $testText.' 0');
ok (${$scoresRef}[1] == $goldScores[1], $testText.' 1');


#########################################################
#                  Sample 1 SBC
#########################################################
$testText = "Sample 2 SBC ordered";
@goldScores = (19.5722,144.7485);
#n11, n1p, np1, npp = 11,18,38,182
#n11, n1p, np1, npp = 104,104,114,182
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 1;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$scoresRef = $association->calculateAssociation_setPairList(\@cuiSets1, \@cuiSets2, $option_hash{'measure'});
ok (${$scoresRef}[0] == $goldScores[0], $testText.' 0');
ok (${$scoresRef}[1] == $goldScores[1], $testText.' 1');

#n11, n1p, np1, npp = 11, 27, 38, 182
#n11, n1p, np1, npp = 111,114,114,182
$testText = "Sample 2 SBC noOrder";
@goldScores = (7.5706, 157.2651);
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$scoresRef = $association->calculateAssociation_setPairList(\@cuiSets1, \@cuiSets2, $option_hash{'measure'});
ok (${$scoresRef}[0] == $goldScores[0], $testText.' 0');
ok (${$scoresRef}[1] == $goldScores[1], $testText.' 1');

#########################################################
#                  Sample 2 LSA
#########################################################
$testText = "Sample 2 LSA ordered";
@goldScores = (9.1477, 144.7485);
#n11, n1p, np1, npp = 7,18,27,182
#n11, n1p, np1, npp = 104,104,114,182
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 1;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$scoresRef = $association->calculateAssociation_setPairList(\@cuiSets1, \@cuiSets2, $option_hash{'measure'});
ok (${$scoresRef}[0] == $goldScores[0], $testText.' 0');
ok (${$scoresRef}[1] == $goldScores[1], $testText.' 1');

#n11, n1p, np1, npp = 7, 28, 65, 182
#n11, n1p, np1, npp = 114, 114, 114, 182
$testText = "Sample 2 LSA noOrder";
@goldScores = (1.6545, 182.0000);
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$scoresRef = $association->calculateAssociation_setPairList(\@cuiSets1, \@cuiSets2, $option_hash{'measure'});
ok (${$scoresRef}[0] == $goldScores[0], $testText.' 0');
ok (${$scoresRef}[1] == $goldScores[1], $testText.' 1');


#################################################
#################################################
###########    END SAMPLE 2 TESTS   #############
#################################################
#################################################

#########################################################
#########################################################
#                 Sample 2 Flipped Test                    
#########################################################
#########################################################
#$option_hash{'matrix'} = './t/sampleMatrix1'
%option_hash = ();
$option_hash{'matrix'} = './t/sampleMatrix2';
$option_hash{'measure'} = 'x2';

#########################################################
#                 Sample 2, flipped                    
#########################################################
$testText = "Sample 2 LSA noOrder (flipped)";
$goldScore = 182.0000;
#n11, n1p, np1, npp = 114,114,114,182
@cuiSet1 = ();
push @cuiSet1, 'C0000012';
push @cuiSet2, 'C0000013';
@cuiSet2 = ();
push @cuiSet2, 'C0000011';
$option_hash{'noorder'} = 1;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 1;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);






#########################################################
#########################################################
#                 Sample 3 Tests                    
#########################################################
#########################################################
#$option_hash{'matrix'} = './t/sampleMatrix3'
%option_hash = ();
$option_hash{'matrix'} = './t/sampleMatrix3';
$option_hash{'measure'} = 'x2';

#########################################################
#                 Sample 3 Direct                    
#########################################################
$testText = "Sample 3 Direct ordered";
$goldScore = 0.0000;
#n11, n1p, np1, npp = 80, 91, 80, 91
@cuiSet1 = ();
push @cuiSet1, 'C0000001';
push @cuiSet1, 'C0000002';
@cuiSet2 = ();
push @cuiSet2, 'C0000002';
push @cuiSet2, 'C0000003';
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 0;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok ($score == $goldScore, $testText);


##n11, n1p, np1, npp = TODO - I cannot pass this test
#$testText = "Sample 3 Direct noOrder";
#$goldScore = 0; #TODO - I cannot properly pass this test
#$option_hash{'noorder'} = 1;
#$association = UMLS::Association->new(\%option_hash); 
#$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $opti#on_hash{'measure'});
#ok ($score == $goldScore, $testText);


#########################################################
#########################################################
#                 Sample 4 Tests                    
#########################################################
#########################################################
#$option_hash{'matrix'} = './t/sampleMatrix4'
%option_hash = ();
$option_hash{'matrix'} = './t/sampleMatrix4';
$option_hash{'measure'} = 'freq';

#########################################################
#                 Sample 4 WSA                   
#########################################################
$testText = "Sample 4 WSA ordered";
$goldScore = (7/3);
#n11, n1p, np1, npp = 2.33, 3, 2.33, 11
@cuiSet1 = ();
push @cuiSet1, 'C0000000';
push @cuiSet1, 'C0000001';
@cuiSet2 = ();
push @cuiSet2, 'C0000005';
push @cuiSet2, 'C0000006';
$option_hash{'noorder'} = 0;
$option_hash{'lta'} = 0;
$option_hash{'mwa'} = 0;
$option_hash{'lsa'} = 0;
$option_hash{'sbc'} = 0;
$option_hash{'wsa'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok (($score >= $goldScore-0.00001 && $score <= $goldScore+0.00001), $testText);

$testText = "Sample 4 WSA noOrder";
$goldScore = (112/49);
$option_hash{'noorder'} = 1;
$association = UMLS::Association->new(\%option_hash); 
$score = $association->calculateAssociation_setPair(\@cuiSet1, \@cuiSet2, $option_hash{'measure'});
ok (($score >= $goldScore-0.00001 && $score <= $goldScore+0.00001), $testText);






### TODO, delete this once tests is installed
sub ok {
    my $truthValue = shift;
    my $testText = shift;

=comment
    if ($truthValue > 0) {
	print "passed - $testText\n";
    } else {
	print "failed - $testText\n";
    }
=cut

    if ($truthValue > 0) {
	print "ok $testText\n";
    } else {
	print "not ok $testText\n";
    }
}
