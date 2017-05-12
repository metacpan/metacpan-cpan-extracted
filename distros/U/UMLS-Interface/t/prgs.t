#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

#  This scripts tests the functionality of the utils/ programs

use strict;
use warnings;

use Test::More tests => 52;

BEGIN{ use_ok ('File::Spec') }

my $perl     = $^X;
my $util_prg = "";

my $output   = "";

#######################################################################################
#  check the findLeastCommonSubsumer.pl program
#######################################################################################

$util_prg = File::Spec->catfile('utils', 'findLeastCommonSubsumer.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/Two terms and\/or CUIs are required\s+Type findLeastCommonSubsumer.pl --help for help\.\s+Usage\: findLeastCommonSubsumer\.pl \[OPTIONS\] \[CUI1\|TERM1\] \[CUI2\|TERM2\]\s*/);

#  check when only one input is given on the command line 
$output = `$perl $util_prg hand 2>&1`;
like ($output, qr/Two terms and\/or CUIs are required\s+Type findLeastCommonSubsumer.pl --help for help\.\s+Usage\: findLeastCommonSubsumer\.pl \[OPTIONS\] \[CUI1\|TERM1\] \[CUI2\|TERM2\]\s*/);


#######################################################################################
#  check the findCuiDepth.pl program with --maximum option
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'findCuiDepth.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg --maximum 2>&1`;
like ($output, qr/No term was specified on the command line\s+Type findCuiDepth.pl --help for help.\s+Usage\: findCuiDepth\.pl \[OPTIONS\] \[TERM\|CUI\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg --maximum C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getTermList\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the findCuiDepth.pl program with --minimum option
#####################################################################
##################
$util_prg = File::Spec->catfile('utils', 'findCuiDepth.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg --minimum 2>&1`;
like ($output, qr/No term was specified on the command line\s+Type findCuiDepth.pl --help for help.\s+Usage\: findCuiDepth\.pl \[OPTIONS\] \[TERM\|CUI\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg --minimum C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getTermList\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the findPathToRoot.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'findPathToRoot.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No term was specified on the command line\s+Type findPathToRoot.pl --help for help.\s+Usage\: findPathToRoot\.pl \[OPTIONS\] \[CUI\|TERM\]\s*/);

#  check when invalid CUI is entered 
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getTermList\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
$util_prg = File::Spec->catfile('utils', 'findShortestPath.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/Two terms and\/or CUIs are required\s+Type findShortestPath.pl --help for help.\s+Usage\: findShortestPath\.pl \[OPTIONS\] \[CUI1\|TERM1\] \[CUI2\|TERM2\]\s*/);

#  check when only one input is given on the command line 
$output = `$perl $util_prg 2>&1`;
like ($output, qr/Two terms and\/or CUIs are required\s+Type findShortestPath.pl --help for help.\s+Usage\: findShortestPath\.pl \[OPTIONS\] \[CUI1\|TERM1\] \[CUI2\|TERM2\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 hand 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getTermList\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the getChildren.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getChildren.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No term was specified on the command line\s+Type getChildren.pl --help for help.\s+Usage\: getChildren\.pl \[OPTIONS\] \[CUI\|TERM\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getAllPreferredTerm\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the getParents.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getParents.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No term was specified on the command line\s+Type getParents.pl --help for help.\s+Usage\: getParents\.pl \[OPTIONS\] \[CUI\|TERM\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getAllPreferredTerm\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the getCuiDef.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getCuiDef.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No term was specified on the command line\s+Type getCuiDef.pl --help for help.\s+Usage\: getCuiDef\.pl \[OPTIONS\] \[CUI\|TERM\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/\s*UMLS\-Interface Configuration Information\:\s*\(Default Information - no config file\)\s*Sources \(SAB\)\:\s*MSH\s*Relations \(REL\)\:\s*PAR\s*CHD\s*Sources \(SABDEF\)\:\s*UMLS\_ALL\s*Relations \(RELDEF\)\:\s*UMLS\_ALL\s*ERROR\:\s*UMLS\:\:Interface\:\:CuiFinder\-\>_getPreferredTerm\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the getRelated.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getRelated.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/A term and relation must be specified\s+Type getRelated.pl --help for help.\s+Usage\: getRelated\.pl \[OPTIONS\] \[CUI\|TERM\]\s*/);

#  check when only one input is specified on the  command line 
$output = `$perl $util_prg hand 2>&1`;
like ($output, qr/A term and relation must be specified\s+Type getRelated.pl --help for help.\s+Usage\: getRelated\.pl \[OPTIONS\] \[CUI\|TERM\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 SIB 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getTermList\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the getRelations.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getRelations.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No term was specified on the command line\s+Type getRelations.pl --help for help.\s+Usage\: getRelations\.pl \[OPTIONS\] \[CUI\|TERM\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getTermList\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the getSts.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getSts.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/At least 1 term or CUI should be given on the\s+command line or use the \-\-infile option\s+Type getSts.pl --help for help.\s+Usage\: getSts\.pl \[OPTIONS\] \[TERM\|CUI\]\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getTermList\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the getStDef.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getStDef.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No semantic type was specified on the command line\s+Type getStDef.pl --help for help.\s+Usage\: getStDef\.pl \[OPTIONS\] \<semantic type\>\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg dkj 2>&1`;
like ($output, qr/There are no definitions for the semantic type \(dkj\)/);

#######################################################################################
#  check the getAssociatedTerms.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getAssociatedTerms.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No CUI was specified on the command line\s+Type getAssociatedTerms.pl --help for help.\s+Usage\: getAssociatedTerms\.pl \[OPTIONS\] CUI\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getAllTerms\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);

#######################################################################################
#  check the getAssociatedCuis.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getAssociatedCuis.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No term was specified on the command line\s+Type getAssociatedCuis.pl --help for help.\s+Usage\: getAssociatedCuis\.pl \[OPTIONS\] TERM\s*/);

#  check when invalid term is entered
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/No CUIs are associated with C98\./);

#######################################################################################
#  check the getAssociatedTerms.pl program with the --config option
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getAssociatedTerms.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/No CUI was specified on the command line\s+Type getAssociatedTerms.pl --help for help.\s+Usage\: getAssociatedTerms\.pl \[OPTIONS\] CUI\s*/);

#  check when invalid CUI is entered
$output = `$perl $util_prg C98 2>&1`;
like ($output, qr/ERROR\: UMLS\:\:Interface\:\:CuiFinder\-\>_getAllTerms\s*Invalid CUI \(Error Code 6\)\.\s*Concept \(C98\) is not valid\./);
 
#######################################################################################
#  check the removeConfigData.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'removeConfigData.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/Configuration file was not specified on the command line\s+Type removeConfigData.pl --help for help.\s+Usage\: removeConfigData\.pl \[OPTIONS\] CONFIGFILE\s*/);

#######################################################################################
#  check the getCuiList.pl program
#######################################################################################
$util_prg = File::Spec->catfile('utils', 'getCuiList.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/Configuration file was not specified on the command line\s+Type getCuiList.pl --help for help.\s+Usage\: getCuiList\.pl \[OPTIONS\] CONFIGFILE\s*/);


