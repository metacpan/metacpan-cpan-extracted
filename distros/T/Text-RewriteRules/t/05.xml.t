# -*- cperl -*-
use Test::More tests => 10;
use Text::RewriteRules;

RULES first
[[:XML:]]==>XML
ENDRULES

RULES Xsecond
[[:XML(d):]]==>XML
ENDRULES

RULES Ysecond
[[:XML(c):]]==>XML
ENDRULES

RULES Zsecond
[[:XML(b):]]==>XML
ENDRULES

RULES third
[[:XML:]]=e=>$+{TAGNAME}
ENDRULES

RULES Xthird
[[:XML:]]=e=>$+{PCDATA}
ENDRULES

my $in = "<a><b></a></b> ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";
my $in2 = "ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola <a hmm =\"hmm\"><b><d zbr='foo'/><c>o</c></b></a> ola";
my $in3 = "<foo hmm=\"bar\"/>";

is(first($in),"<a><b></a></b> ola XML ola");
is(first($in2),"ola XML ola XML ola");
is(first($in3), "XML");

is(Xsecond($in),"<a><b></a></b> ola <a hmm =\"hmm\"><b>XML<c>o</c></b></a> ola");
is(Ysecond($in),"<a><b></a></b> ola <a hmm =\"hmm\"><b><d zbr='foo'/>XML</b></a> ola");
is(Zsecond($in),"<a><b></a></b> ola <a hmm =\"hmm\">XML</a> ola");
is(Zsecond($in2),"ola <a hmm =\"hmm\">XML</a> ola <a hmm =\"hmm\">XML</a> ola");

is(third($in),"<a><b></a></b> ola a ola");
is(third($in3),"foo");
is(Xthird($in),"<a><b></a></b> ola o ola");


