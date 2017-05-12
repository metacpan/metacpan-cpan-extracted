#!/usr/bin/perl -w

BEGIN {print "1..1\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

use WWW::Link::Repair;
use WWW::Link::Repair::Substitutor;

#$::verbose=0xFF;
#$::verbose=32;
$::verbose=0 unless defined $::verbose;
$WWW::Link::Repair::Substitutor::verbose=0xFFF if $::verbose;

$loaded = 1;

$text = <<EOF;
<HTML>
<HEAD>
<TITLE>Test file.. for testing repairs</TITLE>
</HEAD>
<BODY>
<P><A HREF="http://bounce.com/">this</A> is a paragraph
with some garbage text <A HREF=http://bounce.com/>about nothing</A>
</P>
</BODY>
</HTML>
EOF


$targettext = $text;

$targettext =~ s/bounce.com/bing.bong/g;


$tfile="/tmp/test.$$";
open(TESTFILE, ">$tfile");
print TESTFILE $text;
close TESTFILE;

$filehand1 = WWW::Link::Repair::Substitutor::gen_file_substitutor
  ( "http://bounce.com/" , "http://bing.bong/");


&$filehand1("$tfile");
open(TESTFILE, "$tfile");

$returntext="";
while ( <TESTFILE> ) {
  $returntext = $returntext . $_;
}

$returntext eq $targettext or nogo;
ok(1);

#  sub file_to_url {
#
#  }
