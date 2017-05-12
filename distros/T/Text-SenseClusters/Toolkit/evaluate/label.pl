#!/usr/local/bin/perl -w

=head1 NAME

label.pl - Assign labels to clusters in a confusion matrix to maximize agreement 

=head1 SYNOPSIS

 label.pl [OPTIONS] PRELABEL

Type C<label.pl --help> for a quick summary of options

=head1 DESCRIPTION 

Labels the discovered clusters with sense tags such that maximum number of 
contexts are correctly assigned.

=head1 INPUT

=head2 Required Arguments:

PRELABEL

Should be the output of cluto2label.pl.

Sample CLUTO2LABEL format 

 2
 //	cord  phone   text   div
 C0:	 4       3       0       0
 C1:	 2       2       2       2
 C2:	 1       3       3       2

 where the 1st line shows the number of unclustereted instances = 2 

 2nd line shows a space separated list of sense classes starting with // mark.

Each line thereafter shows the sense distribution of the instances belonging
to each discovered cluster in the form of a cluster by sense distribution
matrix. A cell value at (i,j) in the matrix shows the number of instances
belonging to cluster Ci that have the sense tag Sj.

Note that each row begins with the cluster id that precedes a colon (:).
Also, the number of sense classes on 2nd line should be same as the number 
of columns in the cluster by sense distribution table.

=head2 Optional Arguments:

=head3 --help

Displays this message.

=head3 --version

Displays the version information.

=head1 OUTPUT

Output shows the sense labels attached to each of the discovered 
clusters along with the score. Score tells the percentage of the total 
number of instances correctly clustered if the clusters are tagged with 
the sense labels as suggested.

Example :

Prelabel file =>

 0
 //      cord    divi    form    phon    prod    text
 C0:     35      26      44      18      23      43
 C1:     64      34      50      43      57      52
 C2:     0       3       1       2       0       3
 C3:     0       0       2       31      0       0
 C4:     1       28      0       4       6       0
 C5:     0       9       3       2       14      2

Label Output =>

 ClusterID -> SenseID
 C0 -> form
 C1 -> cord
 C2 -> text
 C3 -> phon
 C4 -> divi
 C5 -> prod
 Score = 30.67

shows that 

 cluster C0 represents the 'form' sense
 cluster C1 represents the 'cord' sense
 cluster C2 represents the 'text' sense
 cluster C3 represents the 'phon' sense
 cluster C4 represents the 'divi' sense
 and cluster C5 represents the 'prod' sense

Also, 30.67 % of the total instances are in their right sense classes
if the clusters are tagged with this labeling scheme.

=cut

#			===============================
#			COMMAND LINE OPTIONS AND USAGE 
#			=============================== 	

use Algorithm::Munkres;

use Getopt::Long;
GetOptions ("help","version");

#command option for help
if(defined $opt_help)
{
        $opt_help=1;
        &showhelp();
        exit;
}
#version information
if(defined $opt_version)
{
        $opt_version=1;
        &showversion();
        exit;
}

#show minimal usage
if($#ARGV<0)
{
        &minimal();
        exit;
}

#truncate $0 which contains the complete path to
#the program. Keep just the program name
#this is used in the error messages
$0=~s/.*\/(.+)/$1/;

# input file
if(defined $ARGV[0])
{
	$infile=$ARGV[0];
	if(-e $infile)
	{
		open(IN,$infile) || die "Error($0): Error(code=$!) in opening file <$infile>.\n";
	}
	else
	{
		print STDERR "ERROR($0): PRELABEL file <$infile> doesn't exist...\n";
		exit;
	}
}
else
{
	print STDERR "ERROR($0): Please specify the PRELABEL file name...\n";
	exit;
}

# first line of prelabel file should show number of instances thrown or 
# unclustered 
# label.pl should just pass this information to next program that computes 
# precision and recall
$thrown=<IN>;
if(!defined $thrown)
{
	print STDERR "ERROR($0):
        1st line in the PRELABEL file <$infile> should show 
	the number of instances unclustered or 0.\n";
        exit;
}
chomp $thrown;
if(!($thrown=~/^\s*\d+\s*$/))
{
        print STDERR "ERROR($0):
        1st line in the PRELABEL file <$infile> should show 
	the number of instances unclustered or 0.\n";
        exit;
}

# 2nd line of prelabel output should list all the Sense Classes
# senses should be space separated 
$sense_string=<IN>;
if(defined $sense_string && $sense_string=~/\/\//)
{
	$sense_string=$';
	$sense_string=~s/\s+$//g;
        $sense_string=~s/^\s+//g;
        $sense_string=~s/\s+/ /g;
	# stores all sense classes listed on this line 
	@all_senses=split(/\s+/,$sense_string);
}
else
{
	print STDERR "ERROR($0):
	2nd line in the input file <$infile> should list 
	the sense labels starting with //.\n";
	exit;
}

# accept matrix entries row wise
$i=0;
# total is the total #instances
$total=0;
# read the input file with each row on each line
$line_num=0;
while(<IN>)
{
	chomp;
	s/\s+$//g;
	s/^\s+//g;
	s/\s+/ /g;
	if(/^\s*$/)
	{
		next;
	}

	# we use cluster ids only while printing
	# the final output 
	# during processing, we use the serial 
	# numbers 0,1,... for clusters in the order
	# as they appear in the prelabel file
	($cid,$row)=split(/\s*:\s*/);
	push @cluster_ids,$cid;
	
	#extract the matrix cells
	@row_elements=split(/\s+/,$row);

	if($#row_elements!=$#all_senses)
	{
		print STDERR "ERROR($0):
	        Number of columns (". scalar(@row_elements) . ") at line <$line_num> 
	        in PRELABEL file <$infile> doesn't match the number of senses (" . 
             	scalar(@all_senses) . ") specified on Line 2 of the same file.\n";
		exit;
	}
	
	for($cnt = 0; $cnt <= $#row_elements; $cnt++)
	{
	    if($row_elements[$cnt]!~/^[0-9]+$/)
	    {
		print STDERR "ERROR($0): Line <" . $line_num+1 . "> in PRELABEL file <$infile> contains a non-integer matrix value.\n";
		exit;
	    }
	    else
	    {
		$inp_mat[$line_num][$cnt] = -1 * $row_elements[$cnt];
		$total += $row_elements[$cnt];
	    }
	}

	$line_num++;
}

my @soln_mat = ();

assign(\@inp_mat, \@soln_mat);
$clus_total = 0;

print "ClusterID -> SenseID\n";
for($i=0;$i<=$#inp_mat;$i++)
{
    if(defined $inp_mat[$i][$soln_mat[$i]])
    {
	$clus_total += $inp_mat[$i][$soln_mat[$i]];
    }
    if(defined $all_senses[$soln_mat[$i]])
    {
	print $cluster_ids[$i] . " -> " . $all_senses[$soln_mat[$i]] . "\n";
    }

}
if($total != 0)
{
    $score = $clus_total/$total * -100;
    $score = sprintf("%.2f",$score);
    print "Score = $score\n";
}
else
{
    print "Score = NA\n";    

}


#show minimal usage message
sub minimal()
{
        print "Usage: label.pl [OPTIONS] PRELABEL";
        print "\nTYPE label.pl --help for help\n";
}

#show help
sub showhelp()
{
	print "Usage: label.pl [OPTIONS] PRELABEL\n";
	print "Labels the discovered clusters with sense tags such\n";
	print "that maximum number of contexts are correctly assigned.\n";

	print "\nPRELABEL\n";
        print "Should be an output created by cluto2label.pl\n";
        print "showing a cluster by sense distribution matrix.\n\n";

        print "OPTIONS:\n";

        print "--help
	Displays this message.\n";

        print "--version
	Displays the version information.\n";
}

#version information
sub showversion()
{
 	print '$Id: label.pl,v 1.15 2008/03/30 05:06:07 tpederse Exp $'; 
#       print "\nCopyright (C) 2002-2006, Ted Pedersen, Amruta Purandare, & Anagha Kulkarni\n";
#        print "label.pl      -       Version 0.11\n";
	print "\nLabel discovered clusters with sense tags to maximize agreement\n";
#	print "Date of Last Update:	11/30/2004\n";
	
}

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Amruta Purandare, University of Pittsburgh

 Anagha Kukarni, Carnegie-Mellon University

=head1 COPYRIGHT

Copyright (c) 2002-2008, Ted Pedersen, Amruta Purandare, Anagha Kulkarni

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

