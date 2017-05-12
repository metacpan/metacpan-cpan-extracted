# -*- cperl -*-
use strict;
use warnings;

use IO::Handle;
use Test::More tests => 110;

use vars qw($DEBUG);
use Cwd;
BEGIN {
    use_ok('Text::BibTeX', qw(purify_string));
    my $common = getcwd()."/t/common.pl";
    require $common;
}

#
# purify.t
#
# Text::BibTeX test program -- compare my purify routine with known
# results from BibTeX 0.99.
#
# $Id$
#

$DEBUG = 1;

# make sure that purify_string doesn't modify its input string
# (at least while it's *supposed* to act this way!)
my ($in1, $in2, $out);
$in1 = 'f{\"o}o';
$in2 = $in1;
$out = 'clobber me';
$out = purify_string ($in2);
is($in1, $in2);
is($out, 'foo');

is(length $in1, 7);
is(length $in2, 7);
is(length $out, 3);

# These two *don't* come from BibTeX -- just borderline cases
# that should be checked
is(purify_string (''), '');
ok(! defined purify_string (undef));


# The "expected" results here are all taken directly from BibTeX, using
# a special .bst file of my own devising.  One problem is that BibTeX
# strips trailing spaces from each line on output, which means that 
# "purified" strings ending with a space are not delivered exactly as
# I expect them.  However, BibTeX's text.length$ function does give the
# correct length (including those trailing spaces), so at least I can
# indirectly check that things are as I expect them to be.
#
# The upshot of all this is that the "expected purified strings" in the
# table below are shorn of trailing spaces, but have accurate lengths.
# My reasoning for doing things this way is that although it is (apparently)
# BibTeX's output routines that does the space-stripping, there is no 
# way to get data out of BibTeX other than through its output routines.
# Thus, if I'm going to compare my results with BibTeX's, I'd better be
# prepared to deal with the stripped-spaces problem...so I am!

my @tests = 
   (q[Bl{\"o}w, Jo{\'{e}} Q. and J.~R. R. Tolk{\u e}in and {Fo{\'o} Bar ~ {\aa}nd {\SS}on{\v{s}}, Ltd.}] => 
       [58, 'Blow Joe Q and J R R Tolkein and Foo Bar   aand SSonvs Ltd'],
    q[] => [0, ''],
    q[G{\"o}del] => [5, 'Godel'],
    q[G{\" o}del] => [5, 'Godel'],
    q[G{\" o }del] => [5, 'Godel'],
    q[G{\"o }del] => [5, 'Godel'],
    q[G{\"{o}}del] => [5, 'Godel'],
    q[G{\" {o}}del] => [5, 'Godel'],
    q[G{\" { o}}del] => [5, 'Godel'],
    q[G{\" {o }}del] => [5, 'Godel'],
    q[G{\" { o }}del] => [5, 'Godel'],
    q[G{\" { o } }del] => [5, 'Godel'],
    q[G{\"{o} }del] => [5, 'Godel'],
    q[G{\" {o} }del] => [5, 'Godel'],
    q[G{\"o foo}del] => [8, 'Gofoodel'],
    q[G{\"foo}del] => [7, 'Gfoodel'],
    q[G{\"{foo}}del] => [7, 'Gfoodel'],
    q[{G\"odel}] => [5, 'Godel'],
    q[G{\"o}del] => [5, 'Godel'],
    q[G{\"{o}}del] => [5, 'Godel'],
    q[{\ss}uper-duper] => [12, 'ssuper duper'],
    q[{\ss }uper-duper] => [12, 'ssuper duper'],
    q[{ \ss}uper-duper] => [13, ' ssuper duper'],
    q[{\ss{}}uper-duper] => [12, 'ssuper duper'],
    q[{\ss foo}uper-duper] => [15, 'ssfoouper duper'],
    q[{\ss { }}uper-duper] => [12, 'ssuper duper'],
    q[{\ss {foo}}uper-duper] => [15, 'ssfoouper duper'],
    q[{\ss{foo}}uper-duper] => [15, 'ssfoouper duper'],
    q[Tom{\`a}{\v s}] => [5, 'Tomas'],
    q[Tom{\`a}{\v{s}}] => [5, 'Tomas'],
    q[Tom{\`a}{{\v s}}] => [7, 'Tomav s'],
    q[{Tom{\`a}{\v s}}] => [7, 'Tomav s'],
    q[{Tom{\`a}{\v{s}}}] => [6, 'Tomavs'],
    q[{Tom{\`a}{\v{ s}}}] => [7, 'Tomav s'],
    q[{Tom{\`a}{\v{ s }}}] => [8, 'Tomav s'],
    q[{\v s}] => [1, 's'],
    q[{\x s}] => [1, 's'],
    q[{\r s}] => [1, 's'],
    q[{\foo s}] => [1, 's'],
    q[{\oe}] => [2, 'oe'],
    q[{\ae}] => [2, 'ae'],

    # Handling of \aa is a bit problematic -- BibTeX 0.99 converts this
    # special char. to "a", but my understanding of the Nordic languages
    # leads me to believe it ought to be converted to "aa".  (E.g.
    # \AArhus is usually written "Aarhus" in English, not "Arhus".)
    # Neither way will result in proper sorting (at least for Danish,
    # where \aa comes at the end of the alphabet), but at least my way 
    # is consistent with the normal English rendering of \aa.
#   q[{\aa}] => [1, 'a'],               # BibTeX 0.99's behaviour
    q[{\aa}] => [2, 'aa'],              # btparse's behaviour
    q[{\AA}] => [2, 'Aa'],
    q[{\o}] => [1, 'o'],
    q[{\l}] => [1, 'l'],
    q[{\ss}] => [2, 'ss'],
    q[{\ae s}] => [3, 'aes'],
    q[\TeX] => [3, 'TeX'],
    q[{\TeX}] => [0, ''],
    q[{{\TeX}}] => [3, 'TeX'],
    q[{\foobar}] => [0, '']
    );

while (@tests)
{
   my $str = shift @tests;
   my ($exp_length, $exp_purified) = @{shift @tests};

   my $purified = purify_string ($str);
   my $length = length $purified;       # length before stripping
   printf "[%s] -> [%s] (length %d) (expected [%s], length %d)\n",
          $str, $purified, $length, $exp_purified, $exp_length
      if $DEBUG;

   $purified =~ s/ +$//;                # strip trailing spaces
   is($purified, $exp_purified);
   is($length, $exp_length);
}

