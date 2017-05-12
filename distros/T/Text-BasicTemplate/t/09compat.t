#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::BasicTemplate;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#use Text::BasicTemplate;

my $pp;
my %arg;
@arg{strip_html_comments,strip_c_comments,strip_cpp_comments,strip_perl_comments} =
 (1,1,1,1);
@arg{condense_whitespace,use_cache,simple_ssi,eval_conditionals,eval_subroutine_refs} = (1,1,1,1,1);
$arg{document_root} = '.';
$arg{use_scalarref_template_cache} = 1;
print "not " unless $pp = new Text::BasicTemplate(%arg);
print "ok 2\n";

my $buf = "foo";
print "not " unless $pp->push(\$buf);
print "ok 3\n";
print "not " unless $pp->push(\$buf,"key=value");
print "ok 4\n";

my $strip_comment_buffer = <<"EOT";
C /* C comment */
C++ // C++ comment
sharp \# perl comment
html <!-- html comment -->
EOT
print "not " unless (join(',',split(/\s+/m,$pp->push(\$strip_comment_buffer)))
		       eq 'C,C++,sharp,html');
print "ok 5\n";

my $repl_buffer = "%foo%";
print "not " unless ($pp->push(\$repl_buffer,foo => 'bar') eq 'bar');
print "ok 6\n";

my $cond_buffer = "%?one==1%true%false% %?one==2%true%false%";
print "not " unless ($pp->push(\$cond_buffer,one => 1) eq 'true false');
print "ok 7\n";

my $fn = "/tmp/test-text_parseprint_$$";
if (open(TESTFILE,">$fn")) {
  print TESTFILE "%foo%";
  close TESTFILE;
  print "not " unless ($pp->push($fn,foo => 'bar') eq 'bar');
  unlink $fn;
} else {
  warn "Couldn't open /tmp/text_parseprint_$$: $!";
  print "not ";
}
print "ok 8\n";

my $subref_buffer = '%snaf% %one%';
print "not " unless $pp->push(\$subref_buffer,
			      snaf => sub { 'u' },
			      one => 2) eq 'u 2';
print "ok 9\n";

print "not " unless $pp->list_lexicon_cache;
print "ok 10\n";

print "not " unless $pp->purge_cache;
print "ok 11\n";

## tests after this point were not in 0.9.8's test suite

$pp->{simple_ssi} = 1;
my $ss;
my $tfn = "maketest-04pragma-$$-it.tmpl";
my $tf = "/tmp/$tfn";
my $iov = { me => 'something' };
open(TT,">$tf") || do {
    print "not ok 3\n";
    exit(1);
};
print TT "included %me%";
close TT;
print "ok 12\n";

$ss = "I have <!--#include file=\"$tf\"-->";
print "not " unless $pp->parse(\$ss,$iov) eq 'I have included something';
print "ok 13\n";

$pp->{include_document_root} = '/tmp';
$ss = "I have <!--#include virtual=\"$tfn\"-->";
print "not " unless $pp->parse(\$ss,$iov) eq 'I have included something';
print "ok 14\n";

# FIXME -- restore orphan-% test
$ss = "pre<table width=\"42%%\">%?me==something% y % n % %me%";
#print STDERR "[".$pp->parse(\$ss,$iov)."]";
print "not " unless $pp->parse(\$ss,$iov) eq
  'pre<table width="42%"> y something';
print "ok 15\n";

#$ss = "%?one==1%\nfoo\n%\nbar\n%\n";
$ss = "%?one==1%\nfoo\n%\nbar\n%\n";
print "not " unless $pp->parse(\$ss,{'one',1}) eq "\nfoo\n";
print "ok 16\n";

#$ss = "pre%?one==1%true%false%<table width=\"42%\"> xx 47%, %?one==1%T%F% %?two==3%T%F% %?one=={two}%T%F%";
##print STDERR "[".$pp->parse(\$ss,{ one => 1, two => 2})."]\n";
#print "not " unless $pp->parse(\$ss,{ one => 1, two => 2}) eq
#  'pretrue<table width="42%"> xx 47%, T F F';

#$ss = "<foo %?odd==1%bgcolor=#f2f2f2%bgcolor=#c7c7c7%>";
$ss = "%?odd==foo%foo%b=ar%";
print "not " unless $pp->parse(\$ss,{'odd' => 1}) eq "b=ar";
print "ok 17\n";

#print "17out=[".$pp->parse(\$ss,{ one => 1, two => 2})."]\n";

$ss = "<title>%?one==1%true%false%</title>";
print "not " unless $pp->parse(\$ss, { one => 1}) eq '<title>true</title>';
print "ok 18\n";

$ss = "%?one==1% tr?ue % fal?se %";
print "not " unless $pp->parse(\$ss, { one => 1}) eq ' tr?ue ';
print "ok 19\n";

$ss = "%?one==1% f{one}o % t{two}o %";
print "not " unless $pp->parse(\$ss, { one=>1, two=>2}) eq ' f1o ';
print "ok 20\n";

$ss = "x%x%y";
print "not " unless $pp->parse(\$ss,"x=z\nz") eq "xz\nzy";
print "ok 21\n";

$pp->{include_document_root} = '/tmp';
$ss = "I have <!--#include virtual=\"$tfn-->";
print "not " unless $pp->parse(\$ss,$iov) eq 'I have included something';
print "ok 22\n";

unlink($tf);



# $Id: 09compat.t,v 1.12 2000/01/20 07:11:36 aqua Exp $
