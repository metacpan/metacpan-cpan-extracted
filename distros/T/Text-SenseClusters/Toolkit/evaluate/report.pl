#!/usr/local/bin/perl -w

=head1 NAME

report.pl - Summarize SenseClusters results with precision, recall, and confusion matrix

=head1 SYNOPSIS

 report.pl [OPTIONS] LABEL PRELABEL

Type C<report.pl --help> for a quick summary of options

=head1 DESCRIPTION 

Reports the performance of discrimination in terms of the precision, recall 
and confusion table.

=head1 INPUT

=head2 Required Arguments:

=head3 LABEL 

An output created by label.pl showing sense labels attached to 
the discovered clusters. 

Sample LABEL files =>

=over 

=item 1. report.pl will minimally expect LABEL in this format -

 C0 -> fine%5:00:00:elegant:00
 C1 -> fine%3:00:00::
 C2 -> fine%5:00:00:superior:02
 C3 -> fine%5:00:00:satisfactory:00
 C4 -> fine%5:00:00:thin:01

report will only read those lines from LABEL file that contain right arrow 
(->), all other lines will be ignored.

Lines containing '->' should show the cluster id on the left of the arrow 
and a sense tag on the right.

=item 2.

 ClusterID -> SenseID
 0 -> fine%5:00:00:elegant:00
 1 -> fine%3:00:00::
 2 -> fine%5:00:00:superior:02
 3 -> fine%5:00:00:satisfactory:00
 4 -> fine%5:00:00:thin:01
 Score = 60.00

Shows the actual output of label which contains a descriptive header line
on the 1st line and the score of the mapping scheme on the last line.

=back

=head3 PRELABEL

Should be an output created by cluto2label.pl program showing the 
distribution of instances from each sense class in each of the clusters.

This distribution should be shown in a cluster by sense matrix where the 
rows represent the clusters and the columns represent the senses. Cell entry
at CS[i][j] shows the number of instances belonging to cluster Ci that
have the true true sense tag Sj.

e.g.

 0
 //phone	cord	txt	div	form
 0       	2       1       0       0
 0       	1       2       4       0
 5       	2       2       25      4
 0       	1       9       0       0
 0       	1       0       1       0

Note that -

=over

=item 1. 1st line shows the number of instances unclustered. 

=item 2. 2nd line starts with // and shows the sense labels of corresponding columns.

=item 3. 3rd line and onwards show the cluster by sense distribution matrix.

=back

=head2 Optional Arguments:

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Output will display a confusion table whose rows represent the discovered 
clusters and columns represent the actual sense classes such that cell value at
(i,j) indicates the number of instances belonging to cluster Ci that have true
sense id Sk where Sk is the column label on the top of the jth column. 
Columns are reordered such that the sense representing the rth column most 
accurately represents the rth cluster Cr and diagonal value at (r,r) shows the 
number of instances in the rth cluster that belong to their correct sense class.

When #clusters > #senses, clusters that aren't assigned a sense tag will 
have star (*) on them. When #senses > #clusters, senses that aren't assigned
to any cluster will be hash (#) marked.

The sum of the diagonal entries shows the total number of instances that are 
correctly discriminated(#hits). From this number, report computes precision
and recall where 

 precision = #hits / #clustered

#clustered = Number of instances clustered = total #instances - #instances 
that belong to the unlabelled clusters - #thrown shown in PRELABEL input file.

 recall = #hits / #total instances

Sample Output : 

        S1      S2      S0      S3      TOTAL
 C0:     221     11      3       15      250     (5.71)
 C1:     295     395     448     144     1282    (29.28)
 C6:     430     233     441     68      1172    (26.77)
 C9:     145     44      149     105     443     (10.12)
 C2:*    0       1       135     2       138     (3.15)
 C3:*    138     4       4       2       148     (3.38)
 C4:*    0       0       182     0       182     (4.16)
 C5:*    2       6       150     6       164     (3.75)
 C7:*    41      159     99      97      396     (9.05)
 C8:*    0       0       203     0       203     (4.64)
        1272    853     1814    439     4378
        (29.05) (19.48) (41.43) (10.03)
 Precision = 36.92(1162/3147)
 Recall = 26.54(1162/4378+0)

 Legend of Sense Tags
 S0 = SERVE10
 S1 = SERVE12
 S2 = SERVE2
 S3 = SERVE6
 
shows 

=over 

=item 1. 9 clusters(C0-C8) and 4 senses (S0-S3). 

=item 2. Cluster C0 represents sense S1 which stands for actual sense SERVE12

 C1 represents S2 (stands for SERVE2),
 C6 represents S0 (stands for SERVE10)
 C9 represents S3 (stands for SERVE6)

=item 3. The above maximal mapping gives precision of 36.92% and recall of 26.54%
where total 1162 instances are correctly discriminated among the total 4378
instances.

=item 4. The last two columns show the total number and percentage of instances in 
each cluster(row marginal totals) while the last two rows indicate the total 
number and percentage of instances in each sense class(column marginal totals).

=back

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth

 Amruta Purandare, University of Pittsburgh

 Anagha Kulkarni, Carnegie-Mellon University

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

=cut

###############################################################################

#                               THE CODE STARTS HERE

###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# show minimal usage message if no arguments
if($#ARGV<0)
{
        &showminimal();
        exit;
}

# command line options
use Getopt::Long;
GetOptions ("help","version");
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

#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Specify the Label file ...\n";
        exit;
}
#accept the label file name
$labelfile=$ARGV[0];
if(!-e $labelfile)
{
        print STDERR "ERROR($0):
        Label file <$labelfile> doesn't exist...\n";
        exit;
}
open(LAB,$labelfile) || die "Error($0):
        Error(code=$!) in opening <$labelfile> file.\n";

if(!defined $ARGV[1])
{
        print STDERR "ERROR($0):
        Please specify the Prelabel file ...\n";
        exit;
}
#accept the cluster by sense matrix file
$prelabfile=$ARGV[1];
if(!-e $prelabfile)
{
        print STDERR "ERROR($0):
        Prelabel file <$prelabfile> doesn't exist...\n";
        exit;
}
open(PRE,$prelabfile) || die "Error($0):
        Error(code=$!) in opening <$prelabfile> file.\n";

##############################################################################

#			========================
#			    ACCEPTING MATRIX
#			========================
$line_num=0;
# first line of pre-label output should show the number of instances 
# unclustered 
# this should be counted while computing recall
$thrown=<PRE>;
if(!defined $thrown)
{
	print STDERR "ERROR($0):
        1st line of the Prelabel file <$prelabfile> should show the number of 
	instances unclustered or 0.\n";
        exit;
}
chomp $thrown;
$thrown=~s/^\s*//g;
$thrown=~s/\s*$//g;
if(!($thrown=~/^\d+$/))
{
        print STDERR "ERROR($0):
        1st line of the Prelabel file <$prelabfile> should show number of 
	instances unclustered or 0.\n";
        exit;
}

# 2nd line should show the Sense Label list starting with //
$sense_string=<PRE>;
if(defined $sense_string && $sense_string=~/\/\//)
{
	# remove // 
	$sense_string=$';
        $sense_string=~s/\s*$//g;
        $sense_string=~s/^\s*//g;
        @all_senses=split(/\s+/,$sense_string);
}
else
{
        print STDERR "ERROR($0):
        The 2nd line of the Prelabel file <$prelabfile> must contain 
	the sense labels starting with //.\n";
        exit;
}

foreach $sid (0..$#all_senses)
{
	$sids{$all_senses[$sid]}=$sid;
}

$total=0;
while(<PRE>)
{
	$line_num++;
        # trimming extra spaces
        chomp;
        s/\s*$//g;
        s/^\s*//g;
        s/\s+/ /g;
	# handling blank lines
        if(/^\s*$/)
        {
                next;
        }

	if($_ =~ /\s*:\s*/)
	{
		($cid,$row)=split(/\s*:\s*/);
	}
	else
	{
		print STDERR "ERROR($0):
	Wrong format of Prelabel file <$prelabfile> at line <$line_num>.\n";
		exit;
	}

	@row_elements=split(/\s+/,$row);
	if($#row_elements!=$#all_senses)
        {
		print STDERR "ERROR($0):
        Number of columns (". scalar(@row_elements) . ") at line <$line_num>
        in the Prelabel file <$prelabfile> doesn't match the number of 
	senses (" . scalar(@all_senses) . ") specified on Line 2 of the 
	same file.\n";
                exit;
        }
	foreach $sense(@all_senses)
        {
                if(!($row_elements[0]=~/\s+/))
                {
                        if(!($row_elements[0]=~/^[0-9]+$/))
                        {
                                print STDERR "ERROR($0):
	Line <$line_num> in the Prelabel file <$prelabfile> contains 
	a non-integer matrix value.\n";
                                exit;
                        }
			# make an entry in the matrix
                        $cluster_sense{$cid}{$sense}=shift(@row_elements);
			$total+=$cluster_sense{$cid}{$sense};
                }
        }
}

##############################################################################

#			==============================
#				ACCEPT MAPPINGS
#			==============================

$line_num=0;
while(<LAB>)
{
	$line_num++;
        # trimming extra spaces
        chomp;
        s/\s*$//g;
        s/^\s*//g;
        # handling blank lines
        if(/^\s*$/)
        {
                next;
        }
	if(/^(.*)\s*->\s*(.*)$/)
	{
		# skip header
		if($1 !~ /ClusterID/)
		{
			$sense=$2;
			$cid=$1;
			push @senses,$sense;
			$labels{$sense}=1;
			$cid=~s/\s*$//g;
			push @clusters,$cid;
			$labelled{$cid}=1;
			if(!defined $cluster_sense{$cid}{$sense})
			{
				print STDERR "ERROR($0):
	Cluster-Sense pair <$cid,$sense> in the Label file <$labelfile> doesn't
	have any entry in the Prelabel file <$prelabfile>.\n";
				exit;
			}
		}
	}
}

# senses that are not assigned to 
# any clusters appear on the right
# side of the confusion matrix

foreach $sense (@all_senses)
{
	if(!defined $labels{$sense})
	{
		push @senses,$sense;
	}
}

# clusters that are not assigned any
# tags appear at the bottom of the
# confusion table

foreach $cluster (sort keys %cluster_sense)
{
	if(!defined $labelled{$cluster})
	{
		push @clusters,$cluster;
	}
}
##############################################################################

#			===========================
#			      FINDING MARGINALS
#			===========================

# finding marginals
$attempted=0;
foreach $cluster (@clusters)
{
	$row_margin=0;
	foreach $sense (0..$#senses)
	{
		if(!defined $cluster_sense{$cluster}{$senses[$sense]})
		{
			print STDERR "ERROR($0):
	Prelabel file <$prelabfile> and Label File <$labelfile> are 
	inconsistent.\n";
			exit;
		}
		if(!defined $col_marginals{$senses[$sense]})
		{
			$col_marginals{$senses[$sense]}=0;
		}
		$col_marginals{$senses[$sense]}+=$cluster_sense{$cluster}{$senses[$sense]};
		if(defined $labelled{$cluster})
		{
			$attempted+=$cluster_sense{$cluster}{$senses[$sense]};
		}
		$row_margin+=$cluster_sense{$cluster}{$senses[$sense]};
	}
	push @row_marginals,$row_margin;
}


##############################################################################

#			=========================
#			      OUTPUT SECTION
#			=========================

printf "%6s"," ";
foreach $sense (@senses)
{
	printf("%8s","S$sids{$sense}");
	if(!defined $labels{$sense})
        {
                print "#";
        }
	print "\t";
}
printf("%8s\t","TOTAL");
$hits=0;
foreach $cluster (0..$#clusters)
{
	printf "\n%4s:","$clusters[$cluster]";
	if(!defined $labelled{$clusters[$cluster]})
	{
		print "*";
	}
	else
	{
		print " ";
	}
	foreach $sense (0..$#senses)
	{
		printf("%8s\t",$cluster_sense{$clusters[$cluster]}{$senses[$sense]});
		if($cluster==$sense)
		{
			# counting number of instances tagged correctly
			$hits+=$cluster_sense{$clusters[$cluster]}{$senses[$sense]};
		}
	}
	printf("%8s\t",$row_marginals[0]);
	printf "(%2.2f)", $row_marginals[0]/$total*100;
	shift @row_marginals;
}

printf "\n%6s","TOTAL";
foreach (@senses)
{
	printf("%8s\t",$col_marginals{$_});
}
printf("%8s\n",$total);

printf "%6s"," ";

foreach (@senses)
{
    printf "%3s", " ";    
    printf("(%2.2f)",$col_marginals{$_}/$total*100," ");
}

my $precision = $hits/$attempted*100;
my $recall = $hits/($total+$thrown)*100;
my $fmeasure = 2 * $precision * $recall / ($precision + $recall);

printf "\nPrecision = %2.2f($hits/$attempted)\n",$precision;
printf "Recall = %2.2f($hits/$total+$thrown)\n",$recall;
printf "F-Measure = %2.2f\n",$fmeasure;

print "\nLegend of Sense Tags\n";
foreach $sense (@all_senses)
{
	print "S$sids{$sense} = $sense\n";
}
##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: report.pl [OPTIONS] LABEL PRELABEL";
        print "\nTYPE report.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  report.pl [OPTIONS] LABEL PRELABEL

Evaluates the discrimination performance by printing the precision, recall
and confusion matrix.

LABEL
	Output of label.pl program.
PRELABEL
	Output of cluto2label.pl program.

OPTIONS:
--help
        Displays this message.
--version
        Displays the version information.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
	print '$Id: report.pl,v 1.14 2008/03/30 05:06:07 tpederse Exp $';
#        print "\nCopyright (C) 2002-2006, Ted Pedersen, Amruta Purandare & Anagha Kulkarni\n";
#        print "report.pl      -       Version 0.06\n";
        print "\nReports Precision, Recall, F-Measure and Confusion table\n";
#        print "Date of Last Update:     01/19/2005\n";
}

#############################################################################

