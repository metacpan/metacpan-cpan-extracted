#!/usr/local/bin/perl -w

=head1 NAME 

setup.pl - Preprocess Senseval-2 data for sample experiments

=head1 SYNOPSIS 

A Perl script that preprocesses and prepares DATA for experiments with SenseClusters. 

=head1 USAGE 

setup.pl [Options] DATA 

Type 'setup.pl --help' for quick summary of options

=head1 INPUT

=head2 Required Arguments:

=head3 DATA

SenseClusters requires input DATA in Senseval-2 format. DATA in any other 
format has to be first converted to this format. We provide with this 
distribution a pre-processing program Toolkit/preprocess/plain/text2sval.pl 
that converts  data in plain text format (with the context of single 
instance on each line) into Senseval-2 format.

SenseClusters uses an unsupervised clustering approach and hence doesn't 
require DATA to be sense tagged at all. However, if the true sense classes
of the DATA instances are available, those could be used for evaluation.

=head2 Optional Arguments:

=head3 Data Options (--training | --split)? 

Data Options specify the input DATA to setup.pl. There are three different 
possibilities, which can be denoted via the following regex:

C<setup.pl DATA (--training TRAIN or --split P)?>

1. If neither --training nor --split options are used, DATA will be clustered 
using the features extracted from the same DATA file.

2. If a separate Training file is provided via --training TRAIN option, 
DATA will be clustered using features extracted from the given TRAIN file.
TRAIN file is expected to be in the Senseval-2 format.

3. If DATA file is provided with the --split P option, (100-P)% of DATA will be 
clustered using features extracted from the rest P% DATA.

Thus, DATA can be provided in a single DATA file, or with the --split P option
or with a separate training file via --training TRAIN option. Options --split 
and --training can't be both used together.

=head3 Sense Tag Options :

If the correct answer tags of the DATA instances are known, these can be used 
for performing some special tasks like evaluating results or filtering low 
frequency senses.

=head4 --key KEY

Specifies the true sense tags of the DATA instances.

Each line in the KEY file should show 

   <instance id=\"I\"\/>  [<sense id=\"S\"\/>]+

where an Instance-Id is followed by its true sense tag/s. 

KEY file in any other format has to be first converted to this format. We 
provide with this distribution a script called keyconvert.pl (in
Toolkit/preprocess/sval2) to convert a KEY file in Senseval-2 format (such as
fine.key) to SenseClusters' KEY format.

If the KEY file is not specified and if any sense-tag options like evaluation
or sense-filter are used in wrapper discriminate.pl, SenseClusters assumes 
that the sense ids are embedded in the same DATA file and these will be 
searched by matching an expression

                /sense\s*id=\"SID\"/

assuming that SID shows a true sense id of an immediately preceding 
instance ID matched by /instance id=\"ID\"/ expression.

=head3 Tokenization Options :

=head4 --token TOKENFILE

TOKENFILE is a file of Perl regexes that define tokenization scheme in DATA. 
A sample regex file, token.regex is provided with this distribution and if the
user doesn't specify the TOKENFILE via --token option, token.regex will be 
searched in the current directory. 

=head4 --nontoken NONTOKENFILE

NONTOKENFILE is a file of Perl regexes that define strings that will be removed
prior to tokenization. If NONTOKENFILE is not specified, only those string 
sequences that are not tokens will be removed. 

=head3 Other Options :

=head4 --verbose

Displays to STDERR the current program status. Silent by default.

=head4 --showargs

Displays to STDOUT values of required and option arguments.

=head4 --help

Displays this message.

=head4 --version

Displays the version information.
	
=head1 OUTPUT

setup.pl preprocesses given DATA in following ways -

=over 4

=item 1.

Creates a LexSample directory that contains a separate directory for each 
<lexelt> found in the DATA file. Each LEXELT directory (found within LexSample) 
will have following files -

=over 8

=item * LEXELT-test.xml 

A test XML file containing instances of single 'LEXELT' from a given DATA file.
If --split P is specified, LEXELT-test.xml will have (1-P)% of the instances 
in DATA with the value of <lexelt> tag as LEXELT.
Otherwise, will have all DATA instances that come under the LEXELT item.

=item * LEXELT-test.count

A count file containing instance data within <context> and </context> tags on 
a single line for each instance appearing in corresponding LEXELT-test.xml.


=item * [LEXELT-training.xml]

This file is created only if --training or --split options are used. 
If --split P is used, this will contain P% of the DATA instances having 
<lexelt> tag value = LEXELT. Otherwise, this file will have all instances 
from TRAINING that come under the LEXELT tag.

=item *	[LEXELT-training.count]

This is created only if its equivalent LEXELT-training.xml is created and  
contains instance data within <context> </context> tags on a single line for 
each instance appearing in LEXELT-training.xml.

=back

Additionally, LexSample directory will have files token.regex and 
nontoken.regex if --nontoken option is used.

=item 2. 

Converts data within <context> and </context> tags to lowercase. 

=item 3.

If KEY file is specified via --key option, answer tags are put along with the 
instances in the corresponding LEXELT files. These will be accessed only 
during the sense tag options like evaluation or filtering low frequency senses.
Sense tags are ignored during clustering and feature selection. The inclusion
of sense tags in the same XML files is only meant for sake of convenience for
programming.

=back

=head1 SYSTEM REQUIREMENTS

setup.pl uses a preprocessing program L<preprocess.pl> which is included 
in SenseClusters

=head1 SEE ALSO

L<discriminate.pl> uses the training and test files created by setup.pl

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
###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================

# command line options
use Getopt::Long;
GetOptions ("help","version","showargs","verbose","training=s","split=f","token=s","nontoken=s","key=s");

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
# show minimal usage message if required arguments not specified
if($#ARGV<0)
{
        &showminimal();
        exit;
}

###############################################################################

#			============================
#			    Initialization Section
#			============================

# $0 contains the program name along with the complete path. 
# Extract just the program name and use in error messages

$0=~s/.*\/(.+)/$1/;

if(!defined $ARGV[0])
{
	print STDERR "ERROR($0): 
	Specify a Senseval-2 formatted DATA file.\n";
	exit;
}
$datafile=$ARGV[0];

if(defined $opt_training && defined $opt_split)
{
	print STDERR "ERROR($0):
	--split and --training can't be used together. Can't split DATA into 
	Training and Test parts when a training file is already given.\n";
	exit;
}

if(defined $opt_training)
{
	$trainfile=$opt_training;
}

if(defined $trainfile && $datafile eq $trainfile)
{
	print STDERR "ERROR($0):
	Training file <$trainfile> and DATA file <$datafile> are same.\n";
	exit;
}
# if token file not specified, use our token.regex 
if(!defined $opt_token)
{
	$opt_token="token.regex";
}

# if --showargs is selected show command line argument values 
if(defined $opt_showargs)
{
	print "DATA: $datafile\n";
	if(defined $opt_training)
	{
               print "--training=$trainfile\n";
	}
	print "--token=$opt_token\n";
        if(defined $opt_nontoken)
        {
                print "--nontoken=$opt_nontoken\n";
        }
	if(defined $opt_split)
	{
		print "--split=$opt_split\n";
	}
	if(defined $opt_key)
	{
		print "--key=$opt_key\n";
	}
	if(defined $opt_showargs)
	{
		print "--showargs=ON\n";
	}
}
###############################################################################

#			==========================
# 			   Preprocessing Section
#			==========================

if(! -e $datafile)
{
	print STDERR "ERROR($0):
	Specified DATA file <$datafile> doesn't exist.\n";
	exit;
}
if(defined $trainfile && !-e $trainfile)
{
	print STDERR "ERROR($0):
	Specified Training file <$trainfile> doesn't exist.\n";
	exit;
}
if(! -e $opt_token)
{
	print STDERR "ERROR($0):
	Token file <$opt_token> doesn't exist.\n";
	exit;
}
if(defined $opt_nontoken && !-e $opt_nontoken)
{
	print STDERR "ERROR($0):
	Specified NonToken file <$opt_nontoken> doesn't exist.\n";
	exit;
}
# -------------
# prepare_sval2 
# -------------
	if(defined $opt_verbose)
	{
		print STDERR "Preprocessing $datafile ...\n";
	}
	if(defined $opt_key)
	{
		system("prepare_sval2.pl --key $opt_key --modifysat $datafile > $datafile.proc");
	}
	else
	{
		system("prepare_sval2.pl --modifysat $datafile > $datafile.proc");

	}

	if(defined $trainfile)
	{
		if(defined $opt_key)
		{
			system("prepare_sval2.pl --key $opt_key --modifysat $trainfile > $trainfile.proc");
		}
		else
		{
			system("prepare_sval2.pl --modifysat $trainfile > $trainfile.proc");
		}
	}
	
# --------------
# preprocess.pl
# --------------
		$lexdir="LexSample";
                if(-e $lexdir)
                {
                        print STDERR "ERROR($0):
		        Directory $lexdir already exists. Aborting ...\n";
                        exit;
                }
                mkdir $lexdir;
		system("cp $opt_token $lexdir/token.regex");
		if(defined $opt_nontoken)
		{
			system("cp $opt_nontoken $lexdir/nontoken.regex");
		}
	# preprocessing with --split ON
	if(defined $opt_split)
	{
		system("mv $datafile.proc $lexdir/$datafile");
		chdir $lexdir;
		if(-e "nontoken.regex")
		{
			if(defined $opt_verbose)
			{
				system("preprocess.pl --verbose --split $opt_split --token token.regex --removeNotToken --nontoken nontoken.regex $datafile");
			}
			else
			{
				system("preprocess.pl --split $opt_split --token token.regex --removeNotToken --nontoken nontoken.regex $datafile");
			}
		}
		else
		{
			if(defined $opt_verbose)
			{
				system("preprocess.pl --verbose --split $opt_split --removeNotToken --token token.regex $datafile");
			}
			else
			{
				system("preprocess.pl --split $opt_split --removeNotToken --token token.regex $datafile");
			}
		}
		system("mkdir train-lexelts");
		system("mkdir test-lexelts");

		system("/bin/rm -f $datafile");
		system("mv *-training.* train-lexelts/");
		system("mv *-test.* test-lexelts/");
		chdir "../";
	}
	else
	{	
		# preprocessing training file
		if(defined $trainfile && -e $trainfile)
		{
			system("mv $trainfile.proc $lexdir/$trainfile");
			chdir $lexdir;
			if(-e "nontoken.regex")
	                {
				if(defined $opt_verbose)
				{
        	                	system("preprocess.pl --verbose --token token.regex --removeNotToken --nontoken nontoken.regex $trainfile");
				}
				else
				{
					system("preprocess.pl --token token.regex --removeNotToken --nontoken nontoken.regex $trainfile");
				}
                	}
	                else
        	        {
				if(defined $opt_verbose)
				{
                	        	system("preprocess.pl --verbose --removeNotToken --token token.regex $trainfile");
				}
				else
				{
					system("preprocess.pl --removeNotToken --token token.regex $trainfile");
				}
	                }

        	        # gathering separate lexelt files created by 
			# preprocess.pl in dir train-lexelts

			system("/bin/rm -f $trainfile");
	                system("mkdir train-lexelts");
        	        system("mv *.count train-lexelts/");
                	system("mv *.xml train-lexelts/");
			chdir "../";
		}
		system("mv $datafile.proc $lexdir/$datafile");
		chdir $lexdir;
		# preprocessing DATA file
		if(-e "nontoken.regex")
                {
			if(defined $opt_verbose)
			{
	                       	system("preprocess.pl --verbose --token token.regex --removeNotToken --nontoken nontoken.regex $datafile");
			}
			else
			{
				system("preprocess.pl --token token.regex --removeNotToken --nontoken nontoken.regex $datafile");
			}
                }
                else
                {
			if(defined $opt_verbose)
			{
                       		system("preprocess.pl --verbose --removeNotToken --token token.regex $datafile");
			}
			else	
			{
				system("preprocess.pl --removeNotToken --token token.regex $datafile");
			}
                }
                # gathering separate lexelt files created by preprocess.pl
                # in dir test-lexelts

                system("mkdir test-lexelts");
		system("/bin/rm -f $datafile");
                system("mv *.count test-lexelts/");
	        system("mv *.xml test-lexelts/");

		chdir "../";
	}
	# -----------------------------------------------------------
	# After preprocessing, there will be a test-lexelt dir 
	# and an optional train-lexelt dir containing separate
	# XML/count files of each lexelt element
	# -----------------------------------------------------------	

if(defined $opt_verbose)
{
	print STDERR "Preprocessing complete ...\nCreating LexSample...\n";
}
# --------------------------------------
# Setting up directories for experiment
# --------------------------------------
system("setdirs.sh");

# after this there will be a LexSample dir containing a separate dir for each
# lexelt and each lexelt containing a separate test dir and optional train
# dir

if(defined $opt_verbose)
{
	print STDERR "Created LexSample Directory !!!\nWe are now ready to start experiments!\n";
	print STDERR "Run sc-toolkit.sh, target-wrapper.sh, or word-wrapper.sh\n";    
        print STDERR "Remember to rename the LexSample file after each experiment\n";
	print STDERR "and run makedata.sh again.\n";

}

##############################################################################

#                      ==========================
#                          SUBROUTINE SECTION
#                      ==========================

#-----------------------------------------------------------------------------
#show minimal usage message
sub showminimal()
{
	print "Usage: setup.pl [Options] DATA\n";
	print "Type 'setup.pl --help' for quick summary of the Options.\n";
	print "Type 'perldoc setup.pl' for detailed description of setup.pl.\n'";
}

#-----------------------------------------------------------------------------
#show help
sub showhelp()
{
	print "Usage: setup.pl [Options] DATA";
	print "Required Arguments:

DATA	a Senseval-2 formatted file

Optional Arguments:

Data Options :
--------------

--training TRAINFILE
	DATA will be clustered using the features extracted from the given
	TRAINFILE file. By default, features are extracted from the same DATA
	file.

--split P
	Given DATA is randomly split into P:1-P TRAIN::TEST parts such that,
	(1-P)% TEST portion is clustered using the features extracted from the
	rest P% TRAIN.

If neither --training nor --split options are used, DATA will be clustered
using the features extracted from the same DATA file.

Sense Tag Options :
-------------------

--key KEY
	If the sense ids of the DATA instances are available in a separate KEY
	file, this information can be used for evaluation of results. The 
	KEY file specified via --key option should show the correct sense tags
	of the DATA instances.
 
Tokenization Options :
----------------------
--token TOKENFILE

	TOKENFILE is a file of Perl regexes that define tokenization scheme in 
	DATA. If not specified, a default file token.regex will be searched 
	in current directory.

--nontoken NONTOKENFILE

	NONTOKENFILE is a file of Perl regexes that define strings that  
	will be removed prior to tokenization.

Other Options :
---------------

--verbose
	Displays to STDERR the current program status. Silent by default.

--showargs
	Displays to STDOUT values of required and option arguments.

--help
        Displays this message.

--version
        Displays the version information.

Documentation :
----------------
See perldoc page of setup.pl for detailed help.\n";

}
#------------------------------------------------------------------------------

#version information
sub showversion()
{
#        print "setup.pl      -       Version 0.03\n";
	print '$Id: setup.pl,v 1.3 2008/03/29 23:43:35 tpederse Exp $';
        print "\nPrepares samples DATA for running experiments with SenseClusters\n";
#        print "\nCopyright (c) 2002-2006, Ted Pedersen, Amruta Purandare.\n";
#        print "Date of Last Update:     07/28/2006\n";
}

#############################################################################

