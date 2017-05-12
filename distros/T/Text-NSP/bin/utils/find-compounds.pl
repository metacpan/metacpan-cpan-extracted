#!/usr/local/bin/perl -w

=head1 NAME

find-compounds.pl - find compound words in a text that are specified in a list.

=head1 DESCRIPTION

See perldoc find-compounds.pl 

=head1 USAGE

find-compounds.pl SourceFile CompoundWordList 

=head1 INPUT

=head2 Required Arguments:

=head4 SourceFile

Source file is the original text file.

=head4 CompoundWordList 

Compound word list contains the compound words. Compound words
are seperated by underscore "_". Each compound word is a line. 

=head3 Examples:

The original text contains "This is the new york city". In the 
compound word list, it has

 new_york
 new_york_city

The find-compounds.pl will find the longest match. After replace
the compound words, the text is "This is the new_york_city". 

=head3 Other Options:

=head4 --newline

Find compound words within one line boundary with this option. If run
find-compounds.pl without this option, find compound words crossing
lines. 

Displays this message.

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 AUTHOR

Ying Liu.
University of Minnesota at Twin Cities.
liux0395@umn.edu

=head1 COPYRIGHT

Copyright (c) 2010-2011, Ying Liu

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

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# command line options
use Getopt::Long;
GetOptions ("help","version", "newline");

# show help option
if(defined $opt_help)
{
    $opt_help = 1;
    &showHelp();
    exit;
}

# show version information
if(defined $opt_version)
{
    $opt_version = 1;
    &showVersion();
    exit;
}

# newline option 
if(defined $opt_newline)
{
    $opt_newline = 1;
}
else
{
    $opt_newline = 0;
}

#############################################################################
#           ========================
#                 CODE SECTION
#           ========================

# first check if no commandline options have been provided... in which case
# print out the usage notes!
if ( $#ARGV == -1 )
{
    &minimalUsageNotes();
    exit;
}

my $list_file = $ARGV[1]; 
open(LST1, "$list_file") or die ("Error: cannot open file $list_file for input.\n");

# read the compound txt and put them in the hash array. 
my %complist = ();
while (my $line = <LST1>)
{
    chomp($line);
    if ($line ne "") {
	my $lower_case = lc($line);
	my @string = split('_', $lower_case);	
	my $head = shift(@string);
	
	my $rest = join (' ', @string);
	push (@{$complist{$head}}, $rest); 
    }
    
}
close LST1;

# sort the compound txt 
foreach my $h (sort (keys (%complist)) )
{
    my @sort_list = sort(@{$complist{$h}});
    
    for my $i (0..$#sort_list)
    {
	$complist{$h}[$i] = $sort_list[$i]; 
    } 
}

my $input_file = $ARGV[0] ;
if ( !($input_file ) )
{
    print STDERR "No source file supplied.\n";
    askHelp();
    exit;
}
open(TXT, "<$input_file") or die ("Error: cannot open file $input_file for input.\n");

while (my $line = <TXT>)
{
    chomp($line);
    my @words = split(' ', $line);
    my $size_line = @words;
    
    #for every word of the line, check the compound word
    for (my $i=0; $i<$size_line; $i++)
    {
	if (($opt_newline==0) and ($i==$size_line-1))
	{
	    while($line = <TXT>)
	    {	
		chomp($line);
		my @line_words = split(' ', $line);
		push (@words, @line_words);							
		$size_line = @words; 
	    }
	}
	
	my $w = $words[$i];
	my $w_lower = lc($w);
	my $flag_print_w = 0;
	my $flag_comp = 0;
	my $flag_comp2 = 0;
	
	if(defined $complist{$w_lower})
	{
	    # get the compound list start with word $w
	    my @comps = @{$complist{$w_lower}};					
	    my @string_match= ();
	    foreach my $c (@comps)
	    {
		# compare the rest of the compound word  
		my @string = split(' ', $c);
		my @text_string = ();
		my $count = 1;			
		my $flag_compstring = 0;
		for(my $j=0; $j<@string; $j++)
		{
		    # read a new line if without the line boundary
		    if (($opt_newline==0) and (($i+$count)==($size_line-1)))
		    {
			while($line = <TXT>)
			{	
			    chomp($line);
			    my @line_words = split(' ', $line);
			    push (@words, @line_words);							
			    $size_line = @words; 
			}
		    }
		    
		    # match string 
		    if (($i+$count)<$size_line)    
		    {
			my $match_word = lc($words[$i+$count]);		
			my @match_chars = split('', $match_word);
			my @char_string = ();
			
			# no signs
			foreach my $char (@match_chars)
			{
			    if ($char =~ /[a-z]/)	
			    {
				push(@char_string, $char);
			    }
			}
			
			$match_word = join('', @char_string);
			if ($string[$j] eq $match_word)
			{
			    $flag_comp = 1;			
			    push(@text_string, $words[$i+$count]);
			    $count++;
			}			
			else
			{
			    $flag_comp = 0;
			    last;
			}
		    }
		    
		    # couldn't finish a full compound word string
		    #print "i = $i count=$count size_line=$size_line j=$j \n";
		    if ((($i+$count)==$size_line) and ($j<@string-1))
		    {
			$flag_comp = 0;
		    }
		    
		} # test one compound word start by $w_lower															
		# connect the compound word  	
		if ($flag_comp==1)
		{
		    unshift(@text_string, "$w");
		    my $comp = join('_', @text_string);		
		    push(@string_match, $comp);								
		    $flag_comp2 = 1;
		}	
	    }
	    # print out the $w if it doesn't match any compound words
	    if (($flag_print_w==0) and ($flag_comp2==0))
	    {
		print "$w ";				
		$flag_print_w = 1;
	    }
	    
	    if ($flag_comp2==1)
	    {
		my $longest = 0;
		my $longest_string = "";
		foreach my $s (@string_match)
		{
		    if($longest < length($s))
		    {
			$longest = length($s);
			$longest_string = $s;
		    }		
		}	
		print "$longest_string ";				
		my @string = split('_', $longest_string);
		my $skip = @string-1;
		$i = $i + $skip;
	    }
	} # test all the compound word start by $w	
	else
	{
	    print "$w ";				
	    
	}	
	
    } # end of defined compound word start by $w
    
    print "\n";				
    
} # end of every line of the file

close TXT;

#-----------------------------------------------------------------------------
#                       User Defined Function Definitions
#-----------------------------------------------------------------------------

# function to output a minimal usage note when the user has not provided any
# commandline options
sub minimalUsageNotes
{
    print STDERR "Usage: find-compounds.pl Sourcefile CompoundWordList\n";
    askHelp();
}

# function to output "ask for help" message when the user's goofed up!
sub askHelp
{
    print STDERR "Type find-compounds.pl --help for help.\n";
}

# function to output help messages for this program
sub showHelp
{
    print "\n";
    print "Usage: find-compounds.pl Outputfile Sourcefile CompoundWordList\n\n";

    print "Identify the the compound words in the source file as found\n";
    print "in the file CompoundWordList. Compound words are connected by\n";
    print "an underscore.\n\n";
    
    print "OPTIONS:\n\n";
    
    print "  --newline          Find compound words in one line.\n\n";

    print "  --version          Prints the version number.\n\n";

    print "  --help             Prints this help message.\n\n";
}

# function to output the version number
sub showVersion
{
    print STDERR 'find-compounds.pl $Id: find-compounds.pl,v 1.10 2013/02/15 22:50:57 btmcinnes Exp $';
    print STDERR "\nCopyright (C) 2009-2011, Ying Liu\n";

}




