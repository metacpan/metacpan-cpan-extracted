#!/usr/bin/perl
#*********************************************
#*              Insertion.pl                 *
#*                                           *
#*           Author: Jon Rusert              *
#*********************************************

use WordNet::QueryData;
use Wiktionary::Parser;

#If program is run without any passed arguments, show basic help
if($#ARGV < 0)
{
    printUsage();
    exit(0);
}

#If user enters help flag, print help
if($ARGV[0] =~ /--help/)
{
    printHelp();
    exit(0);
}

#If program does not have enough arguments, informs user of error.
if($#ARGV < 1)
{
    print "Input or Output missing!\n";
    print "Type Insertion.pl --help for help.\n";
    exit(0);
}

#**************Variables**********************
$tempIn = ""; #temporarily holds inLemma data as one string
@inLemma = ("", "", "", "", ""); #Current lemma to be inserted into WordNet 
                                 #inLemma's will hold the Lemma data as follows:
                                 #(lemma, part-of-speech, item-id, definition, def source)
@outLemma = ("", "", ""); #Stores proccessed lemma after insertion
                          #outLemma holds data as follows:
                          #(item-id, WordNet sense, operation)
$tempOut = ""; #temporarily stores processed lemma before inserting to file
$wn = WordNet::QueryData->new; #to be used to access data from wordnet
@wordNetNouns; #stores all words for noun sense from wordnet
@wordNetVerbs; #stores all words for verb sense from wordnet
%wnGlosses = ();
@wnNounSenses;
@wnVerbSenses;
%wnHypes = ();
%wnHypos = ();
%wnSyns = ();
%wnFreq = ();
%senseScores = (); #stores the scores of each sense, the highest scoring sense generally chosen as WordNet word.
$highSenseScore = 0; #stores highest sense score for comparison.
$highSense = ""; #stores highest scored sense.
$wikParser = Wiktionary::Parser->new(); #Parses data from wiktionary pages.
$attachMerge = "";
#*********************************************

$count =0;

#******************run()**********************
# Runs main insertion program.
#*********************************************
sub run()
{
    #Attempts to open trial data
    open TRIAL, "$ARGV[0]" or die $!;
    open (OUTTRIAL, '>', "$ARGV[1]") or die $!;
   
    preProcessing();
    
    while(<TRIAL>) #While lemmas are left in the trial data
    {
	for $tempIn (split("\n")) #processes data line by line.
	{
	    @inLemma = split("\t"); #stores lemma as formatted above
	    
	    processLemma();
	    
	    $tempOut = "$outLemma[0]\t$outLemma[1]\t$outLemma[2]\n";

	    print OUTTRIAL "$tempOut";
	    print "$tempOut";
	}
    }
}

#**************preProcessing()*****************
#* Highly increases speed of program by making
#*as many outside calls as possible and storing
#*outside info to be used later.
#**********************************************
sub preProcessing()
{
    @wordNetNouns = $wn->listAllWords('noun'); #Stores all nouns from wordNet for multiple uses.
    @wordNetVerbs = $wn->listAllWords('verb'); #Stores all verbs from wordNet for multiple uses.
    
    #Preemptively retrieves glosses, hypes, hypos, and syns for all senses as they will be used every iteration.
    foreach my $noun (@wordNetNouns)
    {
	my @nSenses = $wn->querySense("$noun\#n"); #gets all senses for that word
	foreach my $curNSense (@nSenses)
	{
	    #stores in noun senses to differentiate from verbs.
	    push(@wnNounSenses, $curNSense);

	    #obtain each gloss and clean up before inserting into hash.
	    my @nGlosses = $wn->querySense($curNSense, "glos");
	    my $tempSenseGloss = $nGlosses[0];
	    
	    #Clean up the words in the temporary sense gloss.
	    $tempSenseGloss =~ s/(\(|\)|\.)//g;
	    $tempSenseGloss =~ s/^a-zA-Z//g;
	    $tempSenseGloss = lc $tempSenseGloss; #converts all words to lowercase.
	    $tempSenseGloss =~ s/\b(the|is|at|which|on|a|an|and|or|up)\b//g; #remove stop words
	    
            #maps each sense to its gloss
	    $wnGlosses{$curNSense} = $tempSenseGloss;
	    
	    #obtains and stores, hypes, hypos, and syns
	    my @hypes = $wn->querySense($curNSense, "hype");
	    $wnHypes{$curNSense} = \@hypes;
	    my @hypos = $wn->querySense($curNSense, "hypo");
	    $wnHypos{$curNSense} = \@hypos;
	    my @syns = $wn->querySense($curNSense, "syns");
	    $wnSyns{$curNSense} = \@syns;
	    $wnFreq{$curNSense} = $wn->frequency($curNSense);
	}
    }

    #stores verbs' senses' glosses, hypes, hypos, and syns.
    foreach my $verb (@wordNetVerbs)
    {
	my @vSenses = $wn->querySense("$verb\#v"); #gets all senses for that word
	foreach my $curVSense (@vSenses)
	{
	    #stores in verb senses to differentiate later.
	    push(@wnVerbSenses, $curVSense);

	    #obtain each gloss and clean up before inserting into hash.
	    my @vGlosses = $wn->querySense($curVSense, "glos");
	    my $tempSenseGloss = $vGlosses[0];
	    
	    #Clean up the words in the temporary sense gloss.
	    $tempSenseGloss =~ s/(\(|\)|\.)//g;
	    $tempSenseGloss =~ s/^a-zA-Z//g;
	    $tempSenseGloss = lc $tempSenseGloss; #converts all words to lowercase.
	    $tempSenseGloss =~ s/\b(the|is|at|which|on|a|an|and|or|up)\b//g; #remove stop words
	    
	    #maps each sense to its gloss
	    $wnGlosses{$curVSense} = $tempSenseGloss;

	    #obtains and stores, hypes, hypos, and syns
	    my @hypes = $wn->querySense($curVSense, "hype");
	    $wnHypes{$curVSense} = \@hypes;
	    my @hypos = $wn->querySense($curVSense, "hypo");
	    $wnHypos{$curVSense} = \@hypos;
	    my @syns = $wn->querySense($curVSense, "syns");
	    $wnSyns{$curVSense} = \@syns;
	    $wnFreq{$curVSense} = $wn->frequency($curVSense);
	}
    }


}

#**************processLemma()******************
#* Determines where the OOV Lemma should be 
#*inserted into WordNet, stores the output in
#*@outLemma.
#**********************************************
sub processLemma()
{
    %senseScores = ();#reset sense scores hash
    $highSenseScore = 0; #reset hss.
    $highSense = ""; #reset

    if($inLemma[1] =~ /noun/)#only process nouns
    {
        foreach $curSense (@wnNounSenses) #runs through each sense of current word
	{
	    scoreSense();
	}
    }
    else#only process verbs
    {
	foreach $curSense (@wnVerbSenses)
	{
	    scoreSense();
	}
    }

    refineSense();
    
    if($wnFreq{$highSense} == 0)
    {
	$attachMerge = "attach";
    }
    else
    {
	$attachMerge = "merge";
    }

    $outLemma[0] = $inLemma[2];
    $outLemma[1] = $highSense;
    $outLemma[2] = $attachMerge;
}

#**************scoreSense()*********************
#* Calculates a score for the passed sense then
#*stores that score with the sense into %senseScores
#***********************************************
sub scoreSense()
{
    $word = substr($curSense, 0, index($curSense, '#')); #extracts base word.

    #_________________Sense Gloss_________________________________
    my @curSenseGloss = split (' ', $wnGlosses{$curSense}); #initialize current sense gloss. 
   
    #__________________Hype Gloss_________________________________
    #Now expands to hypernyms glosses in overlaps
    my @senseHypes = @{$wnHypes{$curSense}};
    my @senseHypeGloss = ();
    my $tempAllHypeGloss = "";
  
    for my $hype (0..$#senseHypes)
    {
	my $tempHypeGloss = $wnGlosses{$hype};
	
	$tempAllHypeGloss = $tempAllHypeGloss . " " . $tempHypeGloss;
    }

    @senseHypeGloss = split(' ', $tempAllHypeGloss);

        
    #________________Hypo Gloss__________________________________
    #adds in hyponyms' glosses in overlaps
    my @senseHypos = @{$wnHypos{$curSense}};
    my @senseHypoGloss = ();
    my $tempAllHypoGloss = "";
    
    for my $hypo (0..$#senseHypos)
    {
	my $tempHypoGloss = $wnGlosses{$hypo};
	
	$tempAllHypoGloss = $tempAllHypoGloss . " " . $tempHypoGloss;
    }

    @senseHypoGloss = split(' ', $tempAllHypoGloss);


    #_________________Syns Gloss_________________________________
    #adds in synsets' glosses in overlaps
    my @senseSyns = @{$wnSyns{$curSense}};
    my @senseSynsGloss = ();
    my $tempAllSynsGloss = "";

    for my $syns (0..$#senseSyns)
    {
	if(!($syns =~ /\b$word\b/)) #do not repeat sense
	{
	    my $tempSynsGloss = $wnGlosses{$syns};
	
	    $tempAllSynsGloss = $tempAllSynsGloss . " " . $tempSynsGloss;
	}
    }

    @senseSynsGloss = split(' ', $tempAllSynsGloss);


    #________________Lemma Gloss_________________________________
    my $tempLemmaGloss = $inLemma[3];

    #Clean up the words in the temp lemma gloss.
    $tempLemmaGloss =~ s/(\(|\)|\.)//g;
    $tempLemmaGloss =~ s/^a-zA-Z//g;
    $tempLemmaGloss = lc $tempLemmaGloss;
    $tempLemmaGloss =~ s/\b(the|is|at|which|on|a|an|and|or|up)\b//g; #remove stop words
    
    my @curLemmaGloss = split(' ', $tempLemmaGloss);


    #__________________Overlaps__________________________________
    my $glossLength = 0;#(scalar @curSenseGloss) + (scalar @curLemmaLength) + (scalar @senseHypeGloss) + (scalar @senseHypoGloss) + (scalar @senseSynsGloss) + 1; #stores length of current gloss + current lemma + hype gloss + hypo gloss.
    my $overlaps = 0.0; #number of overlapped words.

    #scan through each word from the sense gloss and see if any overlap on the lemma gloss.
    for my $lWord (0..$#curLemmaGloss)
    {
	$glossLength = $glossLength + length $curLemmaGloss[$lWord];
	if($curLemmaGloss[$lWord] =~ /\b$word\b/) #if lemma contains current word from sense itself
	{
	    $overlaps = $overlaps + 10*(length $word);
	}
	
	$spaceWord = $word;
	$spaceWord =~ s/_/ /g; #substitute underscores for spaces for comparison below
	if($spaceWord =~ /(^\w+\s\b$curLemmaGloss[$lWord]\b$)|(^\b$curLemmaGloss[$lWord]\b\s\w+$)/)
	{
	    $overlaps = $overlaps + 2*(length $curLemmaGloss[$lWord]);
	}

	for my $sWord (0..$#curSenseGloss)
	{
	    if($curLemmaGloss[$lWord] =~ /\b\Q$curSenseGloss[$sWord]\E\b?/)
	    {
		$overlaps = $overlaps + length $curSenseGloss[$sWord];
	    }
	}
	for my $hypeWord (0..$#senseHypeGloss)
	{
	    if($curLemmaGloss[$lWord] =~ /\b\Q$senseHypeGloss[$hypeWord]\E\b?/)
	    {
		$overlaps = $overlaps + length $senseHypeGloss[$hypeWord];
	    }
	}
	for my $hypoWord (0..$#senseHypoGloss)
	{
	    if($curLemmaGloss[$lWord] =~ /\b\Q$senseHypoGloss[$hypoWord]\E\b?/)
	    {
		$overlaps = $overlaps + length $senseHypeGloss[$hypoWord];
	    }
	}
	for my $synsWord (0..$#senseSynsGloss)
	{
	    if($curLemmaGloss[$lWord] =~ /\b\Q$senseSynsGloss[$synsWord]\E\b?/)
	    {
		$overlaps = $overlaps + length $senseSynsGloss[$synsWord];
	    }
	}
    }

    

    $score = $overlaps/$glossLength;
    if($score >= $highSenseScore)
    {
	$highSenseScore = $score;
	$highSense = $curSense;
	
    }
	
    $senseScores{$curSense} = $score;
}

#*************refineSense()********************
#* Refines chosen sense, by determing which
#*numbered sense should be chosen.
#**********************************************
sub refineSense()
{
    $word = substr($highSense, 0, index($highSense, '#')); #extracts base word.
    $shortSense = substr($inLemma[1], 0, 1);
    $sense = $word . "#" . $shortSense;
    $highSenseScore = 0;
    my $rSenseScore = 0;
    my $refineHigh = "$sense#1"; #assume first sense.
    my $tempLemmaGloss = $inLemma[3];
    
    #Clean up the words in the temp lemma gloss.
    $tempLemmaGloss =~ s/(\(|\)|\.)//g;
    $tempLemmaGloss =~ s/^a-zA-Z//g;
    $tempLemmaGloss = lc $tempLemmaGloss;
    $tempLemmaGloss =~ s/\b(the|is|at|which|on|a|an|and|or|up)\b//g; #remove stop words
    
    my @refineLemmaGloss = split(' ', $tempLemmaGloss);
    
    my $rGlossLength = 0.0;
    my $rOverlaps = 0.0;
    my @refineSenses = $wn->querySense($sense); #obtains the other senses for the same word.
    for my $rSense (0..$#refineSenses)
    {
	my $tempSenseGloss = $wnGlosses{$rSense};
	
	for my $rLemma (0..$#refineLemmaGloss)
	{
	    $rGlossLength = $rGlossLength + length $refineLemmaGloss[$rLemma];
	    if($refineLemmaGlos[$rLemma] ne $word)
	    {
		if($tempSenseGloss =~ /$refineLemmaGloss[$rLemma]/)
		{
		    $rOverlaps = $rOverlaps + length $refineLemmaGloss[$rLemma];
		}
	    }
	   
	}

	$rSenseScore = $rOverlaps/$rGlossLength;
	if($rSenseScore > $highSenseScore)
	{
	    $highSenseScore = $rSenseScore;
	    $refineHigh = $rHypo;
	}
    }
    
    $highSense = $refineHigh;

    
}

#*************printUsage()*********************
# Prints basic program usage to screen.
#**********************************************
sub printUsage()
{
    print "Usage: Insertion.pl DATA SOURCE | DESTINATION SOURCE\n";
    print "\tType Insertion.pl --help for help.\n";
}

#**************printHelp()**********************
# Prints indepth help guide to screen.
#***********************************************
sub printHelp()
{
    printUsage();
    print "Takes in lemmas from file and attempts to\n";
    print "insert them into WordNet by first finding\n";
    print "a hypernym, then either a) merging the   \n";
    print "lemma with the hypernym or b) attaching  \n";
    print "the lemma to the hypernym.\n";
}

run();

