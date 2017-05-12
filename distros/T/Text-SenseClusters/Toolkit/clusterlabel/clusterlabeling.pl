#!/usr/local/bin/perl -w

=head1 NAME

clusterlabeling.pl - Label discovered clusters based on their content

=head1 SYNOPSIS

 clusterlabeling.pl [OPTIONS] INPUTFILE

=head1 DESCRIPTION

Assigns labels to each cluster with the significant word pairs found in 
the cluster contexts. Also separates the clusters in different files.
This is particularly useful for the web-interface.
 
Two types of labels are assigned to each cluster : Descriptive and 
Discriminating. Descriptive labels are the top n significant word pairs.
Discriminating labels are the word-pairs unique to the cluster out of the 
top n significant word-pairs for the cluster.

=head2 Required Arguments:

=head3 INPUTFILE

File created by Toolkit/evaluate/format_clusters.pl with --context option.

=head2 Optional Arguments:

=head4 --token TOKEN

A file containing Perl regex/s that define the tokenization scheme in INPUTFILE file.

If --token is not specified, default token regex file 
token.regex is searched in the current directory.

=head4 --prefix PRE

Specify a prefix to be used for the file names of the cluster files. 
e.g. If the PRE is the prefix specified then cluster with id=0 will
have file name: PRE.cluster.0

If prefix is not specified then prefix is created by concatenating
time stamp to the string "expr".

=head4 --stop STOPFILE

A file of Perl regexes that define the stop list of words to be 
excluded from the features.

STOPFILE could be specified with two modes :

=over 4

=item * AND mode - declared by including '@stop.mode=AND' on the first 
line of the STOPFILE

=item * OR mode - declared by including '@stop.mode=OR' on the first line 
of the STOPFILE [Default]

=back

AND mode ignores word pairs in which both words are stop words.

OR mode ignores word pairs in which either word is a stop word.

=head4 --ngram n

Allows user to set the size of the ngrams that will be used for the 
labels. Valid values are 2, 3, and 4. 

Default value for this option is 2 (i.e. default feature selection)

=head4 --remove N

Removes bigrams that occur less than N times.

Default value for this option is 5

=head4 --window W

Specifies the window size for bigrams. Pairs of words that co-occur 
within the specified window from each other (window W allows at most
W-2 intervening words) will form the bigram features. 

Default window size is 2 which allows only consecutive word pairs.

=head4 --stat STAT

Specifies the statistical scores of association. The following are 
available:

                ll              -       Log Likelihood Ratio [default]
                pmi             -       Point-Wise Mutual Information
                tmi             -       True Mutual Information
                x2              -       Chi-Squared Test
                phi             -       Phi Coefficient
                tscore          -       T-Score
                dice            -       Dice Coefficient
                odds            -       Odds Ratio
                leftFisher      -       Left Fisher's Test
                rightFisher     -       Right Fisher's Test

=head4 --rank R

Word pairs ranking below R when arranged in descending order of 
their test scores are ignored. 

Default value for this option is 10

=head4 --newLine

If turned on, word pair selection process will not span across newlines.

By default this option is turned off, that is, word pair selection spans 
across lines.

=head3 Other Options :

=head4 --help

Displays the quick summary of program options.

=head4 --version

Displays the version information.

=head4 --verbose

Displays to STDERR the current program status.

=head1 OUTPUT

=over

=item 1. Cluster ids followed by the assigned labels are directed to STDOUT:

 Cluster 0 (Descriptive): Bill Clinton, Mariana Islands, Northern Mariana, Pacific island, World Cup, per hour

 Cluster 0 (Discriminating): Mariana Islands, Northern Mariana, Pacific island, World Cup, per hour

 Cluster 2 (Descriptive): Bill Clinton, Erik wrote, Inc Within, Jersey And, Lyle Menendez

 Cluster 2 (Discriminating): Erik wrote, Inc Within, Jersey And, Lyle Menendez

 Cluster 1: 

 Cluster 3:

 Cluster -1 (Descriptive): York Times, Undated _
 
 Cluster -1 (Discriminating): York Times, Undated _

=item 2. Cluster files, named with the specified prefix or the generated prefix.
 
=back

=head1 SYSTEM REQUIREMENTS

Input to this program should be created by L<format_clusters.pl>

=head1 BUGS

=head1 AUTHOR

 Anagha Kulkarni, Carnegie-Mellon University

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

=cut

###############################################################################

#                               THE CODE STARTS HERE

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# command line options
use Getopt::Long;
GetOptions ("help","version","verbose","stop=s","remove=i","window=i","stat=s","rank=i","prefix=s","token=s","newLine", "ngram=n");

# show help option
if(defined $opt_help)
{
        $opt_help=1;
        &showhelp();
        exit;
}

# show version information
if(defined $opt_version)
{
        $opt_version=1;
        &showversion();
        exit;
}

# show minimal usage message if no arguments
if($#ARGV<0)
{
        &showminimal();
        exit 1;
}

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

# ----------
# Input file
# ----------
if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify the INPUTFILE file name...\n";
        exit 1;
}
$inpfile=$ARGV[0];

if(!-e $inpfile)
{
        print STDERR "ERROR($0):
        Could not locate the INPUTFILE file $inpfile.\n";
        exit 1;
}

# --------------
#  Prefix
# --------------

if(defined $opt_prefix)
{
	$prefix=$opt_prefix;
}
else
{
	$prefix="expr" . time();
}


# ---------------
# Tokenfile
# ---------------

if(defined $opt_token)
{
	$token=$opt_token;
}
else
{
	$token="token.regex";
}

if(!-e $token)
{
	print STDERR "ERROR($0):
	Could not locate the TOKEN file $token.\n";
	exit 1;
}

$cwd = `pwd`;
chomp($cwd);

#*********************************************************************

# String to hold ngram option.
$ngram_str = "";

# Added: NGRAM option in the program.
if(defined $opt_ngram){
    $ngram_str = " --ngram $opt_ngram "; 
    
    
	if($opt_ngram < 2 || $opt_ngram > 4)
	{
        print STDERR "\n ERROR($0):
        Labeling mechanism only supports bigrams, trigrams and 4-grams for feature selection.\n";
        exit 1;
	}

}else{
    $ngram_str .= " --ngram 2 "; 
}



# form the parameter string for count.pl
$count_str = "";

if(defined $opt_window)
{
    $count_str .= " --window $opt_window "; 
}

if(defined $opt_stop)
{
    $count_str .= " --stop $opt_stop "; 
}

if(defined $opt_remove)
{
    $count_str .= " --remove $opt_remove "; 
}
else
{
    $count_str .= " --remove 5 "; 
}

if(defined $opt_newLine)
{
    $opt_newLine = $opt_newLine;         # to avoid warnings regarding variable used only once...
    $count_str .= " --newLine "; 
}

$count_str .= " --token $token ";

# Adding the new ngram option here.
$count_str .= $ngram_str;

# form the parameter string for statistic.pl
$stat_str = "";

if(defined $opt_stat)
{
    $stat_str .= " $opt_stat "; 
}
else
{
    $stat_str .= " ll ";
}

if(defined $opt_rank)
{
    $stat_str .= " --rank $opt_rank "; 
}
else
{
    $stat_str .= " --rank 10 "; 
}

# Adding the new ngram option in statistical calculation.
$stat_str .= $ngram_str;





# open the input file in read mode
open(INP,"$inpfile") || die "Error while opening the $inpfile for reading";

# read the complete file in single instruction instead of reading line by line.
my $temp_delimiter = $/;
$/ = undef;
my $inp_str = <INP>;
$/ = $temp_delimiter;

# check if at least one cluster present in the input file.
# if not then cannot generate cluster labels. Probably incorrect file format.
if($inp_str !~ /<cluster/ || $inp_str !~ /<\/cluster>/)
{
    print STDERR "ERROR($0):
		No clusters found in the input file. Probably incorrect input file format. 
		Please use a file created by Toolkit/evaluate/format_clusters.pl with 
		--context option.\n";    
    exit 1;
}
 
# separate the clusters
my @clusters = split(/<\/cluster>/,$inp_str);

my $first_cId = "";

# label hash counter
my $array_cnt = 0;

# String for all the clusters without any labels
my $no_label_clusters = "";

# label each cluster at a time
while($#clusters)
{
    my $cluster = shift @clusters;
    
    # extract the cluster id
    $cluster =~ /<cluster id=\"(.+?)\">/;
    my $cId = $1;
    
    $cluster .= "</cluster>";
    
    # 
    # write out the cluster to a file
    open(CLS,">$prefix.cluster.$cId") || die "Error while creating $prefix.cluster.$cId.xml";
    print CLS $cluster;
    close CLS;
    
    # add time-stamps to the temp files
    my $time_stamp = time();
    my $tmp_txt = "tmp.$time_stamp.cluster.$cId.txt";
    my $tmp_cnt = "tmp.$time_stamp.cluster.$cId.cnt";

    if(defined $opt_verbose)
    {
        print STDERR "Starting sval2text.pl $prefix.cluster.$cId.xml > $tmp_txt\n";
    }

    # call sval2plain.pl for above created cluster file to convert it to plain text
    $status=system("sval2plain.pl $prefix.cluster.$cId > $cwd/$tmp_txt ");
    die "Error while running sval2text.pl $prefix.cluster.$cId.xml > $cwd/$tmp_txt" unless $status==0;

    if(defined $opt_verbose)
    {
        print STDERR "Finished sval2text.pl $prefix.cluster.$cId.xml > $cwd/$tmp_txt\n";
    }

    if(defined $opt_verbose)
    {
        print STDERR "Starting count.pl $count_str $cwd/$tmp_cnt $cwd/$tmp_txt\n";
    }
    
    # call count.pl for this plain text
    $status=system("count.pl $count_str $cwd/$tmp_cnt $cwd/$tmp_txt ");
    die "Error while running count.pl $count_str $cwd/$tmp_cnt $cwd/$tmp_txt" unless $status==0;

    if(defined $opt_verbose)
    {
        print STDERR "Finished count.pl $count_str $cwd/$tmp_cnt $cwd/$tmp_txt\n";
    }
    
    # check the $tmp_cnt file. If does not have any bigram do not proceed to statistic.pl
    open(TP,"$cwd/$tmp_cnt") || die "Error opening $cwd/$tmp_cnt file\n";

    # check the no. of bigrams specified by count.pl on 1st line of o/p file
    $cnt = <TP>;

    close TP;

    # if no. of bigrams more than 0 then proceed
    if($cnt > 0)
    {
	my $tmp_stat = "tmp.$time_stamp.cluster.$cId.stat";

        if(defined $opt_verbose)
        {
            print STDERR "Starting statistic.pl $stat_str $cwd/$tmp_stat $cwd/$tmp_cnt\n";
        }

        # call statistic.pl on count.pl's o/p
        $status=system("statistic.pl $stat_str $cwd/$tmp_stat $cwd/$tmp_cnt ");
        die "Error while running statistic.pl $stat_str $cwd/$tmp_stat $cwd/$tmp_cnt" unless $status==0;
        
        if(defined $opt_verbose)
        {
            print STDERR "Finished statistic.pl $stat_str $cwd/$tmp_stat $cwd/$tmp_cnt\n";
        }

        if(defined $opt_verbose)
        {
            print STDERR "Starting selection of labels...\n";
        }
    
        # format statistic.pl's o/p to be shown as labels for the cluster
        open(FP,"$cwd/$tmp_stat") || die "Error while opening the file $cwd/$tmp_stat";
        
        <FP>;
      
  
        while(<FP>)
        {
            @tmp = split(/<>/);

            # Following code will support the ngram features for label.
            $label = "";

			# If ngram is defined, use that as features.
            if(defined $opt_ngram){
	 			$labelSize = $opt_ngram;	           
		        foreach $tempName (@tmp) {
		        	if($labelSize > 0){
					    $label = $label." ".$tempName;
					    $labelSize--;
					}else{
						last;
					}
		        }
			}else{
			# If ngram is not defined then default feature is bigram.			
			   	$label = "$tmp[0] $tmp[1]";            
            }
          
            
            $l_aoh[$array_cnt]{$label} = $cId;
        }

        close FP;
        
        # delete the temporary files
	unlink "$cwd/$tmp_txt", "$cwd/$tmp_cnt", "$cwd/$tmp_stat";

        $array_cnt++;
    }
    else
    {
	if($cId ne "-1")
	{
	    # no bigrams were returned by count.pl 
	    # thus print just the cluster id
	    $no_label_clusters .= "Cluster $cId: \n";
	}
	else # misc cluster
	{
	    $no_lbl_misc_clust = "Cluster -1:";
	}

        # and delete the temporary files (note *.stat never gets created in this case)
        unlink "$cwd/$tmp_txt", "$cwd/$tmp_cnt";
    }
}

# find the unique/discriminating labels

# check each label for its uniqueness.
# if unique add to the label string else add to the hash of non-unique labels

$non_uni = {};

for $i ( 0 .. $#l_aoh )
{
	$labels = "";
	for $key (keys %{$l_aoh[$i]} )
	{
		$clusId = $l_aoh[$i]{$key};
		$c_lab = $key;

		# first check in the non-unique hash 
		if(!exists $non_uni{$c_lab})
		{
			# now check in all the other hashes i.e.clusters
			$flag = 0;
			for $j ( 0 .. $#l_aoh )
			{
				if($j == $i) 
				{
					next;
				}
				
				if(exists $l_aoh[$j]{$c_lab})
				{
					$non_uni{$c_lab} = $c_lab;
					$flag = 1;
					last;
				}
			}
			
			# found unique label
			if($flag == 0)
			{
				$labels .= $c_lab . ", ";
			}
		}
	}
	
	# remove the extra ',' and space at the end
	$labels = substr($labels, 0, length($labels)-2);
    
	
	# for descriptive labels
	$desc_labels = "";
	for $key (keys %{$l_aoh[$i]} )
	{
		$desc_labels .= $key . ", ";
	}
	
	# remove the extra ',' and space at the end
	$desc_labels = substr($desc_labels, 0, length($desc_labels)-2);
    
	if($clusId ne "-1") 
	{	
		# print the descriptive labels with the cluster id
		print "Cluster $clusId (Descriptive): $desc_labels\n\n";
		
		# print the discriminating labels with the cluster id
		print "Cluster $clusId (Discriminating): $labels\n\n";
	}
	else # misc cluster (Cluster -1)
	{
		$desc_misc_clust = $desc_labels;
		$disc_misc_clust = $labels;
	}
}

# print the clusters without any labels at the end.
print $no_label_clusters;

# print the labels for the misc cluster (Cluster -1)
# If: Misc cluster present but no labels found
if(defined $no_lbl_misc_clust)
{
	print $no_lbl_misc_clust;
}
elsif(defined $desc_misc_clust) # Misc cluster present and labels identified too
{
	print "Cluster -1 (Descriptive): $desc_misc_clust\n\n";
	print "Cluster -1 (Discriminating): $disc_misc_clust\n\n";
}

if(defined $opt_verbose)
{
    print STDERR "Finished selection of labels...\n";
}


#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: clusterlabeling.pl [OPTIONS] INPUTFILE";
        print "\nTYPE clusterlabeling.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  clusterlabeling.pl [OPTIONS] INPUTFILE 

Assigns labels to each cluster with the significant word pairs 
found in the cluster contexts. Also separates the clusters in 
different files. This is particularly useful for the web-interface.

Two types of labels are assigned to each cluster : Descriptive and 
Discriminating. Descriptive labels are the top n significant word
pairs. Discriminating labels are the top word-pairs unique to the 
cluster out of the top n significant word-pairs for the cluster.

INPUTFILE

File created by format_clusters.pl with --context option.

Optional Arguments:

--token TOKEN

A file containing Perl regex/s that define the tokenization scheme 
in INPUTFILE file.

If --token is not specified, default token regex file 
token.regex is searched in the current directory.

--prefix PRE

Specify a prefix to be used for the file names of the cluster files. 
e.g. If the PRE is the prefix specified then cluster with id=0 will
have file name: PRE.cluster.0

If prefix is not specified then prefix is created by concatenating
time stamp to the string expr.

--stop STOPFILE

A file of Perl regexes that define the stop list of words to be 
excluded from the features.

STOPFILE could be specified with two modes -

  1. AND mode - declared by including \@stop.mode=AND on the 
     first line of the STOPFILE. Ignores word pairs in which
     both words are stop words. 

  2. OR mode - declared by including \@stop.mode=OR on the first 
     line of the STOPFILE. Ignores word pairs in which either
     word (or both) is a stop word. [Default] 

--remove N

Removes bigrams that occur less than N times.

Default value for this option is 5

--window W

Specifies the window size for bigrams. Pairs of words that co-occur 
within the specified window from each other (window W allows at most 
W-2 intervening words) will form the bigram features. 

Default window size is 2 which allows only consecutive word pairs.

--stat STAT

Specifies the statistical scores of association. The following are 
available:

                ll              -       Log Likelihood Ratio [default]
                pmi             -       Point-Wise Mutual Information
                tmi             -       True Mutual Information
                x2              -       Chi-Squared Test
                phi             -       Phi Coefficient
                tscore          -       T-Score
                dice            -       Dice Coefficient
                odds            -       Odds Ratio
                leftFisher      -       Left Fisher's Test
                rightFisher     -       Right Fisher's Test

--rank R

Word pairs ranking below R when arranged in descending order of 
their test scores are ignored. 

Default value for this option is 10

--ngram n

This parameter allows user to enter the value of ngram for feature selections. 
The supported values for n are 2, 3 and 4.

Default value for this option is 2 (i.e. default feature selectection is bigram).

--newLine

If turned on, word pair selection process will not span across newlines.

By default this option is turned off, that is, word pair selection spans 
across lines.

Other Options:

--verbose
	Displays to STDERR the current program status.

--help
        Displays this message.

--version
        Displays the version information.

Type 'perldoc clusterlabeling.pl' to view the detailed documentation.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
	print '$Id: clusterlabeling.pl,v 1.35 2013/06/27 14:44:48 tpederse Exp $';
	print "\nLabel discovered clusters based on their content\n";
#        print "\nCopyright (c) 2004-2006, Ted Pedersen, & Anagha Kulkarni\n";
#        print "clusterlabeling.pl      -       Version 0.04\n";
#        print "Cluster labeling program.\n";
#        print "Date of Last Update:     01/22/2006\n";
}

#############################################################################

=head1 COPYRIGHT

Copyright (c) 2004-2008,2013 Anagha Kulkarni and Ted Pedersen

This program is free software; you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the Free 
Software Foundation; either version 2 of the License, or (at your option) 
any later version.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
for more details.

You should have received a copy of the GNU General Public License along 
with this program; if not, write to

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut


