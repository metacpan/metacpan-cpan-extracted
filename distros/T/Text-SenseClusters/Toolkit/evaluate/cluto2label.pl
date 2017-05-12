#!/usr/bin/perl -w

=head1 NAME

cluto2label.pl - Convert Cluto output to a confusion matrix 

=head1 SYNOPSIS

 cluto2label.pl [OPTIONS] CLUTO KEY

=head1 SYNOPSIS

Converts Cluto's clustering solution file to a cluster by sense distribution matrix to 
then be input to SenseClusters evaluation program L<label.pl>.

=head1 INPUT

=head2 Required Arguments:

=head3 CLUTO 

1st argument should be a clustering solution file (described in section 3.4.1 
on page 34 in Cluto's manual) as created by Cluto's scluster and vcluster 
programs. 

For N instances, CLUTO file will have exactly N lines, each ith line showing 
the cluster number(start from 0) to which the ith instance belongs. 

e.g. 

Cluto's clustering solution file => 

 0
 1
 1
 2
 0
 0
 1
 2

shows the cluster ids of each of the 8 instances clustered by Cluto's program.

 1st, 5th and 6th instance belong to 1st cluster (Cluster No 0)

 2nd, 3rd and 7th instance belong to 2nd cluster (Cluster No 1)

And 

 4th and 8th instance belong to 3rd cluster (Cluster No 2)

Note: cluster id could be possibly -1 which means the corresponding instance 
is not assigned to any cluster

=head3 KEY 

2nd argument should be a KEY file (in SenseCluster's format) showing true sense 
class labels of instances listed in CLUTO. 

For N lines in file CLUTO, KEY should have exactly N lines. Each ith line in 
KEY should minimally show a space separated list of true sense labels of 
ith instance in following format - 

	<sense id="S"/>+

e.g. 

 <sense id="art2"/> <sense id="art4"/>
 <sense id="art1"/>
 <sense id="art3"/><sense id="art4"/>
 <sense id="art3"/>
 <sense id="art4"/> <sense id="art1"/>
 <sense id="art1"/>
 <sense id="art5"/> <sense id="art2"/> <sense id="art3"/>
 <sense id="art2"/> <sense id="art4"/>

Shows the true sense ids of instances in the CLUTO file described in (1).

If KEY is an actual KEY created by SenseClusters programs, KEY will also show 
the instance ids of corresponding instances in the beginning of each line. 

e.g. 

 <instance id="line-n.w7_098:6515:"/> <sense id="art2"/> <sense id="art4"/>

 <instance id="line-n.w8_083:14771:"/> <sense id="art1"/>

 <instance id="line-n.art} aphb 02700649:"/> <sense id="art3"/><sense id="art4"/>

 <instance id="line-n.art} aphb 53900889:"/> <sense id="art3"/>

 <instance id="line-n.w7_066:11025:"/> <sense id="art4"/> <sense id="art1"/>

 <instance id="line-n.art} aphb 42100373:"/> <sense id="art1"/>

 <instance id="line-n.w8_109:8774:"/> <sense id="art5"/> <sense id="art2"/> <sense id="art3"/>

 <instance id="line-n.w7_004:10784:"/> <sense id="art2"/> <sense id="art4"/>

=head2 Optional Arguments:

=head4 --numthrow N

Ignores clusters containing less than N instances. 

=head4 --perthrow P

Ignores clusters containing less than P percent of the instances. 

Number of instances contained in the thrown clusters will be counted as the 
unclustered instances.

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

This will show 

=over 4

=item * 

Number of unclustered instances on 1st line. 

=item * 

Sense Lables of corresponding columns in Cluster Sense Matrix on 2nd line 
starting with marker //

=item * 

Cluster Sense Matrix starting from 3rd line and onwards. The matrix
shows the 
distribution of instances from each sense class (represented by column labels)
in each of the clusters (represented by rows in the Cluster Sense Matrix).

Each cell entry at [i][j] in Cluster Sense distribution matrix shows the number
of instances from ith cluster having true sense class label represented by 
label of jth column.

e.g.

 0
 // art1 art2 art3 art4 art5
 2 1 0 2 0
 1 1 2 1 1
 0 1 1 1 0

Shows that there are no unclustered instances,

1st cluster contains 2 instances having sense id art1 and art4, 1 instance 
having sense id art2 and no instances of sense id art3 and art5.

Similar description applies to 2nd and 3rd clusters.

=back

=head1 SYSTEM REQUIREMENTS

=over 

=item Cluto - L<http://www-users.cs.umn.edu/~karypis/cluto/>

=back

=head1 AUTHORS

 Amruta Purandare, University of Pittsburgh

 Ted Pedersen,  University of Minnesota, Duluth
 tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2002-2008, Amruta Purandare and Ted Pedersen

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
GetOptions ("help","version","numthrow=i","perthrow=f");
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

# argv[0] should be cluto output
if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify the clustering solution file created by Cluto ...\n";
        exit;
}
#accept the output of cluto
$infile=$ARGV[0];
if(!-e $infile)
{
        print STDERR "ERROR($0):
        Cluto solution file <$infile> doesn't exist...\n";
        exit;
}
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening <$infile> file.\n";

# argv[1] should be the KEY file in SenseCluster's format 
if(!defined $ARGV[1])
{
	print STDERR "ERROR($0):
	Please specify the KEY file ...\n";
        exit;
}

#accept the KEY file
$keyfile=$ARGV[1];
if(!-e $keyfile)
{
        print STDERR "ERROR($0):
        KEY file <$keyfile> doesn't exist...\n";
        exit;
}
open(KEY,$keyfile) || die "Error($0):
        Error(code=$!) in opening <$keyfile> file.\n";

##############################################################################

#			===========================
#			    Building KEY Table
#			===========================

$line_num=0;
while(<KEY>)
{
       	$line_num++;
        chomp;
       	# trimming extra spaces from beginning and end
        s/^\s+//g;
       	s/\s+$//g;
        s/\s+/ /g;
       	# handling blank lines
        if(/^\s*$/)
       	{
		print STDERR "ERROR($0):
	Blank file found in KEY file <$keyfile> at line <$line_num>.\n";
		exit;
        }
	@senses_on_line=();
	# get sense ids now
	while(/<sense id=\"([^\"]+)\"\/>/)
	{
		push @senses_on_line,$1;
		$_=$';
	}
	if($#senses_on_line<0)
	{
		print STDERR "ERROR($0):
	No Sense Id found on line <$line_num> in KEY file <$keyfile>.\n";
		exit;
	}
	@{$key_table[$line_num-1]}=@senses_on_line;
}

###############################################################################

#			======================
#			 Reading KEY file now 
#			======================

$line_num=0;
$max_cluster_id=0;
$throw=0;
$instances=0;
while(<IN>)
{
	$line_num++;
        chomp;
        # trimming extra spaces from beginning and end
        s/^\s+//g;
        s/\s+$//g;
        s/\s+/ /g;
        # handling blank lines
        if(/^(\d+)$/)
        {
		$cluster_id=$1;
		$seen_clusters{$cluster_id}=1;
		if($cluster_id>$max_cluster_id)
		{
			$max_cluster_id=$cluster_id;
		}
##		if(!defined @{$key_table[$line_num-1]})
## removed the defined @array per perl deprecation tdp oct 3, 2015
		if(!@{$key_table[$line_num-1]})
		{
			print "ERROR($0):
	Key file <$keyfile> doesn't have enough entries for Cluto solution file
	<$infile>.\n";
			exit;
		}
		foreach $sense (@{$key_table[$line_num-1]})
		{
			$cluster_sense[$cluster_id]{$sense}++;
			$seen_senses{$sense}=1;
		}
		$histo{$cluster_id}++;
		$instances++;
	}
	else
	{
		if(/^-1$/)
		{
			$throw++;
			$instances++;
		}
		else
		{
			print STDERR "ERROR($0):
	Line <$line_num> in Cluto solution file <$infile> should show the 
	number of the cluster to an instance belongs.\n";
			exit;
        	}
	}
}

if($line_num != ($#key_table+1))
{
	print STDERR "ERROR($0):
	Key file <$keyfile> and Cluto solution file <$infile> are incosistent.\n";
	exit;
}

if(defined $opt_perthrow || defined $opt_numthrow)
{
	foreach $cluster (keys %histo)
	{
		if(defined $opt_numthrow && $histo{$cluster}<$opt_numthrow)
		{
			$throw+=$histo{$cluster};
			$thrown{$cluster}=1;
		}
		if(defined $opt_perthrow && ($histo{$cluster}/$instances*100)<$opt_perthrow)
		{
			$throw+=$histo{$cluster};
			$thrown{$cluster}=1;
		}
	}
}

print "$throw\n";
print "\/\/";
foreach $sense (sort keys %seen_senses)
{
	print "\t$sense";
}
print "\n";

foreach $cluster (0..$max_cluster_id)
{
	if(!defined $thrown{$cluster})
	{
		print "C$cluster:";
		foreach $sense (sort keys %seen_senses)
		{
			if(!defined $seen_clusters{$cluster})
			{
				print STDERR "ERROR($0):
	Cluster Ids do not range from 0 to $max_cluster_id in Cluto solution 
	file <$infile>.\n";
				exit;
			}
			if(defined $cluster_sense[$cluster]{$sense})
			{
				print "\t$cluster_sense[$cluster]{$sense}";
			}
			else
			{
				print "\t0";
			}
		}
		print "\n";
	}
}
##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: cluto2label.pl [OPTIONS] CLUTO KEY";
        print "\nTYPE cluto2label.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  cluto2label.pl [OPTIONS] CLUTO KEY 

Displays a Cluster by Sense matrix for the Cluto's clustering solution file 
using a given KEY file.

CLUTO
	Specify Cluto's clustering solution file. This should have exactly n
	lines for n instances clustsred and ith line should show the cluster 
	number to which the ith instance belongs. 

KEY 
	Specify the corresponding KEY file showing true sense tags for each 
	instance in CLUTO file in <sense id=\"S\"\/> tags on each line.

OPTIONS:

--numthrow N 
	Ignores clusters containing less than N instances.

--perthrow P
	Ignores clusters containing less than P percent of the instances.

--help
        Displays this message.

--version
        Displays the version information.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
	print '$Id: cluto2label.pl,v 1.11 2015/10/03 14:05:57 tpederse Exp $';
#        print "\nCopyright (c) 2002-2006, Ted Pedersen & Amruta Purandare\n";
#        print "cluto2label.pl - Version 0.16";
        print "\nConvert Cluto output to confusion matrix\n";
#        print "Date of Last Update:     12/17/2003\n";
}

#############################################################################

