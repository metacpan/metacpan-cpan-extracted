#!/usr/bin/perl -w
#
# Copyright (C) 2002 Ward Vandewege (w@wesql.org)
# 
# extract.pl is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# extract.pl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#  
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# extract.pl will make a 'language file' from all .wsql/.cf files in the
# directory you specify, from the language you specify.
#
# You have to give it two languages as parameters, the 'from' and the 'to'
# language. The 'from' language is the language you would like the translation
# to start from, and the 'to' language is obviously the language you are
# getting a translation into.
#
# extract.pl looks for all numbered tag pairs in the 'from' language, and puts
# the text that they surround in one big file that can then be passed on to a
# translator. If some tag pairs already exist in the 'to' language, the 'to'
# language text will be inserted in the language file. So this script is safe
# to run on your files as much as you like. It will not change them.
#    
# One word of caution, however: be sure that the tag numbers for all the
# languages correspond! Run number.pl for each language to make them correspond.

use Getopt::Long;
use diagnostics;

my $SCRIPTNAME = 'extract.pl';
my $VERSION = '0.10';

my (%opts);

$| = 1;

&main();

sub extract {
	my $file = shift;
	my $flang = shift;
	my $tlang = shift;
	my %tlang = @_;
	open(WSQLFILE,$file) || die "Can't open file $file: $!";
	my $body = join('',<WSQLFILE>);
	close(WSQLFILE);
	
	while ($body =~ /<$flang (\d{1,})>(.*?)<\/$flang>/gsm) {
		$tlang{sprintf("%s.%03d",$file,$1)} = $2;
	}

	while ($body =~ /<$tlang (\d{1,})>(.*?)<\/$tlang>/gsm) {
		$tlang{sprintf("%s.%03d",$file,$1)} = $2;
	}

	return %tlang;
}

sub main {
  # Deal with the command line options
  GetOptions('directory=s' => \$opts{dir},'from=s' => \$opts{f},'to=s' => \$opts{t},'help' => \$opts{h},'version' => \$opts{version});

  if (defined($opts{h}) || (!defined($opts{dir})) || (!defined($opts{f})) || (!defined($opts{t})) ) {
    print <<"EOF";
$SCRIPTNAME $VERSION
extract.pl will make a 'language file' from all .wsql/.cf files in the
directory you specify, from the language you specify.

You have to give it two languages as parameters, the 'from' and the 'to'
language. The 'from' language is the language you would like the translation
to start from, and the 'to' language is obviously the language you are
getting a translation into.

extract.pl looks for all numbered tag pairs in the 'from' language, and puts
the text that they surround in one big file that can then be passed on to a
translator. If some tag pairs already exist in the 'to' language, the 'to'
language text will be inserted in the language file. So this script is safe
to run on your files as much as you like. It will not change them.
    
One word of caution, however: be sure that the tag numbers for all the
languages correspond! Run number.pl for each language to make them correspond.

extract.pl comes with WeSQL (http://wesql.org), and is licensed under the GPL 
(Gnu Public License) version 2 or higher.

Command line arguments:
  -d <directory>, --directory=<directory>     (MANDATORY!)
    the directory to scan for .wsql and .cf files
  -f <from-language>, --from=<from-language>     (MANDATORY!)
    the 'from' language
  -t <to-language>, --to=<to-language>  (MANDATORY!)
		the 'to' language to generate the language file for
  -h, --help: 
    display the help you are reading now
  -v, --version:
    display version output

Report bugs to w\@wesql.org
EOF
    exit 0;
  } elsif (defined($opts{version})) {
    print <<"EOF";
$SCRIPTNAME $VERSION
Copyright (C) 2002 Ward Vandewege (w\@wesql.org)
extract.pl comes with NO WARRANTY,
to the extent permitted by law.
You may redistribute copies of extract.pl
under the terms of the GNU General Public License.
For more information about these matters,
see the files named COPYING.
EOF
    exit 0;
  } 

	my $dir = $opts{dir};
	my $flang = $opts{f};
	my $tlang = $opts{t};

	opendir(DIR, $dir) || die "can't opendir $dir: $!";
	my @files = grep { /\.(wsql|cf)$/ && -f "$dir/$_" && (!-l "$dir/$_") } readdir(DIR);
	closedir DIR;

	my %tlang;

	foreach (@files) {
		my $file = $_;
		%tlang = &extract($file,$flang,$tlang,%tlang);
	}

	if (! -f "$opts{dir}/$opts{t}_$opts{f}_translation.txt") {
		use POSIX qw(strftime);
		my $now = strftime "%Y-%m-%d %H:%M:%S", localtime;

		if ($opts{dir} eq '.') {
			$opts{dir} = `pwd`;
			chop($opts{dir});
		}

		open(TRFILE,">$opts{dir}/$opts{t}_$opts{f}_translation.txt");
		print TRFILE <<EOF;
# This file contains the translation for language '$opts{t}'.

# All lines starting with a hash (#) are comments and will be ignored,
# as will empty lines.

# Your mission, if you choose to accept it, is to translate and replace
# all the text after the ' -> ' signs from the source language ($opts{f}) 
# into the target language ($opts{t}).

# Some things to be aware of:
# 1. Do not touch the text before the ' -> ' sign.
# 2. If there is text there that doesn't need translation (for instance, 
#    a [ or a ]), don't touch it.
# 3. Also, don't touch any html-tags (the text between < and > signs). 
#    So in this example: 
#		   buy.cf.001 -> <a href="buy.wsql">Buy now!</a>
#    you would translate and replace only 'Buy now!'.
# 4. If there are words that start with a dollar sign in the to be 
#    translated text, do not touch those. For instance: 
#      list.cf.005 -> \$email to send
#	   In the above line you would only translate and replace 'to send'.
# 5. Please do not rename this file.

# This file has been generated by extract.pl, version $VERSION.
# Extract.pl comes with WeSQL (http://wesql.org) 0.52 or higher.
# Generated on $ENV{HOSTNAME} by $ENV{USER}, on $now
# from directory $opts{dir}.

EOF
		foreach (sort keys %tlang) {
			print TRFILE "$_ -> $tlang{$_}\n\n";
		}
		close(TRFILE);
		print "The file $opts{dir}/$opts{t}_$opts{f}_translation.txt has been written.\n";
	} else {
		print "A translation file with name $opts{t}_$opts{f}_translation.txt exists already in this directory ($opts{dir})!\nNew translation file not saved.\n";
	}


}
