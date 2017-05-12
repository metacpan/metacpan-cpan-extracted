#!/usr/bin/perl -w
#
# Copyright (C) 2002 Ward Vandewege (w@wesql.org)
# 
# tag.pl is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# tag.pl is distributed in the hope that it will be useful,
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
# tag.pl will 'tag' text in all .wsql or .cf files in the specified directory
# with the language tag you specify. This means that it will recognize clear 
# text like this:
#
# <b>This is a test</b>
#
# and will change it into:
#
# <b><en>This is a test</en></b>
#
# provided you specified 'en' as the language to tag the files with. These
# language tag will be recognized by WeSQL, and the text enclosed within will
# only be displayed when a page in this language (in this case English) is 
# requested.
#
# tag.pl is ideal for switching a single-language .wsql site to a
# multi-language site.
#
# tag.pl has some limitations:
# 
# a) It will only tag text outside <!-- --> blocks, that means it won't touch
# any html you generate on the fly within EVAL blocks. You'll have to tag that
# manually.
#
# b) It's smart enough not to tag a file that already contains tags for that
# language. It will warn you about that. This means that you will have to deal
# with those files manually.
#
# c) I'm pretty sure that in certain cases, tag.pl will NOT do the right thing.
# If you find such a case, let me know.
#
# So check your files after you run tag.pl on them!

use Getopt::Long;
use diagnostics;

my $SCRIPTNAME = 'tag.pl';
my $VERSION = '0.10';

my (%opts);

$| = 1;

&main();

sub doit {
	my ($pre,$val,$post,$lang) = @_;
	$pre ||= ''; $val ||= ''; $post ||= '';
#	print "pre: $pre; val: $val; post: $post\n";
	if (($val ne "\n") && ($val ne '')){
		if (substr($val,-1,1) eq "\n") {	# If the last char of $val is \n, don't put that in the <lang></lang> block
			chop($val);
			$post = "\n$post";
		}
		if (substr($val,0,1) eq "\n") { # If the first char of $val is \n, don't put that in the <lang></lang> block
			$val = substr($val,1);
			$pre = "$pre\n";
		}
		return "$pre<$lang>$val<\/$lang>$post";
	} else {
		return "$pre$val$post";
	}
}

sub docaps {
	my ($str,$lang) = @_;
	$str =~ s/(.+?)=(.*?)(\||$)/$1=<$lang>$2<\/$lang>$3/gs;
	return $str;
}

sub hidespecial {
	my ($one,$two) = @_;
	if (!defined($two)) {
		$one =~ s/</LTSPECIALREPLACEMENT/g;
		$one =~ s/>/GTSPECIALREPLACEMENT/g;
		return "<!--$one-->";
	} else {
		$two =~ s/</LTSPECIALREPLACEMENT/g;
		$two =~ s/>/GTSPECIALREPLACEMENT/g;
		return "<!-- EVAL $one$two/EVAL $one -->";
	}
}

sub unhidespecial {
	my ($one,$two) = @_;
	if (!defined($two)) {
		$one =~ s/LTSPECIALREPLACEMENT/</g;
		$one =~ s/GTSPECIALREPLACEMENT/>/g;
		return "<!--$one-->";
	} else {
		$two =~ s/LTSPECIALREPLACEMENT/</g;
		$two =~ s/GTSPECIALREPLACEMENT/>/g;
		return "<!-- EVAL $one$two/EVAL $one -->";
	}
}

sub tag {
	my $file = shift;
	open(WSQLFILE,$file) || die "Can't open file $file: $!";
	my $body = join('',<WSQLFILE>);
	close(WSQLFILE);
	my $lang = shift;

	my $origbody = $body;

	if ($body =~ /<$lang>|<\/$lang>/) {
		print "$file already contains $lang tags. Skipping...\n";
		return $body,$origbody;
	}

	# First make sure all <!-- text --> blocks won't match
	# Special care for the multi-line EVAL blocks
	$body =~ s/<!-- EVAL (.*?)$(.*?)\/EVAL\s+\1\s+-->/&hidespecial($1,$2)/smeg;
	$body =~ s/<!--(.*?)-->/&hidespecial($1)/eg;
	# Now match all blocks of text that don't contain < and/or >
	# The following line should do the trick. However, we need to use the re in the line under it,
	# as this one is _very_ expensive in Perl 5.6.1, for no good reason. Note that if you switch
	# to the line below (when Perl has been fixed?), you will need to adapt sub doit!
#	$body =~ s/([^<>]*)(?=<)/&doit($1,$2,$lang)/egsm if ($file =~ /\.wsql$/);
	$body =~ s/(<.*?>|^)([^<>]*)(?=<)/&doit($1,$2,'',$lang)/egms if ($file =~ /\.wsql$/);

	# We have to deal slightly differently with .cf files. Basically only replace anything between
	# a > and < sign, on one line, and after the line label (e.g., something:).
	$body =~ s/(^.*?:.*?)(?<=>)([^<>]+)(?=(<|$))/&doit($1,$2,'',$lang)/egm if ($file =~ /\.cf$/);

	# Deal with the captions: line in .cf files
	$body =~ s/^captions:(.*?)$/'captions:' . &docaps($1,$lang)/egm if ($file =~ /\.cf$/);

	# Deal with the title: and titlenew: lines in .cf files
	$body =~ s/^title(new|):(.*?)$/title$1:<$lang>$2<\/$lang>/gm if ($file =~ /\.cf$/);

	# Then restore <!-- text --> blocks
	$body =~ s/<!-- EVAL (.*?)$(.*?)\/EVAL\s+\1\s+-->/&unhidespecial($1,$2)/smeg;
	$body =~ s/<!--(.*?)-->/&unhidespecial($1)/eg;

	return $body,$origbody;
}

sub main {
  # Deal with the command line options
  GetOptions('directory=s' => \$opts{dir},'language=s' => \$opts{lang},'help' => \$opts{h},'version' => \$opts{version});

  if (defined($opts{h}) || (!defined($opts{dir})) || (!defined($opts{lang})) ) {
    print <<"EOF";
$SCRIPTNAME $VERSION
tag.pl will 'tag' text in all .wsql or .cf files in the specified directory
with the language tag you specify. This means that it will recognize clear
text like this:

<b>This is a test</b>

and will change it into:

<b><en>This is a test</en></b>

provided you specified 'en' as the language to tag the files with. These
language tag will be recognized by WeSQL, and the text enclosed within will
only be displayed when a page in this language (in this case English) is
requested.

tag.pl is ideal for switching a single-language .wsql site to a
multi-language site.

tag.pl has some limitations:

a) It will only tag text outside <!-- --> blocks, that means it won't touch
any html you generate on the fly within EVAL blocks. You'll have to tag that
manually.

b) It's smart enough not to tag a file that already contains tags for that
language. It will warn you about that. This means that you will have to deal
with those files manually.

c) I'm pretty sure that in certain cases, tag.pl will NOT do the right thing.
If you find such a case, let me know.

So check your files after you run tag.pl on them!

tag.pl comes with WeSQL (http://wesql.org), and is licensed under the GPL 
(Gnu Public License) version 2 or higher.

Command line arguments:
  -d <directory>, --directory=<directory>     (MANDATORY!)
    the directory to scan for .wsql and .cf files
  -l <languagetag>, --language=<languagetag>  (MANDATORY!)
    the language tag to be inserted in the file, for instance 'en'
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
tag.pl comes with NO WARRANTY,
to the extent permitted by law.
You may redistribute copies of tag.pl
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
		my ($body,$origbody) = &tag($file,$lang);

		if ($body ne $origbody) {
			print "$file\n";
			open(OUTFILE,">$_.tmp");
			print(OUTFILE $body);
			close(OUTFILE);
			if (!-f "$file.orig_tag") {
				rename($file,"$file.orig_tag");
				rename("$file.tmp",$file);
			} else {
				print "New $file is saved as $file.tmp, could not move $file to $file.orig_tag as that file exists!\n";
			}
		}
	}
}
