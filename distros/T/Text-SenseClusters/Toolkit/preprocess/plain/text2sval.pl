#!/usr/local/bin/perl -w

=head1 NAME

text2sval.pl - Convert a plain text file with one context per line into Senseval-2 format 

=head1 SYNOPSIS

Create a Senseval-2 format file from a plain text input (where target 
words are marked) and a given key file:

 cat small.txt
 
Output => 

 he played on the offensive <head>line</head> in college
 i think the phone <head>line</head> is down

cat key.txt

Output =>

 <instance id="0"/> <sense id="formation"/>
 <instance id="1"/> <sense id="cable"/>

 text2sval.pl small.txt --lexelt line --key key.txt

Output =>

 <corpus lang="english">
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

Type C<text2sval.pl> for a quick summary of options.

=head1 DESCRIPTION

Converts a plain text instance data file into a Senseval-2 formatted XML 
file. Sense tags, instances ids, and lexelt tags can be inserted into 
the Senseval-2 file. 

=head1 INPUT

=head2 Required Arguments:

=head3 TEXT

Should be a plain text data file containing context of a single instance on each
line. In other words, contexts of different instances should be separated by
a newline character and there should not be any newline characters within the
context of a single instance. For example, the following shows 3 
instances with context of each instance on each line.

 market capitalization draws a <head>line</head> between big and small stocks

 volunteers using a dozen telephone <head>lines</head> at the group's washington headquarters this week will be urging members in alabama arizona

 he proceeded briskly through a reception <head>line</head> of party officials and old friends

=head2 Optional Arguments:

=head4 --lexelt LEX

Specifies the value of the <lexelt> item tag to be used in the output 
Senseval-2 file.

=head4 --key KEYFILE

Displays the instance ids and optional sense tags of the instances in the TEXT
file. These will be used as the values of the <instance> and <sense> tags in 
the output Senseval-2 file.

Each line in KEYFILE should show the instance id and optional sense tags of 
the instance displayed on the corresponding line in the TEXT file, in the 
format :

	<instance id=\"IID\"\/> [<sense id=\"SID\"\/>]*

where an <instance> tag is followed by zero or more <sense> tags.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Given TEXT input file is converted to a Senseval-2 formatted XML file that 
is displayed on stdout.

Sample Outputs 

=over

=item 1 No options specified

Input TEXT file => input.text

 the maiden seated herself upon the golden chair and offered the silver one to her companion they were <head>served</head> by maidens dressed in white whose feet made no sound as they moved about and not a word was spoken during the meal

 why leftover beef should ever be a problem i cannot understand there is nothing better than cold roast sliced paper thin and <head>served</head> with mustard chutney or pickled walnuts these can be found in almost any food specialty shop meat to be served cold should be removed from the refrigerator an hour or so before eating to allow it to return to room temperature

 continue cooking for hours remove the ribs to a hot platter and <head>serve</head> the pan juices separately

 an agency spokesman al heier said it granted the exceptions because these crops are grown by few farmers in small areas that can be closely monitored dinoseb is a herbicide that also <head>serves</head> as a fungicide and an insecticide 

Command => text2sval.pl input.text 

STDOUT will display =>

 <corpus lang="english">
 <lexelt item="LEXELT">
 <instance id="0">
 <answer instance="0" senseid="NOTAG"/>
 <context>
 the maiden seated herself upon the golden chair and offered the silver one to her companion they were <head>served</head> by maidens dressed in white whose feet made no sound as they moved about and not a word was spoken during the meal
 </context>
 </instance>
 <instance id="1">
 <answer instance="1" senseid="NOTAG"/>
 <context>
 why leftover beef should ever be a problem i cannot understand there is nothing better than cold roast sliced paper thin and <head>served</head> with mustard chutney or pickled walnuts these can be found in almost any food specialty shop meat to be served cold should be removed from the refrigerator an hour or so before eating to allow it to return to room temperature
 </context>
 </instance>
 <instance id="2">
 <answer instance="2" senseid="NOTAG"/>
 <context>
 continue cooking for hours remove the ribs to a hot platter and <head>serve</head> the pan juices separately
 </context>
 </instance>
 <instance id="3">
 <answer instance="3" senseid="NOTAG"/>
 <context>
 an agency spokesman al heier said it granted the exceptions because these crops are grown by few farmers in small areas that can be closely monitored dinoseb is a herbicide that also <head>serves</head> as a fungicide and an insecticide
 </context>
 </instance>
 </lexelt>
 </corpus>

Notice that -

1. Since the instance ids are not provided (via --key KEYFILE), text2sval uses 
ordinal numbers 
0,1,2 ... etc as the instance ids for the instances in the same order
i.e. Instance id assigned to instance at position i in the TEXT file is (i-1)

2. Since the sense tags are not provided, all instances are assigned tag 'NOTAG'

3. Since --lexelt is not provided, value of <lexelt> tag shows LEXELT i.e. as
 <lexelt item=\"LEXELT\">

=item 2 --key KEY is provided and KEY shows only the instance ids 

In this case, text2sval uses instance ids from KEY file as the values of 
instance ids in <instance> and <answer> tags while sense ids will have 
values NOTAG

For TEXT file in example (1), 

if the KEY file is => serve.key

 <instance id="serve-v.aphb_34700303_2142"/> 
 <instance id="serve-v.aphb_51903174_3841"/> 
 <instance id="serve-v.aphb_51903399_3856"/> 
 <instance id="serve-v.w7_022806_525"/> 

Command => text2sval.pl --key serve.key --lexelt serve-v input.text

will display on stdout =>

 <corpus lang="english">
 <lexelt item="LEXELT">
 <instance id="serve-v.aphb_34700303_2142">
 <answer instance="serve-v.aphb_34700303_2142" senseid="NOTAG"/>
 <context>
 the maiden seated herself upon the golden chair and offered the silver one to her companion they were <head>served</head> by maidens dressed in white whose feet made no sound as they moved about and not a word was spoken during the meal
 </context>
 </instance>
 <instance id="serve-v.aphb_51903174_3841">
 <answer instance="serve-v.aphb_51903174_3841" senseid="NOTAG"/>
 <context>
 why leftover beef should ever be a problem i cannot understand there is nothing better than cold roast sliced paper thin and <head>served</head> with mustard chutney or pickled walnuts these can be found in almost any food specialty shop meat to be served cold should be removed from the refrigerator an hour or so before eating to allow it to return to room temperature
 </context>
 </instance>
 <instance id="serve-v.aphb_51903399_3856">
 <answer instance="serve-v.aphb_51903399_3856" senseid="NOTAG"/>
 <context>
 continue cooking for hours remove the ribs to a hot platter and <head>serve</head> the pan juices separately
 </context>
 </instance>
 <instance id="serve-v.w7_022806_525">
 <answer instance="serve-v.w7_022806_525" senseid="NOTAG"/>
 <context>
 an agency spokesman al heier said it granted the exceptions because these crops are grown by few farmers in small areas that can be closely monitored dinoseb is a herbicide that also <head>serves</head> as a fungicide and an insecticide
 </context>
 </instance>
 </lexelt>
 </corpus>

Note that the instance ids are taken from the KEY file while sense ids have
NOTAGs.

=item 3 KEY file contains both the instance and sense tags

For TEXT file in example (1), 

if the KEY file is => serve.key

 <instance id="serve-v.aphb_34700303_2142"/> <sense id="SERVE10"/>
 <instance id="serve-v.aphb_51903174_3841"/> <sense id="SERVE10"/>
 <instance id="serve-v.aphb_51903399_3856"/> <sense id="SERVE10"/>
 <instance id="serve-v.w7_022806_525"/> <sense id="SERVE2"/>

Command => text2sval.pl --key serve.key --lexelt serve-v input.text 

will display on STDOUT =>

 <corpus lang="english">
 <lexelt item="LEXELT">
 <instance id="serve-v.aphb_34700303_2142">
 <answer instance="serve-v.aphb_34700303_2142" senseid="SERVE10"/>
 <context>
 the maiden seated herself upon the golden chair and offered the silver one to her companion they were <head>served</head> by maidens dressed in white whose feet made no sound as they moved about and not a word was spoken during the meal
 </context>
 </instance>
 <instance id="serve-v.aphb_51903174_3841">
 <answer instance="serve-v.aphb_51903174_3841" senseid="SERVE10"/>
 <context>
 why leftover beef should ever be a problem i cannot understand there is nothing better than cold roast sliced paper thin and <head>served</head> with mustard chutney or pickled walnuts these can be found in almost any food specialty shop meat to be served cold should be removed from the refrigerator an hour or so before eating to allow it to return to room temperature
 </context>
 </instance>
 <instance id="serve-v.aphb_51903399_3856">
 <answer instance="serve-v.aphb_51903399_3856" senseid="SERVE10"/>
 <context>
 continue cooking for hours remove the ribs to a hot platter and <head>serve</head> the pan juices separately
 </context>
 </instance>
 <instance id="serve-v.w7_022806_525">
 <answer instance="serve-v.w7_022806_525" senseid="SERVE2"/>
 <context>
 an agency spokesman al heier said it granted the exceptions because these crops are grown by few farmers in small areas that can be closely monitored dinoseb is a herbicide that also <head>serves</head> as a fungicide and an insecticide
 </context>
 </instance>
 </lexelt>
 </corpus>

where instance ids and sense tags are both extracted from the KEY file.

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
GetOptions ("help","version","lexelt=s","key=s");
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
        exit;
}

# lexelt item
if(!defined $opt_lexelt)
{
	$opt_lexelt="LEXELT";
}

#			=======================
#			      KEY handling
#			=======================

if(defined $opt_key)
{
	$keyfile=$opt_key;

	if(!-e $keyfile)
	{
		print STDERR "ERROR($0):
        KEY file <$keyfile> doesn't exist.\n";
                exit;
	}
        
	open(KEY,$keyfile) || die "Error($0):
        Error(code=$!) in opening KEY file <$keyfile>.\n";

	$key_num=0;
	#read the keyfile to construct a keytable
	while(<KEY>)
	{
        	$key_num++;
	        chomp;
	        #blank line
        	if(/^\s*$/)
	        {
			print STDERR "ERROR($0):
	Blank line encountered in KEY file <$keyfile> at line <$key_num>.\n";
			exit;
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
        	        $instance_hash{$instance}=1;
			push @instances,$instance;
        	}
		else
        	{
	                print STDERR "ERROR($0):
        Line <$key_num> in the KEY file <$keyfile> should show an <instance>
	tag.\n"; 
        	        exit;
        	}

        	#get the sense tags
	        while(/<sense id=\"([^\"]+)\"\/>/)
        	{
	                $sense=$1;
        	        $_=$';
	                if(defined $key_tab{$instance}{$sense})
        	        {
                	        print "ERROR($0):
        The Instance-Id Sense-Tag pair <$instance , $sense> is repeated in
        the KEY file <$keyfile>.\n";
                        	exit;
	                }
        	        #making an entry for the instance in the keytab
                	$key_tab{$instance}{$sense}=1;
	        }
        	if($_ !~ /^\s*$/)
	        {
        	        print STDERR "ERROR($0):
        Invalid tag found on line <$key_num> in KEY file <$keyfile> after 
        matching <instance> and <sense> tags.\n";
                	exit;
	        }
	}
}
#############################################################################

#                       ================================
#                          INITIALIZATION AND INPUT
#                       ================================

if(!defined $ARGV[0])
{
        print STDERR "ERROR($0):
        Please specify the input TEXT file ...\n";
        exit;
}
#accept the input file name
$infile=$ARGV[0];
if(!-e $infile)
{
        print STDERR "ERROR($0):
        TEXT file <$infile> doesn't exist...\n";
        exit;
}
open(IN,$infile) || die "Error($0):
        Error(code=$!) in opening <$infile> file.\n";

##############################################################################

#			===========================
#			     ACTUAL CONVERSION 
#			===========================

# output is written into a temporary file 
# if program completes without error, 
# this temp file is displayed on stdout
# and is deleted 
# otherwise temp file is preserved 
# and will contain partial program output

$tempfile="tempfile" . time() . ".text2sval";
if(-e $tempfile)
{
	print STDERR "ERROR($0):
	Temporary file <$tempfile> already exists.\n";
	exit;
}

open(TEMP,">$tempfile") || die "ERROR($0):
	Error(code=$!) in opening temporary file <$tempfile>.\n";

print TEMP "<corpus lang=\"english\">\n";
print TEMP "<lexelt item=\"$opt_lexelt\">\n";

$line_num=0;
while(<IN>)
{
	$line_num++;
        # trimming extra spaces
        chomp;
	# handling blank lines
        if(/^\s*$/)
        {
		print STDERR "ERROR($0):
	Blank line encountered at line <$line_num> in TEXT file <$infile>.\n";
		exit;
        }
	$data=$_;
	if(defined $keyfile)
	{
		if(defined $instances[$line_num-1])
		{
			$instance=$instances[$line_num-1];
		}
		else
		{
			print STDERR "ERROR($0):
	No instance id found at line <$line_num> in KEY file <$keyfile>.\n";
			exit;
		}
	}
	# use the ordinal position of instance as the instance id
	else
	{
		$instance=$line_num-1;
	}
	print TEMP "<instance id=\"$instance\">\n";
	if(defined $keyfile)
	{
		if(defined $key_tab{$instance})
		{
			foreach $sense (sort keys %{$key_tab{$instance}})
			{
				print TEMP "<answer instance=\"$instance\" senseid=\"$sense\"\/>\n";
			}
		}
		else
		{
			print TEMP "<answer instance=\"$instance\" senseid=\"NOTAG\"\/>\n";
		}
	}
	else
	{
		print TEMP "<answer instance=\"$instance\" senseid=\"NOTAG\"\/>\n";
	}
	print TEMP "<context>\n";
	print TEMP "$data\n";
	print TEMP "<\/context>\n";
	print TEMP "<\/instance>\n";
}

print TEMP "<\/lexelt>\n";
print TEMP "<\/corpus>\n";

if(defined $keyfile)
{
	if(scalar(@instances) != $line_num)
	{
		print STDERR "ERROR($0):
	Number of entries in the KEY file <" . scalar(@instances). "> do not match the number of instances <$line_num> in the TEXT file.\n";
		exit;
	}	
}

# --------------
# printing TEMP 
# --------------
close TEMP;
open(TEMP,$tempfile) || die "ERROR($0):
        Error(code=$!) in opening temporary file <$tempfile>.\n";

while(<TEMP>)
{
	print;
}
close TEMP;
unlink "$tempfile";

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: text2sval.pl [OPTIONS] TEXT";
        print "\nTYPE text2sval.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  text2sval.pl [OPTIONS] TEXT

Converts a plain TEXT instance file into the Senseval-2 formatted XML file.

TEXT
	Plain TEXT instance file showing context of each instance of a target 
	word on a separate line.

OPTIONS:

--lexelt LEX
	Specifies the value of the <lexelt> tag to be used in the Senseval-2 
	file. Default is LEXELT.

--key KEY
	Specifies instance ids and optional sense tags of the instances in the 
	TEXT file. 
	Each line in KEY file should show the instance id followed by zero or 
	more sense tags of the instance on the corresponding line in the TEXT 
	file, in the format - 
		<instance id=\"IID\"\/> [<sense id=\"SID\"\/>]*

--help
        Displays this message.

--version
        Displays the version information.

Type 'perldoc text2sval.pl' to view detailed documentation of text2sval.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
#        print "text2sval.pl      -       Version 0.01\n";
	print '$Id: text2sval.pl,v 1.9 2008/03/29 23:37:25 tpederse Exp $';
        print "\nConverts a plain text file into a Senseval-2 formatted XML file.\n";
#        print "Copyright (c) 2002-2005, Amruta Purandare & Ted Pedersen.\n";
#        print "Date of Last Update:     12/02/2003\n";
}

#############################################################################

