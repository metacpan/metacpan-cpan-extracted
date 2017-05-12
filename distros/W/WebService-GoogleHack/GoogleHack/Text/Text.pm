#!/usr/local/bin/perl 
=head1 NAME 

WebService::GoogleHack::Text - This module implements some basic text processing such as parsing data etc.

=head1 SYNOPSIS

    use WebService::GoogleHack::Text;

    #create an object of type Text

    my $text = GoogleHack::Text->new(); 

    # returns an hash words

    %results=$text->getWords("file location");

    # returns an hash of 3 word sentences

    %results=$text->getSentences("file location", 3); 

    # this function reads the configuration file

    %results=$text->readConfig("location of configuration file");

    #removes HTML tags

    %results=$text->removeHTML("string");


=head1 DESCRIPTION

This is a simple Text processing package which aids GoogleHack and Rate 
modules. Given a file of words, it retreives the words in the file and stores 
it in a simple hash format. In addition, given a file of text, it can also 
form n word sentences.


=head1 PACKAGE METHODS

=head2 __METHOD__->new()

Purpose: This function creates an object of type Text and returns a blessed reference.

=head2 __METHOD__->init(Params Given Below)

Purpose: This this function can used to inititalize the member variables.

Valid arguments are :

=over 4

=item *

B<key>

I<string>. key to the google-api

=item *

B<wsdl_location>

I<string>.  This the wsdl file name

=item *

B<basedir>

I<string>. The base directory of Google Hack.


=item *

B<taggerdir>

I<string>. The location of the Brill Tagger

=back

=head2 __METHOD__->getSentences(file_name,sentence_length,trace_file)

Purpose:  Given a file of text or a variable containing text, this function tries to retrieve sentences from it.

Valid arguments are :

=over 4

=item *

B<file_name>

I<string>. Name of file to retrieve sentences from.

=item *

B<sentence_length>

I<Number>. Number of words in a sentence. 

=item *

B<trace_file>.

I<string>.   The location of the trace file. If a file_name is given, the results are stored in this file

=back

Returns: Returns an array of strings.



=head2 __METHOD__->getSentences(file_name,trace_file)

Purpose:Given a file of text this function tries to retrieve words from it.

Valid arguments are :

=over 4

=item *

B<file_name>

I<string>. Name of file to retrieve sentences from.

=item *

B<trace_file>.

I<string>.   The location of the trace file. If a file_name is given, the results are stored in this file

=back

Returns:  Returns a hash of words.


=head2 __METHOD__->getSentences(text)

Purpose: Remove XML tags. Package XML::TokeParser must be installed 

Valid arguments are :

=over 4

=item *

B<text>

I<string>. The text to be de-tagged.

=back

Returns:  Returns a XML less text.



=head2 __METHOD__->getSentences(text)

Purpose: Remove HTML tags. Package HTML::TokeParser must be installed 

Valid arguments are :

=over 4

=item *

B<text>

I<string>. The text to be de-tagged.

=back

Returns:  Returns a HTML less text.


=head2 __METHOD__->getSurroundingWords(filename,stemmer)

Purpose:  this function is used to read a configuration file containing informaiton such as the Google-API key, the words list etc.


Valid arguments are :

=over 4

=item *

B<filename> 

I<string>.  Location of the configuration file.

=item *

B<stemmer>.

I<bool>. Porter Stemmer on or off.

=back

returns : Returns an object which contains the parsed information.


=head2 __METHOD__->readConfig(filename)

Purpose:  this function is used to read a configuration file containing informaiton such as the Google-API key, the words list etc.


Valid arguments are :

=over 4

=item *

B<filename> 

I<string>.  Location of the configuration file.

=back

returns : Returns an object which contains the parsed information.

=head1 AUTHOR

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt>

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt>

=head1 BUGS

=head1 SEE ALSO

GoogleHack home page - http://google-hack.sourceforge.net

Pratheepan Raveendranathan - http://www.d.umn.edu/~rave0029/research

Ted Pedersen - www.d.umn.edu./~tpederse

Google-Hack Maling List E<lt>google-hack-users@lists.sourceforge.netE<gt>

=head1 AUTHOR

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt>

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt>

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


package WebService::GoogleHack::Text;


our $VERSION = '0.15';

sub new
{
my $this = {};
$this-> {'Key'} = undef;
$this-> {'File_Location'} = undef;
$this-> {'basedir'} = undef;
$this-> {'taggerdir'} = undef;

 bless $this;
 
return $this;
} 
 

  
# Purpose: This this function can used to inititalize the memebrs
# Pre Condition: Need to pass following vars
# Post : An object of type Google-Hack is created
# @params  Key -  key to the google-api
# @params  File_location - is the wsdl file name


sub init
{
    my $this = shift;
    $this-> {'Key'} = shift;
    $this-> {'File_Location'} = shift;
}


# Purpose: Given a file of text or a variable containing text, this function 
# tries to retrieve sentences from it.
# Pre Condition: Need to pass the file name and the length of the sentence 
# should also be give - meaning the number of words in the sentence
# Post : Returns an array of sentences
# @params  file_name -  the name of the file where text can be accessed or
# the content of the text.search string which can be a phrase or word
# @params m - number of words in a sentence
# @params flag - flag to let the function know if the file_name is the path to
# the file or the actual content of the file.
# returns : an array of sentences.


sub getSentences
{

$file_name=shift;
$m=shift; #Sentence length
$flag=shift;

if($flag eq "false")
{
open(FILE, $file_name) || die "Unable to open file $filename";

@search_strings=();

$i=0;

$temp_string="";

$para="";

print "\n Reading File  $file_name";
while(<FILE>)
{
    chop($_);
     $para=$para." ".$_; 
    $i++;

}

close (FILE);

}
else
{
$para=$file_name;
}

#words_m contains all the setences

@words_m = split(/\;|\:|\,|\.|\?|\!|\"/, $para);

$size_w=@words_m;

$count=0;
$i=0;
$j=0;


#the main loop
#could have used foreach
$test=0;

while ($count < $size_w)
{     
    #dont want any empty string

    if( ((length ($words_m[$count]) !=1) && (length ($words_m[$count]) !=0)))
    {   
	
    #wcount identifies the no of words in a sequence	
	
	$wcount=$m-1;
	
	@words=();
	chomp ($words_m[$count]); #get rid of the newline
        #print "\n\n $words_m[$count]\n";

        #splitting into words, had some problem here

	@words = split(/ +| |\[|\]|\*+|  \n| \n/, $words_m[$count]);
	
	#uncomment to see if the words from proper setences when combined

	$j=0;


	while($wcount < (@words))
	{
	    $k=$m-1;
	    
	    
	    if((@words) >= $m)
	    {
		#making sure the temp_string is empty before using it

		$temp_string="";
               #once again making sure that the length is not zero		
		if( length($words[$wcount-$k])!=0)
		{
		    while($k >=0)
		    {
			$temp=length($words[$wcount-$k]);
			
			if($temp !=0)
			{
			    $temp_string=$temp_string." ".$words[$wcount-$k];
			    
			} #temp !=0
			$k--;
		    } # while k >=0

#if the sequence already exists in the array, we increment the occurances

   $sequence_occs{"$temp_string"}++ if exists $sequence_occs{"$temp_string"};

#else if the sequence does not in the array, then insert it into the array
 
   $sequence_occs{"$temp_string"}=1 if !exists $sequence_occs{"$temp_string"};
		    
		    
		} #if length of words !=0
		
	    } #if words >= $m
	    
	    
	    $wcount++;
	    
	}  # while wcount
	
    } #if length
    
    $count++;
    
    
} # while count



$semantic_strings=();

$count=0;


while( ($Key, $Value) = each(%sequence_occs) ){
 #  print "Key: $Key, Value: $Value \n";

   $semantic_strings[$count]="$Key ";
  # print $semantic_strings[$count];
   $count++;
}

return @semantic_strings;

}


sub getWords
{
   my $file_name=shift;

   
   open(FILE, $file_name) || print "Unable to open file $file_name";
   
   my %words_list=();

   $temp_string="";
   
   $num_words=0;
   
   print "here also";
   
   while(<FILE>)
   {
       chop($_);
       $temp_string=$_;
       $words_list{"$temp_string"}=$num_words if !exists $words_list{"$temp_string"};;
       $num_words++;
       
   }
   
   $size=@words_list;
   #print "\n $file_name and number of words $num_words \n";
   
   return %words_list;
   
}


sub removeHTML
{

my $text=shift;

require HTML::TokeParser;

$parser = new HTML::TokeParser (\$text);

$content="";

while (my $token = $parser->get_token) {

  next unless $token->[0] eq 'T';
  $content .= $token->[1];

}

$content=~s/[\n\t]//g;

return $content;

}


sub removeXML
{
    $this=shift;
    
    $text = shift;
    
    $text =~ s/\&/\&amp;/g;
    $text =~ s/</\&lt;/g;
    $text =~ s/>/\&gt;/g;
    $text =~ s/\"/\&quot;/g;
    $text =~ s/\'/\&apos;/g;
    
    return $text;
    
}

sub readConfig
{
 my $file_name=shift;
    
    
    open(FILE, "$file_name") || die "Unable to open configuration file - $file_name";
    
#read in config file
    
    $file_content = <FILE>;
    
#    print $file_content;
    
    $file_content =~ s/[\r\f\n]//g;
    $file_content =~ s/\s+//g;
    if($file_content =~ /^GoogleHack/)
    {
	while(<FILE>)
	{
	    s/[\r\f\n]//g;
	    s/\#.*//;
	    s/\s+//g;
	    
	    
	    if(/^basedir::(.*)/)
	    {
		$this->{'basedir'}= $1;
#print $1;
	    }
	    elsif(/^taggerdir::(.*)/)
	    {
		$this->{'taggerdir'}= $1;
#print $1;
	    }
	    
	    elsif(/^key::(.*)/)
	    {
		$this->{'Key'}= $1;
	#	print $1;
		
	    }
	    
	    elsif(/^wsdl::(.*)/)
	    {
		$this->{'File_Location'}= $1;
		#print $1;
		
	    }
	    
	    
	}
	
#	print $this->{'Key'};

	
	
    }
    else
    {
	
	print "\n Config file $file_name is invalid";
	return 0;
    }
    
    
    return $this;
}

# Purpose: given aword, this function tries to retreive the
# text surrounding the search word in the given sentences.
# Pre Condition: Need to pass the search word, 
# Post : A hash of words and frequency of occurence
# @params  searchPhrase -  the search string which can be a word
# @params  proximity -  The number of words surrounding the searchString
# @params  trace_file -  The results of the search will be stored in this file
# returns : A hash of words and frequency of occurence

sub getSurroundingWords
{
    my $searchPhrase=shift;
    my $proximity=shift;
    my @snippet=@_;
    my $stemmer=shift;

    if(!defined($stemmer))
    {
	$stemmer="false";
    }

    %wordsCount=();

    $numIterations=@snippet;

#    print "\n Size is $size\n";
 
   for($x=0; $x < $numIterations; $x++)
    {
	if($snippet[$x])
	{
	    $snippet[$x]=~ s/[\r\f\n]//g;
	    $snippet[$x]=~ s/[\#]//g;
	    $snippet[$x]=~ s/[0-9]+//g;  
	    $snippet[$x]=~ s/(l&;)//g;
	    $snippet[$x]=~ s/(s&;)//g;
#    $snippet=~ s/[...]/\n/g;
	    
	    @sentences = split(/\.+/, $snippet[$x]);
	    
	    
	    $size=@sentences;
	    # %sequences=();
	    
	    $count=0;
	    
	    while($count < $size)
	    {
		$flag="false";
		
		if($sentences[$count])
		{
	#	    print "\n The Sentence is ";
		#    print $sentences[$count];
		 #   print " This \n";
		    
		    @words=split(/\s+|,|\|/, $sentences[$count]);
		    
		    $no_words=@words;
		#    print "\n Number of words is $no_words\n";
		#    for( $i=0; $i < $no_words; $i++)
		#    {
		#	print "\n $searchPhrase - ";
		#	print lc($words[$i]);
		#	print "\n";
		#	if(eq lc($words[$i]))
		#	{
		#	    $flag="true";
		#	    last;
		#	}
		#    }
		    
		    
#		    if($flag eq "true")
	#	    {
			
			for( $i=0; $i < $no_words; $i++)
			{
			    
			    $temp_string=lc($words[$i]);
			    
			    if($stemmer eq "true")
			    {
				@stem = Text::English::stem( "$temp_string" );
				$temp_string="";
				$temp_string=$stem[0];
			    }
			    
			    $wordsCount{"$temp_string"}++ if exists $wordsCount{"$temp_string"};	
			    
			    $wordsCount{"$temp_string"}=1 if !exists $wordsCount{"$temp_string"};	;
			    
			    
			}   
			
		    #}
		    
		    $count++;   
		}
		else
		{
		    $count++;
		    
		}
		
	    }
	    
	}
	
    }
    
    return %wordsCount;

}


# Purpose: Given a search word, this function tries to retreive the
# sentences in the snippet.It is used by GoogleHack::getSnippetSentences.
# The GoogleHack::getSnippetSentences does the search and passes the results to # this functionn.
# Pre Condition: Need to pass the search string, which can be a single word
# We also need to pass the searcInfo, which is a Google-Hack object that has been 
# initialized  to the api key etc.
# Post : A hash of sentences
# @params snippet -  The array containing the snippets.
# returns : A array of sentences

sub getSnippetSentences
{
    my @snippet=@_;

    @sentences=();

    $count=0;

    for($i=0; $i < 10; $i++)
    { 
	if( $snippet[$i])
	{
	    $strings= $snippet[$i];
	    $strings=~ s/[\r\f\n]//g;
	    $strings=~ s/[\#]//g;
	    
	    @temp = split(/\.+/, $strings);
	    
	  #  print $snippet[$i];
	  #  print "\n";  print "\n";
	    $num_sentences=@temp;
	    print "\n Number of sentences is $num_sentences \n\n";
	    for($x=0;$x < $num_sentences; $x++)
	    {
		#print "in here";
	
		$sentences[$count]=$temp[$x];  
	print $sentences[$count];	
	$count++; 

	    }
	    
	}
	
	
    }
    
    return @sentences;

}

# Purpose: Given a search word, this function tries to retreive the
# text surrounding the search word in the retrieved CACHED Web pages.
# It is used by Google-Hack::getCachedSurroundingWords. 
# The Google-Hack::getCachedSurroundingWords function passes the search Phrase
# and the content of cached webpage.
# Pre Condition: Need to pass the search string, which can be a single word
# We also need to pass the searcInfo, which is a Google-Hack object that has been 
# initialized  to the api key etc.
# Post : A hash of words and frequency of occurence
# @params  searchPhrase -  the search string which can be a word
# @params  caachedPage -  the content of the cached webpage.
# returns : A hash of words and frequency of occurence

sub getCachedSurroundingWords
{
    my $searchPhrase=shift;
    my $cachedPage=shift;
    
    $searchPhrase=~ s/\s+//g;
    
    @sentences = split(/\;|\.|\?|\!/, $cachedPage);
    
    $size=@sentences;
    
    $strings=();
    $string_count=0;

    for($x=0; $x < $size; $x++)
    {
    $sentences[$x]=~ s/[\r\f\n]//g;
    $sentences[$x]=~ s/[\#]//g;

#    $snippet=~ s/[...]/\n/g;

   
	$flag="false";

	if($sentences[$x])
	{
	    @words=split(/\s+|,/, $sentences[$x]);

	    $no_words=@words;

	    for( $i=0; $i < $no_words; $i++)
	    {
		$words[$i] =~ s/\s+//g;
		$tempString=lc($searchPhrase);
		if("$tempString" eq lc($words[$i]))
		{
		    $flag="true";
		    last;
		}
	    }

	if($flag eq "true")
	{  
	    for( $i=0; $i < $no_words; $i++)
	    {	    
	
		$strings[$string_count++]=$words[$x];
	    }    
	
	}
    
	}

}

    return @words;

}


sub getCachedSentences
{
    my $searchPhrase=shift;
    my $cachedPage=shift;
    
    $searchPhrase=~ s/\s+//g;
    
    @sentences = split(/\;|\.|\?|\!/, $cachedPage);
    
    $size=@sentences;
    
    $strings=();
    $string_count=0;

    for($x=0; $x < $size; $x++)
    {
    $sentences[$x]=~ s/[\r\f\n]//g;
    $sentences[$x]=~ s/[\#]//g;

#    $snippet=~ s/[...]/\n/g;

   
	$flag="false";

	if($sentences[$x])
	{
	    @words=split(/\s+|,/, $sentences[$x]);

	    $no_words=@words;

	    for( $i=0; $i < $no_words; $i++)
	    {
		$words[$i] =~ s/\s+//g;
		$tempString=lc($searchPhrase);
		if("$tempString" eq lc($words[$i]))
		{
		    $flag="true";
		    last;
		}
	    }

	if($flag eq "true")
	{
	    $strings[$string_count++]=$sentences[$x];
	}    
	
	}
    
}

    return @strings;

}

#################################################
# This code segment is attributed to the Evaluador#
# team from UMD Computer Science NLP Fall 2004#
###############################################

sub Boundary
{
    my $this=shift;
    # local var
    my $infile = shift;
    # array to store processed sentences
    my @data = ();
    # Count index
    my $index = 0;
    my $line = "";

    my $outfile=$this->{'basedir'}."Temp/temp.fr";

    # open the file to read
    open(INFILE, "<$infile") || die "*** Error : Opening $infile to read - Boundary\n";
    while(<INFILE>)
    {
        # remove newline
        chop;
        # apped it to $line .. create on whole string of files
        # and the process them
        $line = $line . " " . $_;
    }
    # Assign $line to $_ .. for easy processing
    $_ = $line;
    # remove any other character besides alpha, space, and (.|!|?)
    tr/a-zA-z.!?0-9%\$\'/ /cs;
    # remove other characters that were no removed such as ^, [, ]
    tr/[|]|^|_|-|&|\#|\@|~/ /s;
    # replace more than one space by one space only.
    s/\s+/ /g;
    # create sentences by split with (.|?|!)
    # replace any leading space too
    while(/(\s*)(((\s|\w|\d)+)(.|\!|\?))/g)
    {
        $data[$index++] = $3;
    }
    # write the output sentence to formatted infile

    open(OUTFILE, ">$outfile") || die "*** Error : Opening $outfile to write - Boundary\n";
    for(my $i=0; $i<$index; $i++)
    {
        print OUTFILE "$data[$i]\n";
    }
    # close the outfile
    close(OUTFILE);
    # check if outfile exists or not
    (-e $outfile) || die "*** Error : $outfile does not exists - Boundary\n";
    #
}


sub parseWebpage
{
 my $webpage=shift;


 require HTML::TokeParser;

 $parser = new HTML::TokeParser (\$webpage);
    $content="";
while ($token = $parser->get_token) {

  next unless $token->[0] eq 'T';
  $content .= $token->[1];

}

 
 $content=~ s/&(.*);/ /g;
 $content=~ s/(\.\.\.)/ /g;
 $content=~ s/\n/\#p\#/g;
 $content=~ s/(<!--)(.*)(-->)//g;
 $content=~ s/(#p#)^(#p#)/\n/g; 
 $content=~ s/(#p#)+/ /g;
 #$content=~ s/(\n\n)+//g;
 $content=~ s/[\t]/ /g;
    return $content;

}


sub POSTagData()
{
    # local variables
    my $this = shift;
    # start getting the input values
    my $filename = $this->{'basedir'}."Temp/temp.fr";
    my $outfile = $filename . ".tg";
    my $location = $this->{'taggerdir'};
    # from current location change to Brill Tagger's folder
    my $var = `pwd`;
    chomp($var);
    (-e "$filename") || print "*** Error : no $filename found - BrillTagger\n";
    (-d "$location") || print "*** Error : no $location found - BrillTagger\n";
    chdir $location;
    $var = `pwd`;
    chomp($var);
    # check if tagger exists or not
    (-e "tagger") || print "*** Error : no tagger file in location - BrillTagger\n";
    # re-direct STDERR from wherever it is now to a log file
    #close STDERR;
    #open (STDERR, '>mEmE') or die "Could not re-open STDERR";    
    # now make a call to tagger
    print "\n running tagger";
    system("tagger LEXICON $filename BIGRAMS LEXICALRULEFILE CONTEXTUALRULEFILE > $outfile");
    # check if file created or not
    (-e "$outfile") || print "*** Error : no outputfile created - BrillTagger\n";
}

1;
