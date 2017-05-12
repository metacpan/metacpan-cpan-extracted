#!/usr/local/bin/perl -w

=head1 NAME

prepare_sval2.pl - Makes sure Senseval-2 data is cleaned and has sense 
tags prior to invocation of SenseClusters

=head1 SYNOPSIS

 prepare_sval2.pl [Options] SOURCE

Here is a Senseval-2 file that is untagged

 cat notags.txt

Output => 

 <corpus lang="english">
 <lexelt item="line">
 <instance id="0">
 <context>
 he played on the offensive <head>line</head> in college
 </context>
 </instance>
 <instance id="1">
 <context>
 i think the phone <head>line</head> is down
 </context>
 </instance>
 </lexelt>
 </corpus>

Here is a key file that contains sense tags for these instances:

 cat key.txt

Output =>

 <instance id="0"/> <sense id="formation"/>
 <instance id="1"/> <sense id="cable"/>

Now we can apply the tags in the key file to the previously untagged 
instances:

 prepare_sval2.pl notags.txt --key key.txt

Output =>

 <corpus lang="english" tagged="NO">
 <lexelt item="line">
 <instance id="0">
 <answer instance="0" senseid="formation"/>
 <context>
 he played on the offensive <head>line</head> in college
 </context>
 </instance>
 <instance id="1">
 <answer instance="1" senseid="cable"/>
 <context>
 i think the phone <head>line</head> is down
 </context>
 </instance>
 </lexelt>
 </corpus>

Type C<prepare_sval2.pl --help> for quick summary of options

=head1 DESCRIPTION

This program prepares Senseval-2 Data for SenseClusters experiments by 
making sure that all instances have sense tags. Sense tags can be 
applied from a separate key file, and if any instances do not have 
tags, then a NOTAG is inserted. This program also deals with P tags 
that may exist in some Senseval data. The P tag indicates that the 
target word is a proper noun. In may cases P tagged instances are 
ommited from experiments since they are a different kind of sense. If 
"bush" were the target word, some instances might refer to "George 
Bush", which may not be one of the senses we wish to evaluate. Finally, 
this program can also deal with satellite tags that exist in some 
Senseval data. When the target word is a verb, in some cases it may have 
a satellite (particle), that we may or may not want to consider as a 
part of the target word. The satellite tags have identifiers in them 
that may cause parsing trouble, so they are often removed.

=head1 INPUT

=head2 Required Arguments:

=head4 SOURCE 

A Senseval-2 formatted Data file that is to be prepared for the SenseClusters 
experiments.

=head2 Optional Arguments:

=head4 --key KEY

Sense Tagging mechanism in prepare_sval2.pl - 

prepare_sval2.pl makes sure that all SOURCE instances are tagged with some 
answer tags (or NOTAGs at least). 

If the sense tags are found in the same SOURCE file, these will 
be retained, however if the SOURCE instances are not tagged, instances will be 
either attached "NOTAG"s or will be attached the sense tags given in the 
separate KEY file.

A KEY file that has true answer keys of the SOURCE instances can be provided 
via --key option. If the SOURCE instances are not sense tagged, they will be 
tagged with the sense tags as given in the KEY file. 

KEY file should be in SenseClusters format showing

		<instance id="I"/>  [<sense id="S"/>]+

on each line where an instance id is followed by its true sense ids on a single line.

prepare_sval2 takes into account following anamolies in SOURCE/KEY - 

=over 4

=item 1.

If the 1st SOURCE instance is sense tagged, it assumes that SOURCE is sense 
tagged and will disable the KEY file option. If some of the SOURCE instances 
are not tagged, regardless of whether they have keys in KEY file or not, 
these are given "NOTAG"s.

=item 2. 

If the 1st SOURCE instance is not sense tagged, it assumes that SOURCE is 
untagged and will give an error if any SOURCE instance is found sense tagged 
in the SOURCE file.

=item 3. 

If the 1st SOURCE instance is not sense tagged and has an entry in the KEY 
file, it will enable the KEY file and will attach the instances with their 
answer keys as given in the KEY file. Any instance that doesn't have an answer 
key in the KEY file is attached "NOTAG".

=item 4. 

If the 1st SOURCE instance is not sense tagged and doesn't have an entry in 
the KEY file, KEY file will be disabled and no instance will be attached a tag 
from the KEY file. All instances are given "NOTAG"s.

=back

=head4 --attachP

P tag handling mechanism in prepare_sval2.pl -

prepare_sval2.pl by default removes the sense tags that have value P. 
According to Senseval-2 standard, these are not true sense tags but indicate 
that the target word is a proper noun. 

--attachP option will attach a P tag to an immediately following sense tag for
the same instance. 

e.g. If --attachP is selected,  

 <instance id="art.40012" docsrc="bnc_A0E_130">
 <answer instance="art.40012" senseid="P"/>
 <answer instance="art.40012" senseid="arts%1:09:00::"/>

will be modified to 

 <instance id="art.40012" docsrc="bnc_A0E_130">
 <answer instance="art.40012" senseid="P_arts%1:09:00::"/>

and if --attachP is not selected, by default P tag will be removed as

 <instance id="art.40012" docsrc="bnc_A0E_130">
 <answer instance="art.40012" senseid="arts%1:09:00::"/>
 

=head4 --modifysat

This switch if selected will remove the satellite tag ids from <head sats="
ID"/> and <sat id="ID"/> tags, retaining basic <head> and <sat> tag 
information.

e.g. by selecting --modifysat,

 Perhaps he 'd have <head sats="call_for.018:0">called</head> <sat
 id="call_for.018:0">for</sat> a decentralized political and economic
 system

will be transformed to 

 perhaps he 'd have <head> called </head> <sat> for </sat> a 
 decentralized political and economic system

By not selecting --modifysat, the satellite ids would be retained.

=head4 --nolc 

prepare_sval2 converts everything to lowercase by default. Select 
this switch to not do any case conversion.

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Output will be a Senseval-2 file displayed to stdout. 

=head1 AUTHORS

 Amruta Purandare, University of Pittsburgh

 Ted Pedersen, University of Minnesota, Duluth
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

#############################################################################

#                               THE CODE STARTS HERE

use utf8;

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
GetOptions ("help","version","attachP","modifysat","key=s","nolc");
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
        Please specify the Senseval-2 Data file name...\n";
        exit;
}
#accept the input file name
$infile=$ARGV[0];
if(!-e $infile)
{
        print STDERR "ERROR($0):
        Source file <$infile> doesn't exist...\n";
        exit;
}
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening <$infile> file.\n";

##############################################################################

#			===========================
#			     KEY file handling
#			===========================

# if the sense tags of the instances in Source file 
# are provided in KEY file, we attach them to source 
# instances
if(defined $opt_key)
{
        $keyfile=$opt_key;

        if(!-e $keyfile)
        {
                print STDERR "ERROR($0):
        KEY File <$keyfile> doesn't exist.\n";
                exit;
        }

        open(KEY,$keyfile) || die "Error($0):
        Error(code=$!) in opening file <$keyfile>.\n";
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
                        next;
                }
		#get the instance id from the key file
                if(/<instance id=\"([^\"]+)\"\/>/)
                {
                        $instance=$1;
                        $_=$';
                        if(defined $instance_hash{$instance})
                        {
                                print STDERR "ERROR($0):
        Instance-Id <$instance> is repeated in the KEY file <$keyfile>.\n";
                                exit;
                        }
                        $instance_hash{$instance}++;
                }
                else
                {
                        print STDERR "ERROR($0):
        Line <$line_num> in the KEY file <$keyfile> doesn't contain any
        <instance> tag.\n";
                        exit;
                }
		# get sense ids now
                while(/<sense id=\"([^\"]+)\"\/>/)
                {
                        $sense=$1;
                        $_=$';
                        if(defined $key_tab{$instance}{$sense})
                        {
                                print "ERROR($0):
        The Instance-Id Sense-Tag pair <$instance $sense> is repeated in
        the KEY file <$keyfile>.\n";
                                exit;
                        }
                        # making an entry for the instance in the keytab
                        $key_tab{$instance}{$sense}=1;
                }
                # checking if this instance has atleast one sense tag
                if(!defined $key_tab{$instance})
                {
                        print STDERR "ERROR($0):
        No Sense Id found at line <$line_num> in KEY file <$keyfile>.\n";
                        exit;
                }
        }
}

##############################################################################

#---------------------
#creating a TEMP file
#---------------------
#we hold the output in tempfile till the program terminates
#without an error. In case of error, the tempfile would be
#retained and will hold partial output of the program.

#use the system_defined date for unique name for tempfile

#$date_time=scalar localtime;
#@time_elements=split(/\s+/,$date_time);
#$tempfile=join "_",@time_elements;
$tempfile="temp".time().".prepare_sval2";
open(TEMP,">$tempfile")||die"ERROR($0):
Internal System Error(code=$!).\n";

##############################################################################

# tag_flag=0 if data is untagged
# =1 if tagged
undef $tag_flag;
undef $data_start;
$line_num=0;
# if tag=1, sense tags must be found for all instances
$tag_found=0;
while(<IN>)
{
	$line_num++;
	# KEY handling
	if(/instance id=\"([^\"]+)\"/)
	{
		$instance=$1;
		# we access key table only if data in untagged
		# otherwise key entries are ignored
		if(!defined $tag_flag || $tag_flag==0)
		{
			if(defined $key_tab{$instance})
			{
				# attach_key = 1 
				# only if all instances have tags in KEY
				# =0 otherwise 
				if(!defined $attach_key)
				{
					$attach_key=1;
				}
				foreach $sense (keys %{$key_tab{$instance}})
				{
					$instance_sense{$instance}{$sense}=1;
				}
			}
			else
			{
				if(!defined $attach_key)
				{
					$attach_key=0;
				}
			}
		}
	}
	if(/sense\s*id=\"([^\"]+)\"/)
	{
		if(!defined $tag_flag)
		{
			$tag_flag=1;
		}
		# error if sense id is not expected
		elsif($tag_flag==0)
		{
			print STDERR "ERROR($0):
	No Sense Id is expected in Source file <$infile> for instance 
	<$instance> as all earlier instances are untagged.\n";
			exit;
		}
		if($1 ne "P")
		{
			$tag_found=1;
		}
	}
	if(defined $data_start && !defined $opt_nolc)
	{
	    tr/A-Z/a-z/;
	}
	if(/<context>/)
	{
		$data_start=1;
		if(!defined $tag_flag)
                {
                        $tag_flag=0;
                }
		# putting no tag if some instances aren't tagged
                elsif($tag_flag==1 && $tag_found==0)
                {
			print TEMP "<answer instance=\"$instance\" senseid=\"NOTAG\"\/>\n";
                }
                $tag_found=0;
	}
	if(/<\/context>/)
	{
		undef $data_start;
		undef $ptag;
	}
	if(defined $ptag && ($_ !~ /senseid=\"[^\"]+\"/))
	{
		print STDERR "ERROR($0):
	P tag is not followed by any Sense tag at line<$line_num> in Senseval-2
	file <$infile>\n.";
		exit;
	}
	# by default remove P tag
	if((!defined $opt_attachP) && /senseid=\"P\"/)
	{
		next;
	}
	# if --attachP defined attach P tag
	if(defined $opt_attachP && /senseid=\"P\"/)
	{
		$ptag=1;
		next;
	}
	if(defined $ptag && /senseid=\"([^\"]+)\"/)
	{
		$sense="P_".$1;
		s/sense\s*id=\"$1\"/senseid=\"$sense\"/;
		undef $ptag;
	}
	# if --modifysat used, remove sat ids from sat and head tags
	if(defined $opt_modifysat && /<head sats=\"[^\"]+\">/)
	{
		s/<head sats=\"[^\"]+\">/<head>/g;
	}
	if(defined $opt_modifysat && /<sat id=\"[^\"]+\">/)
	{
		s/<sat id=\"[^\"]+\">/<sat>/g;
	}
	print TEMP $_;
}

undef $opt_attachP;
undef $opt_modifysat;
undef $opt_nolc;

#now display to STDOUT
close TEMP;
open(TEMP,$tempfile) || die "ERROR($0):
        Internal System Error(code=$!).\n";
# read temp file and display with extra information
while(<TEMP>) 
{
	if(/<corpus\s*(.*)>/)
	{
		if($tag_flag==0)
		{
			print "<corpus $1 tagged=\"NO\">\n";
		}
		elsif($tag_flag==1)
		{
			print "<corpus $1 tagged=\"YES\">\n";
		}
		else
		{
			print STDERR "ERROR($0):
	Error in Processing Data <$infile>.\n";
			exit;
		}
	}
	elsif(/instance id=\"([^\"]+)\"/)
	{
		print;
		$instance=$1;
		# data untagged - either attach tag from KEY or put NOTAG
		if($tag_flag==0)
		{
			# get tag from the KEY file
			if(defined $attach_key && $attach_key==1)
			{
				if(defined $instance_sense{$instance})
				{
					foreach $sense (keys %{$instance_sense{$instance}})
					{
						if($sense ne "P")
						{
							print "<answer instance=\"$instance\" senseid=\"$sense\"\/>\n";
						}
					}
				}
				else
				{
					print "<answer instance=\"$instance\" senseid=\"NOTAG\"\/>\n";
				}
			}
			# put tag as NOTAG
			else
			{
				print "<answer instance=\"$instance\" senseid=\"NOTAG\"\/>\n";
			}
		}
	}
	else
	{
		print;
	}	
}
#remove the tempfile
unlink "$tempfile";

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: prepare_sval2.pl [OPTIONS] SOURCE";
        print "\nTYPE prepare_sval2.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  prepare_sval2.pl [OPTIONS] SOURCE 

Prepares Senseval-2 Data by converting context data to lower case and some 
other preprocessing tasks like attaching sense tags, handling P tags and Sat 
tags. The modified file is displayed to stdout. 

Required Parameters -
SOURCE 
	Specify Senseval-2 Data file. 

Optional Parameters:
--key KEY
	Tags SOURCE instances with their correct answer tags if these are 
	provided in a KEY file. The format of a KEY file should show
                <instance id=\"I\"\/>  [<sense id=\"S\"\/>]+
        where an Instance-Id is followed by its true sense tag/s on each line.

--attachP 
	Attaches P tags to the Sense Tags immediately following them. By 
	default, P tags are removed since they indicate proper nouns. 
	Note: attachP doesn't work when answer tags are provided in KEY file.
	But an option --attachP is provided in keyconvert.pl program that 
	attaches P tags while converting format of KEY file to SenseClusters 
	format.

--modifysat
	Modifies satellite and head tags containing satellite ids like 
	<head sats> or <sat id>, by replacing them with markers <head> and 
	<sat>.

--nolc 
	prepare_sval2.pl converts all characters to lowercase by default. 
	Select --nolc switch not to do any case conversion.
 
--help
        To display this message.

--version
        To display the version information.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
#        print "prepare_sval2.pl - Version 0.19\n";
	print '$id$';
        print "\nEnsure Senseval-2 data is sense tagged and cleaned\n";
#        print "\nCopyright (c) 2002-2005, Amruta Purandare, Ted Pedersen.\n";
#        print "Date of Last Update: 07/18/2003\n";
}

#############################################################################

