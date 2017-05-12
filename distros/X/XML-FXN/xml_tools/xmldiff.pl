#!/usr/bin/perl
#
#  Copyright (c) 2002, DecisionSoft Limited All rights reserved.
#  Please see: 
#  http://software.decisionsoft.com/licence.html 
#  for more information.
# 

#
# xmldiff: xmldiff program - uses xmlpp
#

#Change this if xmlpp is not in your current path
#for example: $XMLPP = "./xmlpp";
$XMLPP = "./xmlpp";

# older versions of less don't support -R, consider -r instead
my $pagerCmd = ' | less -R ';

use Getopt::Std;

getopts('tsncupChHSi');

if ($opt_h || @ARGV != 2) {
  usage();
}

my $diffOpts;

if ($opt_n) {
  $pagerCmd = '';
}

if ($opt_u + $opt_c + $opt_s + $opt_p + $opt_C > 1) {
  print STDERR "Error: Only one mode may be specified\n";
  usage();
}


# Set diff options
if ($opt_u) {
  $diffOpts .= '-u ';
} 
if ($opt_c) {
  $diffOpts .= '-c ';
}

if (!$opt_s) {
  $diffOpts = "--changed-group-format='%<%>' ";
  $diffOpts .= " --new-group-format='%>' ";
  $diffOpts .= "--old-group-format='%<' ";
  $diffOpts .= "--new-line-format='[1m[33m+ %l\n[m' ";
  $diffOpts .= "--old-line-format='[1m[31m- %l\n[m' ";
  $diffOpts .= "--unchanged-line-format='[1m[30m  %l[m\n' ";
}
if ($opt_C) {
  $diffOpts = "--changed-group-format='\n<<<<<<<<<<<<<<\n%<==============\n%>>>>>>>>>>>>>>>\n\n' ";
  $diffOpts .= "--new-line-format='+ %l\n' ";
  $diffOpts .= "--old-line-format='- %l\n' ";
  $diffOpts .= "--unchanged-line-format='  %l\n' ";
}
if($opt_H){
  $diffOpts = "--changed-group-format='%<%>' ";
  $diffOpts .= " --new-group-format='%>' ";
  $diffOpts .= "--old-group-format='%<' ";
  $diffOpts .= "--new-line-format='<font color=\"green\">+ %l</font>\n' ";
  $diffOpts .= "--old-line-format='<font color=\"red\">- %l</font>\n' ";
  $diffOpts .= "--unchanged-line-format='<font color=\"gray\">  %l</font>\n' ";
}


# Set up xmlpp options
my $prettyOpts = $opt_t ? "-t " : "";
$prettyOpts   .= $opt_S ? "-S " : "";
$prettyOpts   .= $opt_H ? "-H " : "";
$prettyOpts   .= "-s -e ";

$file1 = "xmlppTEMP1.$$";
$file2 = "xmlppTEMP2.$$";
system("$XMLPP $prettyOpts '$ARGV[0]' > $file1");
system("$XMLPP $prettyOpts '$ARGV[1]' > $file2");

if($opt_H) {


  print <<EOF;
<HTML>
  <HEAD>
    <TITLE>XML diff</TITLE>
  </HEAD>
  <BODY bgcolor="#FFFFFF" >

    <PRE> 
EOF

  system("diff -bB $diffOpts $file1 $file2");

print <<EOF;
    </PRE>
  </BODY>
</HTML>
EOF

} else {

  system("diff -bB $diffOpts $file1 $file2 $pagerCmd");
}


unlink($file1,$file2);

exit($? >> 8);

sub usage {
  print STDERR <<EOF;
usage: $0 [ mode ] [ options ] oldfile.xml newfile.xml

Warning: The exit code from xmldiff is only meaningful if run with the -n 
option.

mode must be one of:
  -p  coloured unified diff [default]
  -c  context diff
  -u  unified diff
  -s  standard diff output
  -C  vaguely CVS like unified diff

options:
  -H  HTML output
  -t  split attributes - good for spotting changes in attributes
  -n  don't pipe output through less
  -S  schema hack mode - good for diffing schemas
  -i  ignore element and attribute contents

EOF
  exit 1;
}
