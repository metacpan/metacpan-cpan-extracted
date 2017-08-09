# WordNet::Extend::Locate.pm version 0.041
# Updated: 08/06/17
#                                           
# Jon Rusert, University of Minnesota Duluth
# ruse0008 at d.umn.edu
#
# Ted Pedersen, University of Minnesota Duluth             
# tpederse at d.umn.edu
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package WordNet::Extend::Locate;

=head1 NAME

WordNet::Extend::Locate - Perl modules for locating where in WordNet a 
lemma should be inserted.

=head1 SYNOPSIS

=head2 Basic Usage Example

use WordNet::Extend::Locate;

 my $locate = WordNet::Extend::Locate->new();

 $locate->stopList('(the|is|at)');

 $locate->setCleanUp(1);

 $locate->preProcessing();

 $locate->toggleCompareGlosses(1,1,0);

 $locate->setBonus(25);

 $locate->toggleRefineSense(0);

 print "Finding location for 'dog noun withdef.1 man's best friend'\n"; 

 @location = @{$locate->locate("dog\tnoun\twithdef.1\tman\'s best friend")};

 print "Location found: @location\n";

=head1 DESCRIPTION

=head2 Introduction

WordNet is a widely used tool in NLP and other research areas. A drawback of WordNet is the amount of time between updates. WordNet was last updated and released in December, 2006, and no further updates are planned. WordNet::Extend::Locate aims to help users decide where a good place to insert new lemmas into WordNet is by presenting several different methods to run. Users can then take the suggestion from Locate and use that with WordNet::Extend::Insert or simply use it as a guiding point and choose their own location.

=over
=cut

use WordNet::QueryData;
#use Wiktionary::Parser;
use Getopt::Long;
use File::Spec;
use Lingua::Stem;
use Lingua::EN::Tagger;
use WordNet::Similarity::vector;
#use List::Util;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw(Exporter);

%EXPORT_TAGS = ();

@EXPORT_OK = ();

@EXPORT = ();

$VERSION = '0.041';

#**************Variables**********************
$wn = WordNet::QueryData->new; #to be used to access data from wordnet
$stemmer = Lingua::Stem->new; #used to stem words for better overlaps etc.
$tagger = Lingua::EN::Tagger->new; #used to tag words' pos for similarity measure
$measure = WordNet::Similarity::vector->new ($wn); #used to measure similarity for Similarity
@wordNetNouns; #stores all words for noun sense from wordnet
@wordNetVerbs; #stores all words for verb sense from wordnet
%wnGlosses = ();
@wnNounSenses;
@wnVerbSenses;
%wnHypes = ();
%wnHypos = ();
%wnSyns = ();
%wnFreq = ();
#our $wikParser = Wiktionary::Parser->new(); #Parses data from wiktionary pages.
#$stopList = "(the|is|at|which|on|a|an|and|or|up|in|so)"; #default stop list.
$stopList = "(a|about|above|after|again|against|all|am|an|and|any|are|aren't|as|at|be|because|been|before|being|below|between|both|but|by|can't|cannot|could|couldn't|did|didn't|do|does|doesn't|doing|don't|down|during|each|few|for|from|further|had|hadn't|has|hasn't|have|haven't|having|he|he'd|he'll|he's|her|here|here's|hers|herself|him|himself|his|how|how's|i|i'd|i'll|i'm|i've|if|in|into|is|isn't|it|it's|its|itself|let's|me|more|most|mustn't|my|myself|no|nor|not|of|off|on|once|only|or|other|ought|our|ours|ourselves|out|over|own|same|shan't|she|she'd|she'll|she's|should|shouldn't|so|some|such|than|that|that's|the|their|theirs|them|themselves|then|there|there's|these|they|they'd|they'll|they're|they've|this|those|through|to|too|under|until|up|very|was|wasn't|we|we'd|we'll|we're|we've|were|weren't|what|what's|when|when's|where|where's|which|while|who|who's|whom|why|why's|with|won't|would|wouldn't|you|you'd|you'll|you're|you've|your|yours|yourself|yourselves)";
$preProcessed = 0; #Flag to determine if preProcessing() has been called.
$cleanUp = 1; #If cleanUp is on, glosses will be cleanedUp, can be toggled with setCleanUp();
$userCleanUp = ""; #Cleanup step specified by user in addCleanUp();
$useHypeGlosses = 1; #Toggle for use of hypernym glosses in comparisons.
$useHypoGlosses = 1; #Toggle for use of hyponym glosses in comparisons.
$useSynsGlosses = 1; #Toggle for use of synset glosses in comparisons.
$bonus = 10; #Bonus to be used for lemmas that contain the new lemma. Can be set with setBonus();
$refineSense = 0; #Toggle for use of refineSense() method, default on.
$help = 0;
$scoringMethod = 'baseline';
@scoringMethods = ('baseline', 'BwS', 'Similarity', 'Word2Vec');
$stemming = 0; #Toggle for stemming on or off.
$stemmed = 0; #flag for use in BwS
$cValue = 0; #Confidence value for w2veccompare can be set in setConfidenceValue()
#*********************************************

GetOptions('help' => \$help);
if($help == 1)
{
    printHelp();
    exit(0);
}

=head2 Methods

The following methods are defined in this package:

=head3 Public methods

=over

=item $obj->new()

The constructor for WordNet::Extend::Locate objects.

Parameters: none.

Return value: the new blessed object

=cut

sub new
{
    my $class = shift;
    my $self = {};

    $self->{errorString} = '';
    $self->{error}=0;

    bless $self, $class;
    
    return $self;
}

=item $obj->getError()

Allows the object to check if any errors have occurred.
Returns an array ($error, $errorString), where $error 
value equal to 1 represents a warning and 2 represents
an error and $errString contains the possible error.
For example, if a user forgets to run preProcessing() before
a method that relies on it, the error would be 2 and errorString
would mention that preProcessing had not been run.

Parameter: None

Returns: array of the form ($error, $errorString).

=cut
sub getError()
{
    my $self = shift;
    my $error = $self->{error};
    my $errString = $self->{errorString};
    $self->{error}=0;
    $self->{errorString} = "";
    $errString =~ s/^[\r\n\t ]+//;
    return ($error, $errString);
}

=item $obj->locateFile($input_file, $output_file)

Attempts to locate best WordNet position for each word 
from input file into WordNet, outputs results to output file.

Parameter: location of input file and output file respectively

Returns: nothing

=cut

sub locateFile()
{
    my $input = File::Spec->canonpath($_[1]);
    my $output = File::Spec->canonpath($_[2]);
    
    #Attempts to open input data
    open DATA, "$input" or die $!;
    open (OUTDATA, '>', "$output") or die $!;
   
    #if preProcessing() hasn't been called, call it.
    if($preProcessed == 0)
    {
	preProcessing();
    }

    my @outLemma = ("","","");

    while(<DATA>) #While lemmas are left in the input data
    {
	for $tempIn (split("\n")) #processes data line by line.
	{
	    @outLemma = @{locate($tempIn)};

	    if(scalar @outLemma > 0)#only print if ideal lemma found
	    {
		$tempOut = "$outLemma[0]\t$outLemma[1]\t$outLemma[2]\n";

		print OUTDATA "$tempOut";
	    }
	      
	}
    }
    close DATA;
    close OUTDATA;
}

=item $obj->locate($wordPosGloss)

Takes in single lemma with gloss and returns location of best 
insertion point in WordNet.

Parameter: Lemma string in format of 'word\tpos\titem-id\tdef'
NOTE: String must only be separated by \t no space.

Returns: Array in format of (item-id, WordNet sense, operation)

=cut
sub locate()
{
    my $base = 0; 
    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }

    #if preProcessing() hasn't been called, call it.
    if($preProcessed == 0)
    {
	preProcessing();
    }

    my @inLemma = ();
    if(ref($_[$base]) eq 'ARRAY') #distinguishes between lemmas sent in as array vs string in \t format
    {
	@inLemma =@{$_[$base]};
    }
    else
    {
	@inLemma = split("\t", $_[$base]); #stores lemma as formatted above 
    }

    my @outLemma = ();
    #word2vec handles all the wordnet words at once, while the other methods handle them one at a time
    if($scoringMethod eq 'Word2Vec')
    {
	@outLemma = @{word2VecCompare(\@inLemma)};
    }
    else
    {
	@outLemma = @{processLemma(\@inLemma)};
    }
    
    return \@outLemma;
    
}

=item $obj->stopList($newStopList)

Takes in new stop list, in regex form

Parameter:the new stop list in regex substitution form (w1|w2|...|wn)

Returns: nothing

=cut

sub stopList()
{
    my $base = 0; 
    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }
    my $tempStopList = $_[$base];
    if($tempStopList =~ /\(.*(\|.*)?\)/g)
    {
	$stopList = $tempStopList;
    }
    else
    {
	my $self = shift;
	$self->{error} = 1;
	$self->{errorString} = "Proposed stop list not in regex substition form (w1|w2|...|wn), default remains";
    }	
}

=item $obj->setCleanUp($switch)

Allows the user to toggle whether or not 
glosses should be cleaned up.

Parameter: 0 or 1 to turn clean up off or on respectively

Returns: nothing

=cut

sub setCleanUp()
{
    my $base = 0; 
    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }

    if($_[$base] == 0) #turns cleanUp off.
    {
	$cleanUp = 0;
    }
    else #turns cleanUp on.
    {
	$cleanUp = 1;
    }
}

=item $obj->addCleanUp($cleanUp)

Allows the user to add their own 
regex for cleaning up the glosses.

Parameter: Regex representing the cleanup
the user wants performed.

Returns: Nothing

=cut

sub addCleanUp()
{
    my $base = 0; 
    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }

    my $tempCleanUp = $_[$base];
    if($tempCleanUp =~ /(s|t)\/.*\/g?/g)
    {
	$userCleanUp = $tempCleanUp;
    }
    else
    {
	my $self = shift;
	$self->{error} = 1;
	$self->{errorString} = "Clean Up not in regex format '/.../', default remains on";
    }   
}

=item $obj->preProcessing()

Highly increases speed of program by making
as many outside calls as possible and storing
outside info to be used later.

Parameter: none

Returns: nothing
    
=cut

sub preProcessing()
{
    $preProcessed = 1; #Flag that preProcessing has been called.
    @wordNetNouns = $wn->listAllWords('noun'); #Stores all nouns from wordNet for multiple uses.
    @wordNetVerbs = $wn->listAllWords('verb'); #Stores all verbs from wordNet for multiple uses.
    #reset all glosses, senses, etc.
    %wnGlosses = ();
    @wnNounSenses;
    @wnVerbSenses;
    %wnHypes = ();
    %wnHypos = ();
    %wnSyns = ();
    %wnFreq = ();
    
    
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
	    
	    if($cleanUp == 1)
	    {
		#Clean up the words in the temporary sense gloss.
		$tempSenseGloss =~ s/(\(|\)|\.)//g;
		$tempSenseGloss =~ s/^a-zA-Z//g;
		$tempSenseGloss = lc $tempSenseGloss; #converts all words to lowercase.
		$tempSenseGloss =~  s/(^|\s)$stopList(\s|$)/ /g; #remove stop words
	    }
	    if($userCleanUp ne "\"\"")
	    {
		$tempSenseGloss =~ $userCleanUp;
	    }

	    #if stemming is on, stem each word in each gloss
	    if($stemming == 1)
	    {
		my @tempStem = split(' ', $tempSenseGloss);
		my @stemmedGloss = @{$stemmer->stem(@tempStem)};
		$tempSenseGloss = join(' ', @stemmedGloss);
	    }
		
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
	    
	    if($cleanUp == 1)
	    {
		#Clean up the words in the temporary sense gloss.
		$tempSenseGloss =~ s/(\(|\)|\.)//g;
		$tempSenseGloss =~ s/^a-zA-Z//g;
		$tempSenseGloss = lc $tempSenseGloss; #converts all words to lowercase.
		$tempSenseGloss =~  s/(^|\s)$stopList(\s|$)/ /g; #remove stop words
	    }
	    if($userCleanUp ne "\"\"")
	    {
		$tempSenseGloss =~ $userCleanUp;
	    }

	    #if stemming is on, stem each word in each gloss
	    if($stemming == 1)
	    {
		my @tempStem = split(' ', $tempSenseGloss);
		my @stemmedGloss = @{$stemmer->stem(@tempStem)};
		$tempSenseGloss = join(' ', @stemmedGloss);
	    }
	    
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

=item $obj->processLemma(@inLemma)

Determines where the OOV Lemma should be 
inserted into WordNet, returns the output.

Parameter: the lemma to be inserted in array form
(lemma, part-of-speech, item-id, definition, def source)

Returns: chosen lemma in array form 
(item-id, WordNet sense, operation)

=cut

sub processLemma()
{
    my $base = 0; 
    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }

    my %senseScores = ();
    my $highSenseScore = 0; 
    my $highSense = ""; 
    my @inLemma = @{$_[$base]}; 
    my @outLemma = ("","","");
    my $attachMerge = "";
    my @senses = ();

    if($preProcessed == 1)
    {
	if($inLemma[1] =~ /noun/)
	{
	    @senses = @wnNounSenses;
	}
	else
	{
	    @senses = @wnVerbSenses;
	}
	
	foreach $curSense (@senses) #runs through each sense of current word
	{
	    my $score = scoreSense(\@inLemma, $curSense);
	    
	    if($score >= $highSenseScore)
	    {
		$highSenseScore = $score;
		$highSense = $curSense;	
	    }
	    
	    $senseScores{$curSense} = $score;
	}
	
	if($refineSense == 1)
	{
	    $highSense = refineSense(\@inLemma, $highSense);
	}
	
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
	return \@outLemma;
    }
    else
    {
	my $self = shift;
	$self->{error} = 2;
	$self->{errorString} = "PreProcessing must be run before processLemma() is called.";
    }
}

=item $obj->toggleCompareGlosses($hype,$hypo,$syns)

Toggles which glosses are used in score sense.
by default, the sense, the sense's hypernyms'
glosses,hyponyms' glosses, and synsets' glosses
are turned on. This method allows for toggling
of hypes,hypos,synsets, by passing in three 
parameters, 1 for on and 0 for off. 
Example: toggleCompareGlosses(0,0,0) toggles 
all three off.

Parameters: 0 or 1 for toggling hypernyms, hyponyms,
and synset comparisons.

Returns: nothing

=cut

sub toggleCompareGlosses()
{
    my $base = 0; 
    if(scalar @_ == 4)#checks if method entered by object.
    {
	$base = 1;
    }

    if($_[$base] == 0)
    {
	$useHypeGlosses = 0;
    }
    else 
    {
	$useHypeGlosses = 1;
    }

    $base++;
    
    if($_[$base] == 0)
    {
	$useHypoGlosses = 0;
    }
    else
    {
	$useHypoGlosess = 1;
    }
    
    $base++;

    if($_[$base] == 0)
    {
	$useSynsGlosses = 0;
    }
    else
    {
	$useSynsGlosses = 1;
    }
}

=item $obj->setBonus($bonus)

Allows the user to set the bonus that will be
used when scoring lemmas that contain the 
new lemma.

Parameter: the multiplier that should be used in 
calculating the bonus.

Returns: nothing

=ctu

sub setBonus()
{
    my $base = 0; 
    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }

    $bonus = $_[$base];
}

=item $obj->scoreSense(@inLemma, $compareSense)

Serves as a wrapper method to facilitate the 
main program by directing it to the currently 
chosen scoring method. By default the average
highest scoring method is chosen. This can be 
changed with setScoreMethod().

Parameters: the in lemma in array form
(lemma, part-of-speech, item-id, definition, def source)
and the sense that the lemma is being compared to.

Returns: a score of how related the in lemma is to the 
compareSense.

=cut

sub scoreSense()
{
    my $base = 0; 
    if(scalar @_ == 3)#checks if method entered by object.
    {
	$base = 1;
    }

    my @inLemma = @{$_[$base]};
    $base++;
    my $curSense = $_[$base];

    my $score = 0;
    if($scoringMethod eq "baseline")
    {
	$score = baseline(\@inLemma, $curSense);
    }
    if($scoringMethod eq "BwS")
    {
	$score = BwS(\@inLemma, $curSense);
    }
    if($scoringMethod eq "Similarity")
    {
	$score = Similarity(\@inLemma, $curSense);
    }

    return $score;
}   

=item $obj->setScoreMethod($scoreMethod)

Allows the user to choose which scoring method
should be used by default when running the 
program from the top. Options are:
'baseline'
'BwS' - baseline system with stemming and lemmitization
--as more are added they will appear here.

Parameter: the chosen scoring method

Returns: nothing.

=cut

sub setScoreMethod()
{
    my $base = 0;

    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }

    my $scoreMethod = $_[$base];

    #check if the score method is in scoring methods.
    my @matches = grep(/$scoreMethod/, @scoringMethods);
    if(scalar @matches > 0)
    {
	$scoringMethod = $scoreMethod;
    }
    
}

=item $obj->Similarity(@inLemma, $compareSense)

Calculates a score for the passed sense and returns
that score.

Parameters: the in lemma in array form 
(lemma, part-of-speech, item-id, definition, def source)
and the sense that the lemma is being compared to.

Returns: a score of how related the im lemma is to the 
compareSense.

=cut

sub Similarity()
{
    my $base = 0;
    if(scalar @_ == 3)#checks if method entered by object.
    {
	$base = 1;
    }

    my @inLemma = @{$_[$base]};
    $base++;
    my $curSense = $_[$base];

    my $def = @inLemma[3];

    #split definition and stem the words
    my @listDef =split(' ', $def);
    my @defStemmed = @{$stemmer->stem(@listDef)};

    #join definition back together and tag with pos
    $def = join(' ', @defStemmed);
    my $tagged = $tagger->add_tags($def);

    #split the tagged definition for individual word processing
    @tagArray = split(' ', $tagged);
    my @similar = ();

    #step through each tagged word and find the first sense in wordnet, then add that to the @similar list
    foreach my $cur (@tagArray)
    {
	my $pos = '';
	if($cur =~ /<nn>.*/)
	{
	    $pos = 'n';
	}
	else
	{
	    if($cur =~ /<vbp>.*/)
	    {
		$pos = 'v';
	    }
	    else
	    {
		if($cur =~ /<jj>.*/)
		{
		    $pos = 'a';
		}
	    }
	}

	if(length $pos == 1)
	{
	    $cur =~ s/<[nvj\/].{1,3}>//g;
	    @wnQuery = $wn->querySense("$cur#$pos");
	    push @similar, $wnQuery[0];
	}
    }

    my $score = 0;

    foreach my $curSim (@similar)
    {
	my $value = $measure->getRelatedness("$curSense", "$curSim");
	$score = $score + $value;
    }
    
    return $score;
}

=item $obj->BwS(@inLemma, $compareSense)   

Calculates a score for the passed sense and returns
that score. This is a modified baseline() method 
which adds stemming to the data.

Parameters: the in lemma in array form                                                                                               
(lemma, part-of-speech, item-id, definition, def source)                                                                             
and the sense that the lemma is being compared to.                                                                                   
                                                                                                                                     
Returns: a score of how related the in lemma is to the                                                                               
compareSense.     

=cut

sub BwS()
{
    my $base = 0;
    if(scalar @_ == 3)#checks if method entered by object.
    {
	$base = 1;
    }

    my @inLemma = @{$_[$base]};
    $base++;
    my $curSense = $_[$base];

    if($stemmed == 0)
    {
	$stemming = 1;
	preProcessing();
	$stemmed = 1;
    }

    return simpleScoreSense(\@inLemma, $curSense);

}    

=item $obj->baseline(@inLemma, $compareSense)

Calculates a score for the passed sense then returns 
that score. This class is a wrapper for the 
simpleScoreSense() method as it makes sure no stemming
or lemmatization is present in the preProcessing().

Parameters: the in lemma in array form                                                                                               
(lemma, part-of-speech, item-id, definition, def source)                                                                             
and the sense that the lemma is being compared to.                                                                                   
                                                                                                                                     
Returns: a score of how related the in lemma is to the                                                                               
compareSense.                                                                                                                        
                                                                                                                                     
=cut           

sub baseline()
{
    my $base = 0;
    if(scalar @_ == 3)#checks if method entered by object.
    {
	$base = 1;
    }

    my @inLemma = @{$_[$base]};
    $base++;
    my $curSense = $_[$base];

    if($stemmed == 1)
    {
	$stemming = 0;
	preProcessing();
	$stemmed = 0;
    }

    return simpleScoreSense(\@inLemma, $curSense);
    
}    

=item $obj->word2VecCompare(@inLemma)

Calculates a score for the passed sense by 
using the gensim Word2Vec model trained on Google
news vectors.

Parameters: the in lemma in array form
(lemma, part-of-speech, item-id, definition, def source)
and the sense that the lemma is being compared to.

Returns: a score of how related the in lemma is to the 
compareSense.

=cut

sub word2VecCompare()
{
    my $base = 0; 
    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }

    my @inLemma = @{$_[$base]};
    my @candidateArray = ();

    my $tempLemmaGloss = $inLemma[3];
    
    if($cleanUp == 1)
    {
	#Clean up the words in the temp lemma gloss.
	$tempLemmaGloss =~ s/(\(|\)|\.)//g;
	$tempLemmaGloss =~ s/^a-zA-Z//g;
	$tempLemmaGloss = lc $tempLemmaGloss;
	$tempLemmaGloss =~  s/(^|\s)$stopList(\s|$)/ /g; #remove stop words
    }
    
    
    if($inLemma[1] eq 'noun')
    {
	@candidateArray = @wordNetNouns;
    }
    else
    {
	@candidateArray = @wordNetVerbs;
    }

    open (WNFILE, '>', "tmpfile") or die $!;
    print WNFILE "$cValue\n";
    print WNFILE "$inLemma[0]\n"; #print OOV Lemma first which will be handled by python
    print WNFILE "$tempLemmaGloss\n";
    #create a file of all candidate WordNet words to be passed to python word2vec
    foreach $curW (@candidateArray)
    {
	if($curW !~  /(^|\s)$stopList(\s|$)/g)
	{
	    print WNFILE "$curW\n";
	}
    }
    close WNFILE;
    
    #open(my $ideal, "|-", "python ~/WordNet-Extend/word2vecSimilarity.py tmpfile $inLemma[0]") or die "Cannot run python script: $!";

    $ideal =`python -W ignore ~/bin/word2vecSimilarity.py tmpfile`;

    chomp $ideal;
    my $attachMerge = "";
    if($wnFreq{$ideal} == 0)
    {
	$attachMerge = "attach";
    }
    else
    {
	$attachMerge = "merge";
    }
    
    my $pos = "";
    if($inLemma[1] eq 'noun')
    {
	$pos = 'n';
    }
    else
    {
	$pos = 'v'
    }

    my @outLemma = ();
    if($ideal ne "")
    {
	@outLemma = ("$inLemma[2]", "$ideal#$pos#1", "$attachMerge");
    }
#    else
#    {
#	my $self = shift;
#	$self->{error} = 1;
#	$self->{errorString} = "No ideal found, consider changing confidence value";
#    }
    #unlink 'tmpfile';
    
    return \@outLemma;
    
}    

=item $obj->setConfidenceValue()

Allows the user to set the confidence value for word2vecCompare().
The confidence value is the cutoff for the similarity score. If 
the similarity score is below the confidence value it will be dropped.
This aims to increase accuracy but will reduce recall.

Parameters: the new confidence value, default is set to 0

Returns: Nothing

=cut

sub setConfidenceValue()
{
    my $base = 0;

    if(scalar @_ == 2)#checks if method entered by object
    {
	$base = 1;
    }
    
    my $newCValue = $_[$base];

    $cValue = $newCValue;
    
}    


=item $obj->simpleScoreSense(@inLemma, $compareSense)

Calculates a score for the passed sense then
returns that score. This is the baseline system which 
was submitted for SemEval16 task 14. This algorithm
scores by overlapping words found in the lemma's gloss
and also with the lemma's hypernym and hyponyms' glosses.

Parameters: the in lemma in array form
(lemma, part-of-speech, item-id, definition, def source)
and the sense that the lemma is being compared to.

Returns: a score of how related the in lemma is to the 
compareSense.

=cut
    
sub simpleScoreSense()
{
    my $base = 0; 
    if(scalar @_ == 3)#checks if method entered by object.
    {
	$base = 1;
    }

    my @inLemma = @{$_[$base]};
    $base++;
    my $curSense = $_[$base];
    my $word = substr($curSense, 0, index($curSense, '#')); #extracts base word.

    #_________________Sense Gloss_________________________________
    my @curSenseGloss = split (' ', $wnGlosses{$curSense}); #initialize current sense gloss. 
    
    my @extendedGloss = getExtendedGloss($curSense);

    #________________Lemma Gloss_________________________________
    my $tempLemmaGloss = $inLemma[3];

    
    if($cleanUp == 1)
    {
	#Clean up the words in the temp lemma gloss.
	$tempLemmaGloss =~ s/(\(|\)|\.)//g;
	$tempLemmaGloss =~ s/^a-zA-Z//g;
	$tempLemmaGloss = lc $tempLemmaGloss;
	$tempLemmaGloss =~  s/(^|\s)$stopList(\s|$)/ /g; #remove stop words
    }
    if($userCleanUp ne "\"\"")
    {
	$tempLemmaGloss =~ $userCleanUp;
    }
    
    my @curLemmaGloss = split(' ', $tempLemmaGloss);


    #__________________Overlaps__________________________________
    my $glossLength = 0;
    my $overlaps = 0.0; #number of overlapped words.

    #scan through each word from the sense gloss and see if any overlap on the lemma gloss.
    for my $lWord (0..$#curLemmaGloss)
    {
	$glossLength = $glossLength + length $curLemmaGloss[$lWord];
	if($curLemmaGloss[$lWord] =~ /\b$word\b/) #if lemma contains current word from sense itself
	{
	    $overlaps = $overlaps + $bonus*(length $word);
	}
	
	$spaceWord = $word;
	$spaceWord =~ s/_/ /g; #substitute underscores for spaces for comparison below
	if($spaceWord =~ /(^\w+\s\b$curLemmaGloss[$lWord]\b$)|(^\b$curLemmaGloss[$lWord]\b\s\w+$)/)
	{
	    $overlaps = $overlaps + $bonus*(length $curLemmaGloss[$lWord]);
	}

	for my $sWord (0..$#curSenseGloss)
	{
	    if($curLemmaGloss[$lWord] =~ /\b\Q$curSenseGloss[$sWord]\E\b?/)
	    {
		$overlaps = $overlaps + length $curSenseGloss[$sWord];
	    }
	}
	for my $extWord (0..$#extendedGloss)
	{
	    if($curLemmaGloss[$lWord] =~ /\b\Q$extendedGloss[$extWord]\E\b?/)
	    {
		$overlaps = $overlaps + length $extendedGloss[$extWord];
	    }
	}
	
    }
   
    $score = $overlaps/$glossLength;
    
    return $score;
}

=item $obj->getExtendedGloss($compareSense)

Calculates the extended gloss based on which
glosses are toggled and returns an array 

which contains the full glosses.

Parameter: the sense which the extended gloss is 
based on

Returns: an array which contains the extended gloss

=cut

sub getExtendedGloss()
{
    my $base = 0; 
    if(scalar @_ == 2)#checks if method entered by object.
    {
	$base = 1;
    }

    my $curSense = $_[$base];
    my @extendedGloss = ();

    #__________________Hype Gloss_________________________________
    if($useHypeGlosses == 1)
    {
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
	
	push(@extendedGloss, @senseHypeGloss);
    }
        
    #________________Hypo Gloss__________________________________
    if($useHypoGlosses == 1)
    {
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
	push(@extendedGloss, @senseHypoGloss);
    }

    #_________________Syns Gloss_________________________________
    if($useSynsGlosses == 1)
    {
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
	push(@extendedGloss, @senseSynsGloss);
    }

    return \@extendedGloss;    
}

=item $obj->toggleRefineSense($toggle)
    
Allows user to toggle refineSense() on/off.
    
Parameter: 0 or 1 to toggle the refine sense method 
on or off respectively in the processLemma method.

Returns: nothing

=cut

sub toggleRefineSense()
{
    if($_[0] == 0)
    {
	$refineSense = 0;
    }
    else
    {
	$refineSense = 1;
    }
}

=item $obj->refineSense(@inLemma, $highSense)
    
Refines chosen sense, by determing which
numbered sense should be chosen.

Parameters: the in lemma in form of
(lemma, part-of-speech, item-id, definition, def source)
and the sense which currently bests matches the inlemma.

Returns:the new highest scoring sense

=cut

sub refineSense()
{
    my $base = 0; 
    if(scalar @_ == 3)#checks if method entered by object.
    {
	$base = 1;
    }

    my @inLemma = @{$_[$base]};
    
    $base++;
    my $highSense = $_[$base];
    my $word = substr($highSense, 0, index($highSense, '#')); #extracts base word.
    my $shortSense = substr($inLemma[1], 0, 1);
    my $sense = $word . "#" . $shortSense;
    my $highSenseScore = 0;
    my $rSenseScore = 0;
    my $refineHigh = "$sense#1"; #assume first sense.
    my $tempLemmaGloss = $inLemma[3];
    
    if($cleanUp == 1)
    {
	#Clean up the words in the temp lemma gloss.
	$tempLemmaGloss =~ s/(\(|\)|\.)//g;
	$tempLemmaGloss =~ s/^a-zA-Z//g;
	$tempLemmaGloss = lc $tempLemmaGloss;
	$tempLemmaGloss =~  s/(^|\s)$stopList(\s|$)/ /g; #remove stop words
    }
    if($userCleanUp ne "\"\"")
    {
	$tempLemmaGloss =~ $userCleanUp;
    }

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

    return $highSense;
    
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

1;
