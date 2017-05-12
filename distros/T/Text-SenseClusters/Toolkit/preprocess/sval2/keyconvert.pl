#!/usr/local/bin/perl -w

=head1 NAME

keyconvert.pl - Convert Senseval-2 answer key to Senseclusters format

=head1 SYNOPSIS

 keyconvert.pl [OPTIONS] INPUTFILE OUTFILE

=head1 DESCRIPTION

Converts the Senseval formatted input key file to SenseClusters' formatted
output key file required by the SenseClusters package.

=head2 Required Arguments:

=head3 INPUTFILE

The Senseval key file. The format for Senseval key file is: 

 TARGET_WORD 	INSTANCE_ID	SENSE_ID+ 

on each line showing one or more SENSE_IDs for an INSTANCE_ID.

=head3 OUTFILE

The file name which would have the resultant SenseClusters' formatted 
key file. The SenseClusters' format id:

 <instance id=\"I\"\/>	<sense id=\"S\"\/>+ 

on each line where Sense Tags S are attached to an Instance I.

=head2 Optional Arguments:

=head4 --attach_P

This will attach Sense tag P to the Sense Tag that follow it. Otherwise
the P tags are removed. 

=head4 --help

Displays the quick summary of program options.

=head4 --version

Displays the version information.

=head1 AUTHORS

 Amruta Purandare, University of Pittsburgh

 Ted Pedersen, University of Minnesota, Duluth
 tpederse @ d.umn.edu

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
#
#       PROGRAM NAME-  keyconvert.pl (A Component of SenseClusters Package)
#
#############################################################################

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
GetOptions ("help","version","attach_P");
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
        Please specify the Senseval KEY file name...\n";
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

if(!defined $ARGV[1])
{
        print STDERR "ERROR($0):
        Please specify the Output KEY file name...\n";
        exit;
}

#accept the output file name
$outfile=$ARGV[1];
if(-e $outfile)
{
        print STDERR "Warning($0):
        Output file <$outfile> already exists, overwrite (y/n)? ";
	$ans=<STDIN>;
	if(!($ans=~/y|Y/))
	{
		exit;	
	}
}
open(OUT,">$outfile") || die "Error($0):
        Error(code=$!) in opening OUTPUT KEY file <$outfile>.\n";

##############################################################################

$line_num=0;
while($line=<IN>)
{
	$line_num++;
        # trimming extra spaces
        chomp $line;
        $line=~s/\s+$//g;
        $line=~s/^\s+//g;
        $line=~s/\s+/ /g;
	# handling blank lines
        if($line=~/^\s*$/)
        {
                next;
        }
	($word,$instance_id,@senses)=split(/\s+/,$line);
	undef $word;
	if(!defined $instance_id)
	{
		print STDERR "ERROR($0):
	Line <$line_num> in SOURCE KEY file <$infile> doesn't contain an
	Instance-Id.\n";
		exit;
	}
	if(defined %{$instance_sense{$instance_id}})
	{
		print "ERROR($0):
	Instance-Id <$instance_id> occurs more than once in the SOURCE KEY 
	file <$infile>.\n";
		exit;
	}
	if(!($#senses>=0))
        {
                print STDERR "ERROR($0):
        Line <$line_num> in SOURCE KEY file <$infile> doesn't contain valid
        Sense Tags.\n";
                exit;
        }
	$ptag=0;
	foreach $sense (@senses)
	{
		if($ptag==1)
		{
			if(defined $opt_attach_P)
			{
				$sense="P_".$sense;
				$ptag=0;
			}
			$ptag=0;
		}
		if($sense eq "P")
		{
			$ptag=1;
		}
		if($ptag!=1)
		{
			$instance_sense{$instance_id}{$sense}++;
		}
	}
}

undef $opt_attach_P;
#----------------------
#Write into a KEY file 
#----------------------
foreach $instance (sort keys %instance_sense)
{
	print OUT "<instance id=\"$instance\"\/> ";
	foreach $sense (sort keys %{$instance_sense{$instance}})
	{
		print OUT "<sense id=\"$sense\"\/> ";
	}
	print OUT "\n";
}

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
        print "Usage: keyconvert.pl [OPTIONS] SOURCE DESTINATION";
        print "\nTYPE keyconvert.pl --help for help\n";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage:  keyconvert.pl [OPTIONS] SOURCE DESTINATION
Converts a SOURCE KEY file from Senseval format to DESTINATION KEY file 
in SenseCluster's format.

SOURCE 
	Specify the Senseval KEY file name. SOURCE should follow the standard
	Senseval keyfile format with 
	TARGET_WORD 	INSTANCE_ID	SENSE_ID+ 
	on each line showing one or more SENSE_IDs for an INSTANCE_ID.

DESTINATION 
	Specify the DESTINATION KEY file name where program can print the 
	equivalent KEY file in SenseClusters Format showing
	<instance id=\"I\"\/>	<sense id=\"S\"\/>+ 
	on each line where Sense Tags S are attached to an Instance I.

OPTIONS:
--attach_P
	This will attach Sense tag P to the Sense Tag that follow it. Otherwise
	the P tags are removed. 
--help
        To display this message.
--version
        To display the version information.\n";
}

#------------------------------------------------------------------------------
#version information
sub showversion()
{
#        print "keyconvert.pl      -       Version 0.03";
	print '$Id: keyconvert.pl,v 1.12 2013/06/25 14:58:11 tpederse Exp $';
        print "\nConverts Senseval-2 KEY file into SenseCluster's KEY file\n";
#        print "\nCopyright (C) 2002, Ted Pedersen and Amruta Purandare.\n";
#        print "Date of Last Update:     03/17/2003\n";
}

#############################################################################

