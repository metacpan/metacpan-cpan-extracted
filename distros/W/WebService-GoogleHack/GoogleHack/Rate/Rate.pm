#!/usr/local/bin/perl 

=head1 NAME

WebService::GoogleHack::Rate - This module implements a simple relatedness measure and semantic orientation related type functions.

=head1 SYNOPSIS

    
    use WebService::GoogleHack::Rate;

    #GIVE PATH TO INPUT FILE HERE

    my $INPUTFILE="";

    #GIVE PATH TO TRACE FILE HERE

    my $TRACEFILE="";

    #create an object of type Rate

    my $rate = WebService::GoogleHack::Rate->new(); 

    $results=$rate->measureSemanticRelatedness1("dog", "cat");

    #The PMI measure is stored in the variable $results, and it can also 
    #be accessed as $rate->{'PMI'};

    $results=$rate->predictSemanticOrientation($INPUTFILE, "excellent", "bad",$TRACEFILE);

    #The resutls can be accessed through 
    print $results->{'prediction'}."\n"; 
    $results->{'PMI Measure'}."\n"; 
    $rate->{'prediction'} &."\n"; 
    $rate->{'PMI Measure'}."\n"; 


=head1 DESCRIPTION

WebService::GoogleHack::Rate - This package uses Google to do some basic 
natural language processing. For example, given two words, say "knife" and 
"cut", the module has the ability to retrieve a semantic relatedness measure,
 commonly known as the PMI (Pointwise mututal information) measure. The 
larger the measure the more related the words are.
The package can also predict the semantic orientation of a given paragraph of 
english text. A positive measure means that the paragraph has a positive 
meaning, and negative measure means the opposite.

=head1 PACKAGE METHODS

=head2 __METHOD__->new()

Purpose: This function creates an object of type Rate and returns a blessed reference.

=head2 __METHOD__->init(Params Given Below)

Purpose: This this function can used to inititalize the member variables.

Valid arguments are :

=over 4

=item *

B<key>

I<string>. key to the google-api

=item *

B< File_location>

I<string>.  This the wsdl file name


=back

=head2 __METHOD__->measureSemanticRelatedness1(searchString1,searchString2)

Purpose: This function is used to measure the relatedness between two words.

Formula used: log(hits(w1)) + log(hits(w2)) - log(hits(w1w2))

Valid arguments are :

=over 4

=item *

B<searchString1>

I<string>. The search string which can be a phrase or word

=item *

B<searchString2>

I<string>.   The search string which can be a phrase or word

=back

Returns: Returns the object containing the relatedness measure.

=head2 __METHOD__->measureSemanticRelatedness2(searchString1,searchString2)

Purpose: This function is used to measure the relatedness between two words.

Formula used:  log(w1w2/(w1+w2))

Valid arguments are :

=over 4

=item *

B<searchString1>

I<string>. The search string which can be a phrase or word

=item *

B<searchString2>

I<string>.   The search string which can be a phrase or word

=back

Returns: Returns the object containing the relatedness measure.

=head2 __METHOD__->measureSemanticRelatedness3(searchString1,searchString2)

Purpose: This function is used to measure the relatedness between two words.

Formula used:  log( hits(w1w2) / (hits(w1) * hits(w2)))

Valid arguments are :

=over 4

=item *

B<searchString1>

I<string>. The search string which can be a phrase or word

=item *

B<searchString2>

I<string>.   The search string which can be a phrase or word

=back

Returns: Returns the object containing the relatedness measure. 

=head2 __METHOD__->predictSemanticOrientation(infile,posInf, negInf,trace)

Purpose: this function tries to predict the semantic orientation of a paragraph of text.


Valid arguments are :

=over 4

=item *

B<infile> 

I<string>. The location of the review file

=item *

B<posInf>. 

I<string>.   Positive inference such as excellent 

=item *

B<negInf>.

I<string>.    Negative inference such a poor


=item *

B<trace>.

I<string>.   The location of the trace file. If a file_name is given, the results are stored in this file

=back

Returns : the PMI measure and the prediction which is 0 or 1.

=head3 __METHOD__->predictWordSentiment(infile,posInf,negInf,html,trace)

Purpose:Given an file containing text, this function tries to find the positive and negative words.
The formula used to calculate the sentiment of a word is based on 
          the PMI-IR formula given in Peter Turneys paper.

              (hits(word AND "excellent") hits (poor))

         log2 ----------------------------------------

              (hits(word AND "poor") hits (excellent))


For more information refer the paper, "Thumbs Up or Thumbs Down? Semantic Orientation Applied to Unsupervised Classification of Reviews" By Peter Turney.


=over 4

=item *

B<infile> 

I<string>. The input file

=item *

B<posInf> 

I<string>. A positive word such as "Excellent"

=item *

B<negInf>.

I<string>. A negative word such as "Bad"

=item *

B<html>.

I<string>. Set to "true" if you want the results to be HTML formatted

B<trace>.

I<string>. Set to a file if you want the results to be written to the given filename.

=back

returns : Returns an html or text version of the results.

=head3 __METHOD__->predictPhraseSentiment(infile,,posInf,negInf,html,trace)

Purpose:Given an file containing text, this function tries to find the positive and negative phrases. 
The formula used to calculate the sentiment of a phrase is based on the PMI-IR formula given in Peter Turneys paper.

              (hits(phrase AND "excellent") hits (poor))

         log2 ------------------------------------------
     
              (hits(phrase AND "poor") hits (excellent))

For more information refer the paper, "Thumbs Up or Thumbs Down? Semantic Orientation Applied to Unsupervised Classification 
of Reviews" By Peter Turney.

=over 4

=item *

B<infile> 

I<string>. The input file

=item *

B<posInf> 

I<string>. A positive word such as "Excellent"

=item *

B<negInf>.

I<string>. A negative word such as "Bad"

=item *

B<html>.

I<string>. Set to "true" if you want the results to be HTML formatted

B<trace>.

I<string>. Set to a file if you want the results to be written to the given filename.

=back

returns : Returns an html or text version of the results.

=head1 AUTHOR

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt>

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt>

=head1 BUGS

=head1 SEE ALSO

WebService::GoogleHack home page - http://google-hack.sourceforge.net

Pratheepan Raveendranathan - http://www.d.umn.edu/~rave0029/research

Ted Pedersen - www.d.umn.edu./~tpederse

Google-Hack Maling List E<lt>google-hack-users@lists.sourceforge.netE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 by Pratheepan Raveendranathan, Ted Pedersen

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut


package WebService::GoogleHack::Rate;

our $VERSION = '0.15';

use strict;

use SOAP::Lite;

sub new
{
my $this = {};

$this-> {'Key'} = undef;
$this-> {'File_Location'} = undef;
$this->{'releated'}=undef;
$this->{'PMIMeasure'}=undef;
$this->{'prediction'}=undef;


bless $this;
 
return $this;
} 

sub init
 {
    my $this = shift;    
    $this->{'Key'} = shift;
    $this->{'File_Location'} = shift;
    
}

sub measureSemanticRelatedness3
{
#log( hits(w1w2) / (hits(w1) * hits(w2)))
    my $searchInfo = shift;
    my $searchString=shift;
 #   my $searchString2=shift; 
    my $context=shift;
    my $temp_string1="\"".$searchString." AND ".$context."\"";    
  #  $temp_string2=$searchString2." AND ".$context; 
    my $pmi=0;
  
    require WebService::GoogleHack::Search;
    
    my $results1=WebService::GoogleHack::Search::searchPhrase($searchInfo, $searchString);
    my $result_counte=$results1->{NumResults}; 
    
    my $results3=WebService::GoogleHack::Search::searchPhrase($searchInfo, $temp_string1);
    
    my $result_count1=$results3->{NumResults};
    
    my $results5=WebService::GoogleHack::Search::searchPhrase($searchInfo, $context);
    
    my $result_counti=$results5->{NumResults};
    
    my $denom=$result_counte * $result_counti;

    if($denom==0 || $result_count1==0)
    {
	$pmi=0.0;
    }
    else
    {
    $pmi=sprintf("%.4f",$pmi);
    $pmi=log(($result_count1) / $denom)/log(2);
    }   

    return $pmi;

} 
 
sub measureSemanticRelatedness2
{

#   log(w1w2/(w1+w2))
#
#
#
    my $searchInfo = shift;
    my $searchString=shift;
 #   my $searchString2=shift; 
    my $context=shift;
    my $temp_string1="\"".$searchString." AND ".$context."\"";    
  #  $temp_string2=$searchString2." AND ".$context; 
    my $pmi=0;
  
    require WebService::GoogleHack::Search;
    
    my $results1=WebService::GoogleHack::Search::searchPhrase($searchInfo, $searchString);
    my $result_counte=$results1->{NumResults}; 
    
    my $results3=WebService::GoogleHack::Search::searchPhrase($searchInfo, $temp_string1);
    
    my $result_count1=$results3->{NumResults};
    
    my $results5=WebService::GoogleHack::Search::searchPhrase($searchInfo, $context);
    
    my $result_counti=$results5->{NumResults};
    
    my $denom=$result_counte + $result_counti;

    if($denom==0 || $result_count1==0)
    {
	$pmi=0.0;
    }
    else
    {
    $pmi=sprintf("%.4f",$pmi);
    $pmi=log(($result_count1) / $denom)/log(2);
    }   

    return $pmi;

} 

sub measureSemanticRelatedness1
{
# log(hits(w1)) + log(hits(w2)) - log(2 * hits(w1w2))
    my $searchInfo = shift;
    my $searchString=shift;
 #   my $searchString2=shift; 
    my $context=shift;
    my $temp_string1="\"".$searchString." AND ".$context."\"";    
  #  $temp_string2=$searchString2." AND ".$context; 
    my $score=0;
    my $w1=0;
    my $w2=0;
    my $w1w2=0;
    
    require WebService::GoogleHack::Search;
    
    my $results1=WebService::GoogleHack::Search::searchPhrase($searchInfo, $searchString);

    if($results1->{NumResults}!=0)
    {
	$w1=log($results1->{NumResults})/log(2);
    }

    my $results2=WebService::GoogleHack::Search::searchPhrase($searchInfo, $temp_string1);

    if($results2->{NumResults}!=0)
    {
	$w1w2=log($results1->{NumResults})/log(2);
    }

    my $results3=WebService::GoogleHack::Search::searchPhrase($searchInfo, $context);
    
    if($results3->{NumResults}!=0)
    {
	$w2=log($results1->{NumResults})/log(2);
    }

   $score=$w1 + $w2 - (2 * $w1w2); 
   $score=sprintf("%.4f",$score);

    return $score;

} 


sub predictSemanticOrientation
{   
    my $this=shift;
    my $infile=shift;
    my $positive_inference=shift;
    my $negative_inference=shift;
    my $trace_file=shift;

    open(INFILE, "<$infile") || print "*** Error : Opening  $infile to read - Boundary\n";

    my @contents=<INFILE>;
    my $phrase_size=3;
    my @phrases=();

    print "\n Running Predict Semantic Orientation $positive_inference";
    
    foreach my $line (@contents)
    {
	my @temp=split(/\s/,$line);

	for my $i (0..$#temp)
	{
	    my $str="";
	    my $t=$i + $phrase_size;
	    for(my $j=$i; $j < $t; $j++)
	    {
		if($j < ($#temp+1))
		{
		    $str.=" $temp[$j]";
		}
		
	    }
#	print "\n $str";
	    push(@phrases, $str);
	}
    }
    
    
    my %sentences=();
    

    foreach my $ph (@phrases)
    {


	# my @temp=split(/ /,$ph);
	
#my $ph=" FORMER/RB SUPERHERO/JJ IN/IN ";
	
    if($ph=~m/(((\w*)(\/JJ ))((\w*)(\/NN)))/)
    {
#	print "Found $ph :\n$3 $6\n";
        $sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/JJ ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/NN ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/NNS ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/VB )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/VBD )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/VBN )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/VBG )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/VB )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/VBD )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/VBN )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/VBG )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/VB )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/VBD )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/VBN )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/VBG )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }

   
#    print $ph."\n";

}

    
    require WebService::GoogleHack::Search;

    my $results1=WebService::GoogleHack::Search::searchPhrase($this, $positive_inference);
    my $positiveInference=$results1->{NumResults}; 

    my $results2=WebService::GoogleHack::Search::searchPhrase($this, $negative_inference);
    my $negativeInference=$results2->{NumResults}; 
    my $total_so=0;
    my $so=0;
    my $score=0;
    my $html="";
    my $text="";
    
  #  print "\n\n";
    
    $html.= "<BR>";

    foreach my $key ( keys %sentences)
    {

	#print "\n\n\n Phrase is $key";
	$html.= "<BR>Extracted Phrase is \"$key\"";

	my $query1="\"$key\" AND $positive_inference";
	my $query2="\"$key\" AND $negative_inference";

	my $rs1=WebService::GoogleHack::Search::searchPhrase($this,$query1);
       
	my $good_query=$rs1->{NumResults};

	#print "\n Good Count is $good_query";

	#print "\n Query 2 is $query2";

	my $rs2=WebService::GoogleHack::Search::searchPhrase($this,$query2);

	my $bad_query=$rs2->{NumResults};

	#print "\n Bad Count is $bad_query";
	
	$score=($good_query * $negativeInference) / (($bad_query * $positiveInference)+1);

	if($score == 0)
	{
	 $total_so+=0; 

	# print "\n So is 0"; 
	 $html.=" : 0"; 
	}
	else  
	{ 
	    $so=(log ($score))/(log(2));	
 	    $total_so+=$so; 
#	    print "\n So is $so";
	    $html.=" : ".sprintf("%.4f",$so)." ";
	}



    }

#    print "\n Semantic Orientation is $total_so";
 
    my $final="";
    if($total_so >= 0)
    {
     $final="<br> Positive Orientation <BR> Semantic Orientation Score is $total_so"."<br><br> <b>Trace </b>$html";	
    }
    else
    {
      $final="<br> Negative Orientation <BR> Semantic Orientation Score is $total_so"."<br><br> <b>Trace </b> <br><br>$html";	
    }

return $final;

}



sub predictWordSentiment
{   
    my $this=shift;
    my $infile=shift;
    my $positiveWord=shift;
    my $negativeWord=shift;
    my $htmlFlag=shift;
    my $traceFile=shift;

    my %stop_list=();
    my $stoplist_location=$this->{'basedir'}."Datafiles/stoplist.txt";
    my $query1;
    my $query2;
    my $rs1;
    my $rs2;
    my $good_query;
    my $bad_query;
    my $score=0;
    my $so=0;
    my $html="";
    my $text="";
    my $positiveHtml;
    my $positiveText;
    my $negativeHtml;
    my $negativeText;
    my %resultset=();

    require WebService::GoogleHack::Text;

    %stop_list=WebService::GoogleHack::Text::getWords("$stoplist_location");


    undef $/;
    open(INFILE, "<$infile") || print "*** Error : Opening  $infile to read - Boundary\n";
    
    $_=<INFILE>;
 
    my @words=();

    # remove any other character besides alpha, space, and (.|!|?)
    ~tr/a-zA-z\'/ /cs;
    # remove other characters that were no removed such as ^, [, ]
    tr/[|]|^|_|-|&|\#|\@|~|,|!|/ /s;

    my @temp=split(/\s+|\n/,$_);

   
    my $Key;
    my $Value;

    while( ($Key,$Value) = each(%stop_list) ){
	$stop_list{"$Key"}=1;	
}

#    print "\n printing here".$stop_list{"a "};

    foreach my $word (@temp)
    {
	$word=lc($word);	
	chomp($word);
	if(!exists $stop_list{"$word"})
	{
#	    print "\n Word is $word";
	    push(@words,$word);   
	}	
    } 

    require WebService::GoogleHack::Search;

    my $results1=WebService::GoogleHack::Search::searchPhrase($this, "\"$positiveWord\"");
    
    my $positiveInference=$results1->{NumResults}; 

    my $results2=WebService::GoogleHack::Search::searchPhrase($this,  "\"$negativeWord\"");
    
    my $negativeInference=$results2->{NumResults}; 
    
    print "\n";

    foreach my $word (@words)
    {
	$query1="\"$word\" AND $positiveWord";
	$query2="\"$word\" AND $negativeWord";
	
	print ".";

	$rs1=WebService::GoogleHack::Search::searchPhrase($this,$query1);
	$good_query=$rs1->{NumResults};
	$rs2=WebService::GoogleHack::Search::searchPhrase($this,$query2);
	$bad_query=$rs2->{NumResults};

	$score=($good_query * $negativeInference) / (($bad_query * $positiveInference)+1);

	print "\n Score is $score";
	
	if($score == 0)
	{	
	    $resultset{"$word"}=0;
	}
	else  
	{ 
	    $so=(log ($score))/(log(2));	
	    $resultset{"$word"}=$so;	  
	}
	
    }

    foreach my $key (sort  { $resultset{$b} <=> $resultset{$a} } (keys(%resultset))) {
 
	if($resultset{"$key"}>=0)
	{
  	   $positiveHtml.="<TR><TD>$key: $resultset{$key}</TD></TR>";
	   $positiveText.="\n$key: $resultset{$key}";
	}
	else
	{
	    $negativeHtml.="<TR><TD>$key: $resultset{$key}</TD></TR>";
	    $negativeText.="\n$key: $resultset{$key}";
	}

    }
	   
    $text.="\n Results \n\n POSITIVE WORDS \n $positiveText \n NEGATIVE WORDS \n $negativeText";

    $html.="<TABLE><TR><TD> <B> Result </B> </TD></TR><TR><TD></TD></TR>";
    $html.="<TR><TD> <B> Positive Words </B> </TD></TR>";
    $html.="$positiveHtml<TR><TD></TD></TR>";
    $html.="<TR><TD> <B> Negative Words </B> </TD></TR>$negativeHtml<br></TABLE>";

 if($traceFile ne "")
    {
	open(DAT,">$traceFile") || die("Cannot Open $traceFile to write");
	print DAT $text;	
	close(DAT);      
    }

  if($htmlFlag eq "true")
    {
	return $html;
    }
    else
    {
	return $text;
    }

}


sub predictPhraseSentiment
{   
    my $this=shift;
    my $infile=shift;
    my $positive_inference=shift;
    my $negative_inference=shift;
    my $htmlFlag=shift;
    my $traceFile=shift;

    open(INFILE, "<$infile") || print "*** Error : Opening  $infile to read - Boundary\n";

    my @contents=<INFILE>;
    my $phrase_size=3;
    my @phrases=();
    my $positiveHtml;
    my $positiveText;
    my $negativeHtml;
    my $negativeText;

    print "\n Running Phrase Sentiment";
    
    foreach my $line (@contents)
    {
	my @temp=split(/\s/,$line);

	for my $i (0..$#temp)
	{
	    my $str="";
	    my $t=$i + $phrase_size;
	    for(my $j=$i; $j < $t; $j++)
	    {
		if($j < ($#temp+1))
		{
		    $str.=" $temp[$j]";
		}
		
	    }
#	print "\n $str";
	    push(@phrases, $str);
	}
    }
    
    
    my %sentences=();
    

    foreach my $ph (@phrases)
    {


	# my @temp=split(/ /,$ph);
	
#my $ph=" FORMER/RB SUPERHERO/JJ IN/IN ";
	
    if($ph=~m/(((\w*)(\/JJ ))((\w*)(\/NN)))/)
    {
#	print "Found $ph :\n$3 $6\n";
        $sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/JJ ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/NN ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/NNS ))((\w*)(\/JJ )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/VB )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/VBD )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/VBN )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RB ))((\w*)(\/VBG )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/VB )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/VBD )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/VBN )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBR ))((\w*)(\/VBG )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/VB )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/VBD )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/VBN )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }
    if($ph=~m/(((\w*)(\/RBS ))((\w*)(\/VBG )))/)
    {
	#print "Found $ph :\n$3 $6\n";
	$sentences{"$3 $6"}++;
    }

   
#    print $ph."\n";

}

    
    require WebService::GoogleHack::Search;

    my $results1=WebService::GoogleHack::Search::searchPhrase($this,$positive_inference);
    my $positiveInference=$results1->{NumResults}; 

    my $results2=WebService::GoogleHack::Search::searchPhrase($this, $negative_inference);
    my $negativeInference=$results2->{NumResults}; 

    my $so=0;
    my $score=0;
    my $html="";
    my $text="";
    
  #  print "\n\n";
    
    $html.= "<BR>";

    foreach my $key ( keys %sentences)
    {

	print "\n\n\n Phrase is $key";
	$html.= "<BR>\"$key\"";
	$text.= "\n\"$key\"";

	my $query1="\"$key\" AND $positive_inference";
	my $query2="\"$key\" AND $negative_inference";

	my $rs1=WebService::GoogleHack::Search::searchPhrase($this,$query1);
       	my $good_query=$rs1->{NumResults};

	my $rs2=WebService::GoogleHack::Search::searchPhrase($this,$query2);
	my $bad_query=$rs2->{NumResults};

	print "\n Bad Count is $bad_query";
	
	$score=($good_query * $negativeInference) / (($bad_query * $positiveInference)+1);

	if($score == 0)
	{
	    $positiveHtml.="$key : 0"; 
	}
	else  
	{ 
	    $so=(log ($score))/(log(2));	
	    $so=sprintf("%.4f",$so)." ";

	    if($so>=0)
	    {
		$positiveHtml.="<TR><TD>$key: $so</TD></TR>";
		$positiveText.="\n$key: $so";
	    }
	    else
	    {
		$negativeHtml.="<TR><TD>$key</TD></TR>";
		$negativeText.="\n$key: $so";
	    } 	   
	}



    }


    $text.="\n Results \n\n Positive Words \n\n $positiveText \n\n\n Negative Words \n\n $negativeText";

    $html.="<TABLE><TR><TD> <B> Result </B> </TD></TR><TR><TD></TD></TR>";
    $html.="<TR><TD> <B> Positive Words </B> </TD></TR>";
    $html.="$positiveHtml<TR><TD></TD></TR>";
    $html.="<TR><TD> <B> Negative Words </B> </TD></TR>$negativeHtml<br></TABLE>";

 if($traceFile ne "")
    {
	open(DAT,">$traceFile") || die("Cannot Open $traceFile to write");
	print DAT $text;	
	close(DAT);      
    }

  if($htmlFlag eq "true")
    {
	return $html;
    }
    else
    {
	return $text;
    }

}

 # remember to end the module with this
1 ;
 











