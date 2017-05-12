#!/usr/bin/perl -w
#
# Copyright (C) 2002 Ward Vandewege (w@wesql.org)
# 
# number.pl is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# number.pl is distributed in the hope that it will be useful,
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
# number.pl will number the language tags in all .wsql/.cf files in the directory
# you specify. This means that a line like:
#
# <b><en>This is a test</en></b>
#
# will become something like (the actual number may vary):
#
# <b><en 12>This is a test</en 12></b>
#
# Every tag pair gets a unique number. The script is smart enough not to touch
# already numbered tags, so it is safe to run on your set of files as many times
# as you wish.

use Getopt::Long;
use diagnostics;

my $SCRIPTNAME = 'number.pl';
my $VERSION = '0.10';

my (%opts);

$| = 1;

&main();

sub number {
	my $file = shift;
	open(WSQLFILE,$file) || die "Can't open file $file: $!";
	my $body = join('',<WSQLFILE>);
	close(WSQLFILE);
	my $lang = shift;

	my $origbody = $body;

	# First find the lowest numbered tag (if any)
	my $count = 0;
#	while ($body =~ /<$lang (\d{1,})>/g) {
#		$count = $1 + 1 if ($1 > $count);
#	}

	# Next find all unnumbered tags, and alter them!
	$body =~ s/<$lang\s*\d*>/"<$lang " . ++$count . ">"/eg;

	return $body, $origbody;
}

sub main {
  # Deal with the command line options
  GetOptions('directory=s' => \$opts{dir},'language=s' => \$opts{lang},'help' => \$opts{h},'version' => \$opts{version});

  if (defined($opts{h}) || (!defined($opts{dir})) || (!defined($opts{lang})) ) {
    print <<"EOF";
$SCRIPTNAME $VERSION
number.pl will number the language tags in all .wsql/.cf files in the directory
you specify. This means that a line like:

<b><en>This is a test</en></b>

will become something like (the actual number may vary):

<b><en 12>This is a test</en 12></b>

Every tag pair gets a unique number. The script is smart enough not to touch
already numbered tags, so it is safe to run on your set of files as many times
as you wish.

number.pl comes with WeSQL (http://wesql.org), and is licensed under the GPL 
(Gnu Public License) version 2 or higher.

Command line arguments:
  -d <directory>, --directory=<directory>     (MANDATORY!)
    the directory to scan for .wsql and .cf files
  -l <languagetag>, --language=<languagetag>  (MANDATORY!)
    the language tag to be numbered in the file, for instance 'en'
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
number.pl comes with NO WARRANTY,
to the extent permitted by law.
You may redistribute copies of number.pl
under the terms of the GNU General Public License.
For more information about these matters,
see the files named COPYING.
EOF
    exit 0;
  } 

	my $dir = $opts{dir};
	my $lang = $opts{lang};

	opendir(DIR, $dir) || die "can't opendir $dir: $!";
	my @files = grep { /\.(wsql|cf)$/ && -f "$dir/$_" && (!-l "$dir/$_") } readdir(DIR);
	closedir DIR;

	foreach (@files) {
		my $file = $_;
		my ($body,$origbody) = &number($file,$lang);
		if ($body ne $origbody) {
			print "$file\n";
			open(OUTFILE,">$file.tmp");
			print(OUTFILE $body);
			close(OUTFILE);
			if (!-f "$file.orig_number") {
				rename($file,"$file.orig_number");
				rename("$file.tmp",$file);
			} else {
				print "New $file is saved as $file.tmp, could not move $file to $file.orig_number as that file exists!\n";
			}
		}
	}
	print "Done\n";

}
