#!/usr/local/bin/perl -w

=head1 NAME

format_clusters.pl - Map Cluto output to Senseval-2 format input file

=head1 SYNOPSIS

 format_clusters.pl [OPTIONS] CLUTO_SOLUTION RLABEL

=head1 DESCRIPTION

This program maps Cluto's clustering solution file into Senseval2 input file
to give more legible forms of output.

=head1 INPUT

=head2 Required Arguments:

=head3 CLUTO_SOLUTION

This is an output file from Cluto that shows which cluster each context 
is assigned to. This is referred to as *.cluster_solution by the 
SenseClusters Web interface, or can be specified via the -clustfile option 
in Cluto. It consists of N lines, where N is the number of contexts, each 
each line contains an integer value indicating the cluster to which the 
context represented by that line is assigned. 

Each line of this file shows the cluster id assigned to the instance id, 
specified at the same line number in *.rlabel file. The number of lines
in the CLUTO_SOLUTION file should be the same as in the RLABEL file. 

=head3 RLABEL

Row Label shows the instance id to which the cluster id, specified at the same 
line number in *.cluster_solution is assigned.
The file name has an extension as .rlabel 

=head3 Other Options :

=head4 --context SENSEVAL2

SENSEVAL2 should be a file of contexts formatted in the Senseval2 format.
These are the contexts that have been clustered. The --context option 
causes the contexts to be reorganized such that those that occur in the 
same cluster are grouped together. 

=head4 --senseval2 SENSEVAL2

SENSEVAL2 should be a file of contexts formatted in the Senseval2 format. 
These are the contexts that have been clustered. The --senseval2 option 
causes the contexts to be assigned (or tagged) with the cluster value 
assigned by Cluto. This cluster value will be put into the answer tag. 
They are displayed in their original order. 

=head4 --help

Displays the summary of command line options.  

=head4 --version

Displays the version information.

=head1 OUTPUT

If neither of the options (--context or --senseval2) are specified,
the default behavior is that contexts are identified by instance id *only*
and grouped together by clusters. Thus, the actual written contexts
are not displayed in this case. 

Each line is formatted as -

 <cluster id="CID"> 
   [<instance id="IID"/>]+ 
 </cluster>

If --context option is used, then all the instances 
along with the actual context data, grouped by clusters are displayed.
The output sent to STDOUT looks like:

 <cluster id="CID"> 
   [<instance id="IID"><context>DATA</context></instance>]+ 
 </cluster>

If --senseval2 option is used, then output is copy of the 
input senseval2 file except that now, answer tags contain 
cluster id assigned to the instance.
The output is sent to STDOUT.

Note: --context and --senseval2 cannot be used together.

=head1 BUGS

=head1 SYSTEM REQUIREMENTS

=over

=item Cluto -  L<http://www-users.cs.umn.edu/~karypis/cluto/>

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

##############################################################################
#
#                       ===============================
#                       COMMAND LINE OPTIONS AND USAGE
#                       ===============================

#$0 contains the program name along with
#the complete path. Extract just the program
#name and use in error messages
$0=~s/.*\/(.+)/$1/;

use Getopt::Long;
GetOptions ("context=s","senseval2=s","help","version");

#if context and senseval2 both the options are specified
#display an error message and exit.
if(defined $opt_context && defined $opt_senseval2)
{
	print STDERR "ERROR($0):
		--context and --senseval2 options cannot be specified in a single run!\n";
	exit 1;
}

#command option for context
if(defined $opt_context)
{
    $inp_context = $opt_context;
    if(!-e $inp_context)
    {
	print STDERR "ERROR($0):
		Senseval2 formatted input file $inp_context does not exist.\n";
	exit 1;
    }

    # check if the file $inp_context is a Senseval2 formatted file
    open(SCON, $inp_context) || die "Error in opening the senseval2 input file $inp_context. \n";

    # read the complete file in single instruction instead of reading line by line.
    my $temp_delimiter = $/;
    $/ = undef;
    
    my $inp_str = <SCON>;

    $/ = $temp_delimiter;
    close SCON;

    if($inp_str !~ m/<corpus/i || $inp_str !~ m/<lexelt/i || $inp_str !~ m/<instance/i || $inp_str !~ m/<context/i)
    {
	print STDERR "ERROR($0):
		File <$inp_context> is not in Senseval-2 format. \n";
	exit 1;		
    }
}

#command option for senseval2
if(defined $opt_senseval2)
{
    $inp_sval = $opt_senseval2;
    if(!-e $inp_sval)
    {
	print STDERR "ERROR($0):
		Senseval2 formatted input file $inp_sval does not exist.\n";
	exit 1;
    }

    # check if the file $inp_sval is a Senseval2 formatted file
    open(SVAL, $inp_sval) || die "Error in opening the senseval2 input file $inp_sval. \n";

    # read the complete file in single instruction instead of reading line by line.
    my $temp_delimiter = $/;
    $/ = undef;
    
    my $inp_str = <SVAL>;

    $/ = $temp_delimiter;
    close SVAL;

    if($inp_str !~ m/<corpus/i || $inp_str !~ m/<lexelt/i || $inp_str !~ m/<instance/i || $inp_str !~ m/<context/i)
    {
	print STDERR "ERROR($0):
		File <$inp_sval> is not in Senseval-2 format. \n";

	exit 1;		
    }
}

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
if($#ARGV<1)
{
        &showminimal();
        exit;
}

$cluster_solution=$ARGV[0];

if(!-e $cluster_solution)
{
	print STDERR "ERROR($0):
		Cluster solution file <$cluster_solution> does not exist.\n";
	exit 1;
}
$rlabel=$ARGV[1];

if(!-e $rlabel)
{
	print STDERR "ERROR($0):
		Rlabel file <$rlabel> does not exist.\n";
	exit 1;
}

# check if the rlabel and the cluster_solution files have equal number of lines.
my $csol_lines = `wc $cluster_solution` || die "Error in executing the command \"wc $cluster_solution\"\n";
my $rlabel_lines = `wc $rlabel` || die "Error in executing the command \"wc $rlabel\"\n";

$csol_lines =~ /^\s*(\d+)\s*/;
$csol_lines = $1;

$rlabel_lines =~ /^\s*(\d+)\s*/;
$rlabel_lines = $1;

if($csol_lines != $rlabel_lines)
{
	print STDERR "ERROR($0):
		Number of lines in files <$cluster_solution> and <$rlabel> do not match. 
		File <$cluster_solution> contains $csol_lines lines while <$rlabel> 
		contains $rlabel_lines lines.\n";
	exit 1;	
}

if(defined $inp_context)
{
    open(SCON, $inp_context) || die "Error in opening the senseval2 input file $inp_context. \n";
}

if(defined $inp_sval)
{
    open(SVAL, $inp_sval) || die "Error in opening the senseval2 input file $inp_sval. \n";
}

open(CLSOL,$cluster_solution) || die "Error in opening the cluster solution file <$cluster_solution>\n";
open(RLAB, $rlabel) || die "Error in opening the rlabel file <$rlabel>\n";

while($cluster = <CLSOL>)
{
    chomp($cluster);

    if($cluster !~ /\-?\d\d*/)
    {
	print STDERR "ERROR($0):
		File <$cluster_solution> contains non-numeric values. 
		It should contain only numeric cluster-IDs.\n";
	exit 1;	
    }

    $rlabel = <RLAB>;
    chomp($rlabel);

    #if context option specified, extract the context for each instance
    if(defined $inp_context)
    {
	#read the senseval2 file for instance tag
		do{
			$sentence = <SCON>;
		}until($sentence =~ /instance id=\"(.+?)\" /g || $sentence =~ /instance id=\"(.+?)\">/g);
		$instance_id = $1;
		
		#if the instance tag id matches with the rlabel, which should be.
		if($instance_id eq $rlabel)
		{
			# check if the next tag is answer tag or context tag
			$sentence = <SCON>;

			# if answer tag - discard and continue with the next 
			# tag - context tag
			if($sentence =~ m/<answer/)
			{
				#extract the context data along with the tags
				$context = "";
				#extract the context tag
				$sentence = <SCON>;
				$context = "    " . $sentence . "        ";
			}
			else
			{
				#extracted tag is the context tag
				$context = "    " . $sentence . "        ";
			}

			$sentence = <SCON>;
			while($sentence !~ /\/context/)
			{
				$context .= $sentence;
				$sentence = <SCON>;
			}	        
			$context .=  "      " . $sentence;
			
			#update the hash with instance tag, context tag and data
			$cluster{$cluster}.= "  <instance id=\"$rlabel\">\n  " . $context . "  <\/instance>\n";
		}
    }
    elsif(defined $inp_sval)
    {
		$instance_id = "";
		#read the senseval2 file for instance tag
		do{
			$sentence = <SVAL>;	    
			print $sentence;
		}until($sentence =~ /instance id=\"(.+?)\"/);
		$instance_id = $1;
		
#	}until($sentence =~ /instance id=\"(.+)\" /g || $sentence =~ /instance id=\"(.+)\">/g);
#	}until($sentence =~ /instance id=\"([^\"]+)\"/g);
		
		#if the instance tag id matches with the rlabel, which should be.
		if($instance_id eq $rlabel)
		{
			#modify the answer tag line.
			$sentence = <SVAL>;

			#check if answer tag present, if present add the cluster id 
			#else add add an answer tag with the instance id and cluster id	    
			if($sentence =~ /(<answer.+senseid=\".+?\")/)
			{
				$new_answer = $1 . ' cluster="' .$cluster . '"/>' . "\n";
				print $new_answer;
			}
			else
			{
				$new_answer = "<answer instance=\"$instance_id\" cluster=\"$cluster\"/>\n";
				print $new_answer;
				print $sentence;
			}
			
			#extract the context data along with the tags
			$context = "";
			$sentence = <SVAL>;
			print $sentence;
			$context = "    " . $sentence . "        ";
			
			$sentence = <SVAL>;
			print $sentence;
			while($sentence !~ /\/context/)
			{
				$context .= $sentence;
				$sentence = <SVAL>;
				print $sentence;
			}	    
			$context .=  "      " . $sentence;
		}
    }
    else
    {
		$cluster{$cluster}.= "  <instance id=\"$rlabel\"\/>\n";
    }
}

if(defined $inp_sval)
{
    while($sentence = <SVAL>)
    {
	print $sentence;
    }
}
else
{
	# numerically sort the cluster ids.
    foreach $key (sort {$a+0 <=> $b+0} keys %cluster)
    {
	    print "<cluster id=\"$key\">\n";
	    print "$cluster{$key}<\/cluster>\n";
    }
}

#show minimal usage message
sub showminimal()
{
    print STDERR "Usage: format_clusters.pl [OPTIONS] CLUTO_SOLUTION RLABEL\n";
    print STDERR "TYPE format_clusters.pl --help for help\n";
}

#show help
sub showhelp()
{
        print "Usage:  format_clusters.pl [OPTIONS] CLUTO_SOLUTION RLABEL

Maps Cluto's clustering solution file into Senseval2 input file
to give more legible forms of output.

CLUTO_SOLUTION
	Cluto's clustering solution file.

RLABEL
	Row Label file given to Cluto.

OPTIONS:

--context SENSEVAL2

	SENSEVAL2 is the file in Senseval2 format that has been clustered.
        Displays contexts (actual data) along with the instance tag, 
	grouped by the cluster id. This reorders SENSEVAL2 by cluster id.
        Note: --context and --senseval2 cannot be used together.

--senseval2 SENSEVAL2

	SENSEVAL2 is the file in Senseval2 format that has been clustered.
        Displays the cluster id that has been assigned to the instance 
        by Cluto, in the answer tag. This does not reorder SENSEVAL2.
        Note: --context and --senseval2 cannot be used together.

--help
        Displays this message.

--version
        Displays the version information.\n

Note: For more detailed description type 'perldoc format_clusters.pl' 
      at command prompt.\n";
}

#version information
sub showversion()
{
	print '$Id: format_clusters.pl,v 1.23 2008/03/30 05:06:07 tpederse Exp $';
#	print "\nCopyright (c) 2002-2006, Ted Pedersen, Amruta Purandare, & Anagha Kulkarni\n";
#        print "format_clusters.pl - Version 0.02\n";
        print "\nMap Cluto solution into Senseval-2 data to make output more readable\n"; #	print "Date of Last Update:     09/11/2005\n";
}


