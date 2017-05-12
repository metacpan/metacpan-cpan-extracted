#!/usr/bin/perl -w
#
# Copyright (C) 2002 Ward Vandewege (w@wesql.org)
# 
# assemble.pl is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# assemble.pl is distributed in the hope that it will be useful,
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
# assemble.pl will read a 'language file' as made by extract.pl, and update the
# text surrounded by language tags in the .wsql/.cf files in the specified
# directory.
#
# After running assemble.pl, you can erase the language file, and if desired,
# generate a new one with extract.pl

use Getopt::Long;
use diagnostics;

my $SCRIPTNAME = 'assemble.pl';
my $VERSION = '0.10';

my (%opts);

$| = 1;

&main();

sub assemble {
	my $dir = shift;
	my $langfile = shift;

	my ($tlang,$flang);

	# Get original and updated/new language from $langfile
	if ($langfile =~ /^(.{2})_(.{2})_translation\.txt$/) {
		$tlang = $1;
		$flang = $2;
	} else {
		print "The file with translations has been renamed, and can not be processed.\n It needs to be named newlang_oldlang_translation.txt for this script to work, with newlang and oldlang both a 2 letter language code.\nAborting.\n";
		exit;
	}

	open(LANGFILE,$langfile) || die "Can't open file $langfile: $!";
	my $body = join('',<LANGFILE>);
	close(LANGFILE);

	# First remove comments and empty lines
	$body =~ s/^(#.*?|)\n//gm;

	my %filehash;

	# Now deal with the substitutions
	while ($body =~ /^(.*?) -> (.*?)\n\n/gsm) {
		my ($tmp,$tmp2) = ($1,$2);
		($tmp,$number) = ($tmp =~ /(.*)\.(\d+)$/);
		$filehash{$tmp}{$number} = $tmp2;
	}

	foreach (sort keys %filehash) {
		my $file = $_;
		open(THEFILE,$file) || die "Can't open original file $file: $!"; 
		my $body = join('',<THEFILE>);
		close(THEFILE);
		my $oldbody = $body;

		foreach (sort keys %{$filehash{$file}}) {
			my $hashnumber = $_;
			my $number = $hashnumber + 0;
			$body =~ s/(<$flang $number>.*?<\/$flang>)(<$tlang $number>.*?<\/$tlang>|)/$1<$tlang $number>$filehash{$file}{$hashnumber}<\/$tlang>/sm;
		}

		if ($body ne $oldbody) {
			print "$file\n";
			open(THEFILE,">$file.tmp");
			print THEFILE $body;
			close(THEFILE);
			if (!-f "$file.orig_assemble") {
				rename($file,"$file.orig_assemble");
				rename("$file.tmp",$file);
			} else {
				print "New $file is saved as $file.tmp, could not move $file to $file.orig_assemble as that file exists!\n";
			}
		}
	}
	print "Language '$tlang' has been updated.\n";
}

sub main {
  # Deal with the command line options
  GetOptions('directory=s' => \$opts{dir},'from=s' => \$opts{f},'help' => \$opts{h},'version' => \$opts{version});

  if (defined($opts{h}) || (!defined($opts{dir})) || (!defined($opts{f})) ) {
    print <<"EOF";
$SCRIPTNAME $VERSION
assemble.pl will read a 'language file' as made by extract.pl, and update the
text surrounded by language tags in the .wsql/.cf files in the specified
directory.

After running assemble.pl, you can erase the language file, and if desired,
generate a new one with extract.pl

assemble.pl comes with WeSQL (http://wesql.org), and is licensed under the GPL 
(Gnu Public License) version 2 or higher.

Command line arguments:
  -d <directory>, --directory=<directory>     (MANDATORY!)
    the directory with .wsql and .cf files to be updated
  -f <language-file>, --file=<language-file>     (MANDATORY!)
    the language file (e.g. nl_en_language.txt)
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
assemble.pl comes with NO WARRANTY,
to the extent permitted by law.
You may redistribute copies of assemble.pl
under the terms of the GNU General Public License.
For more information about these matters,
see the files named COPYING.
EOF
    exit 0;
  } 

	my $dir = $opts{dir};
	my $langfile = $opts{f};

	&assemble($dir,$langfile);

}
