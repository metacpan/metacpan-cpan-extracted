#!/usr/bin/perl -w
# Author: Oded S. Resnik           Email: razinf@cpan.org
#  Copyright (c) 2003 RAZ Information Systems LTD. http://www.raz.co.il
#  
#You may distribute under the terms of either the GNU General Public
#License or the Artistic License, as specified in the Perl README file
#
# This program updates documentation 
#
use ExtUtils::MakeMaker;
use Date::Format;
use Pod::Text;
use Pod::Html;
use Getopt::Std;
use strict;
####### User configutable values #######
my $makepl = 'Makefile.PL';
my @dirs = qw (. ..); # Where to look for $makepl
######## End of user configuration #####
use vars qw($VERSION $opt_s $opt_H $opt_h);
my $htmldir="html/";
$VERSION = '1.00';
my $me = $0;           
$me =~ s,.*/,,i;
getopts("hsH:") || &usage;
&usage if $opt_h;
if ($opt_H) {
	$opt_H = $opt_H . '/' unless $opt_H =~ m|\/$|;
	$htmldir =  $opt_H;
	};
print "  $me Version $VERSION\n";
print "==========================\n" unless $opt_s;
sub usage{
    die <<EOF;
=== $me Version $VERSION

Usage $me <options> 

Options:
    -h   Display this help message
    -s   Silent Mode
    -H	 <Html directory> 
EOF
};

my $wdir;
foreach  (@dirs){
       if (-e "$_/$makepl")
                {
		$wdir = $_ . '/';
		print "Perl makefile is $wdir$makepl\n" unless $opt_s;
                last;
                };
	}
die "$me: $makepl not fond in " . join (' ' , @ dirs) unless $wdir;
open (MFILE,"$wdir$makepl");
my $project_name;
my $file_name;
while (<MFILE>){
	my $value;
	next if /^#/;
	next unless /=>/;
	s/\s//g;
	/=>\'(.*)'/;
	$value = $1;
	if (/NAME/) {
		$project_name = $value; 
		next;
		};
	if (/VERSION_FROM/) {
                $file_name = $value;
                next;
                };

	last if ($file_name && $project_name);
	};
my $modver=MM->parse_version("$wdir$file_name");
if (! $opt_s) {
	print "Name=> $project_name\n";
	print "File=> $file_name\n";
	print "Version=> $modver\n" ;}
my @lt = localtime(time);
my $today=strftime("%Y %m %d",@lt);
my $file= $file_name;
$file =~ s/\..*$//;
my $pod_file =  $file_name;
$pod_file = "$file.pod" if (-e "$wdir$file.pod");
open (README,">${wdir}README");
	{
	local *STDOUT= *README;
	print  "${project_name} Version $modver   README              $today\n\n"; 
	my $parser = Pod::Text->new(quotes=>'none');
	$parser->parse_from_file("$wdir${pod_file}"); 
	};
print "=== README $pod_file done ...\n" unless $opt_s;
pod2html(
	"--infile=$wdir${pod_file}",
	"--css=${wdir}${htmldir}docs.css",
	"--outfile=${wdir}${htmldir}${file}.html", 
        "--title=${project_name} Version ${modver}"); 
print "=== ${file}.html done ...\n" unless $opt_s;
##### Over ride Pod::Text
sub Pod::Text::seq_i { return '' . $_[1] . '' }; # For more readable README
