#!/usr/local/bin/perl
##################################################################
# Postprocessing script for GMA alignment
# <align file> contains entries as i,j,...k <=> l,m,...n
#script places lines i, j,... k from  file1 in file1.a
#lines l,m,...n from  file2 in file2.a
#results in file1.a and file2.a being aligned files
# optional parameters:
# threshold: pring the names of the files when more than threshold %
#   of the lines are missing
# -s parameter for just statistics, do not generate aligned files
# if the following parameters are specified, 
# print error message if a string is missing and it is not marked 'omitted' and the line is not empty
# and some word in the line is found in the lexicon
# file1 morph - morpholised version of text1 (that was used for axis generation
# file2 morph - morpholised version of text2 (that was used for axis generation
# file1 lexicon 
# file2 lexicon
# 
##################################################################


if($#ARGV<2)
{
    print "usage $0 <align file> <text1> <text2> [<threshold> <-e> <file1 morph> <file2 morph> <file1 lexicon> <file2 lexicon>]\n";
    exit 0;
}

$statonly  = 0;
if($ARGV[4] eq '-s')
{
    $statonly = 1;
}


#empty lines from file 1
$cnt = 0;
open(F1, $ARGV[1]);
while(<F1>)
{
    $cnt++;
    $emptyF1{$cnt} = 1 if(length($_)<=2);
    
}

close(F1);
#empty lines from file 2
$cnt = 0;
open(F2, $ARGV[2]);
while(<F2>)
{
    $cnt++;
    $emptyF2{$cnt} = 1 if(length($_)<=2);
}

close(F2);


open(ALIGN, $ARGV[0]);

$lang1 =  $ARGV[1];
$lang2  =  $ARGV[2];
$thresh = $ARGV[3];
$lang1morph =  $ARGV[5];
$lang2morph  =  $ARGV[6];
$lang1lex = $ARGV[7];
$lang2lex = $ARGV[8];
#$dir = $ARGV[3];

#read in lang1 lexicon
undef $/;
open(F1, $lang1lex) || die "Couldn't open $lang1lex: $!\n";
$lang1lexdata = <F1>;
close(F1);
open(F2, $lang2lex) || die "Couldn't open $lang2lex: $!\n";
$lang2lexdata = <F2>;
close(F2);
$/ = "\n";

if(!($statonly))
{
    system("rm $lang1.a")  if(-f "$lang1.a" );
    system("rm $lang2.a")  if(-f "$lang2.a" );
#exit 0 if(-f "$lang1.a" );
#exit 0 if(-f "$lang2.a" );
}

while(<ALIGN>)
{
#    print stderr $_;
    chop;
    @align = split '<=>';
    @l1  = split ',',$align[0];
    @l2   = split ',',$align[1];

    if($align[0]=~/omitted/ || $align[1] =~ /omitted/)
    {
	#print "omitted $align[0] $align[1]\n";
	foreach $l(@l1){
	    $l1_omit[$l]++;	
	}
	foreach $l(@l2){
	    $l2_omit[$l]++;	
	}


    }
    else
    {    
	foreach $l(@l1){
	    system("sellinesnonewline $l $l $lang1 >>  $lang1.a") if(!($statonly));
	    $l1_check[$l]++;	
	}

	foreach $l(@l2){
	    system("sellinesnonewline $l $l $lang2 >>  $lang2.a") if(!($statonly));
	    $l2_check[$l]++;
	}

	system("echo ''>>  $lang1.a");
	system("echo ''>>  $lang2.a");
	
    }
}


$numlines1 = `wc -l $lang1`;
$numlines2 = `wc -l $lang2`;

##################################################################################################
# print error message if a string is missing and it is not marked 'omitted' and the line is not empty
# and some word in the line is found in the lexicon
##################################################################################################

for($i = 1; $i<=$numlines1; $i++)
{
    if($l1_check[$i]==0 && $l1_omit[$i] == 0 && !(exists $emptyF1{$i}) )
    {
    #print "$lang1 missing $i\n";
    $str  = `head -$i $lang1morph | tail -1`;
    @words = split " ", $str;
    $found = 0;
    foreach $w(@words)
    {
	$found = 1 if($lang1lexdata =~ /\b\Q$w\E\b/)	   	    
    }

    if($found){
	print  "$lang1 missing $i:$str\n"; 
	$missing1++;
    }

    #exit 0;
    }
}

for($i = 1; $i<=$numlines2; $i++)
{
    if($l2_check[$i]==0 && $l2_omit[$i] == 0 && !(exists $emptyF2{$i}))
    {
    #print "$lang2 missing $i\n";
     $str  = `head -$i $lang2morph | tail -1`;
    @words = split " ", $str;
    $found = 0;
    foreach $w(@words)
    {
	$found = 1 if($lang2lexdata =~ /\b\Q$w\E\b/)	   	    
    }

    if($found){	
	print "$lang2 missing $i:$str\n";
	$missing2++;
    }
    #exit 0;
    }
}

print("$lang1\n") if($missing1/$numlines1 > $thresh);
print("$lang2\n") if($missing2/$numlines2 > $thresh);   
