#!/usr/bin/perl -I. -I..
# if run as filter_test.cgi -t $(cat filter_test.params) > filter_test.xml,
# diff -b filter_test.xml instance.xml should return 0 (files match)
# this can also be run as a cgi script, for testing changing the instance data from
#the web. just put the following in a web accessable directory:
#   this script ../PostFilter.pm ../xforms.css ../xforms.xml ../test.xml

use PostFilter;

use XML::LibXSLT;
use HTML::Entities ();
use Getopt::Std;
use CGI;

my $opts='td:';

use vars qw($opt_t,$opt_d);
getopts($opts) or die "usage: $0 [$opts] [cgi_param=value ...]";

my $q=CGI->new;
my $parser=XML::LibXML->new;

my %vars=$q->Vars;

unless($vars{_instance}) {
	my $xslt=XML::LibXSLT->new;
	my $doc=$parser->parse_file('test.xml');
	my $sheet=$xslt->parse_stylesheet
	($parser->parse_file('xforms.xsl'));
	print $sheet->output_string($sheet->transform
								($doc,'encode-instance-data' => 1));
	exit 0;
	
}
my $out=PostFilter->new(parser=>$parser,debug=>$opt_d)->parse(\%vars)->toString(1);
print $out and exit 0 if $opt_t;

print $q->header,"<html><pre>\n",HTML::Entities::encode($out),"</pre></html>\n";;
	


