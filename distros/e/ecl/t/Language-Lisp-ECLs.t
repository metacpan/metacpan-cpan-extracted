# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Language-Lisp-ECL.t'

#########################

BEGIN{$ENV{PERL_DL_NONLAZY}=0}# Temporary  fix:) oh, don't ask why....  
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More ('no_plan'); # tests => 30?;
BEGIN { use_ok('ecl') };

#########################

my $cl = new ecl;

ok($cl->eval("(+ 1 2)")==3, '1+2=3');
is($cl->eval("(format nil \"[~S]\" 'qwerty)"), '[QWERTY]');
is($cl->eval("'qwerty")->stringify, '#<SYMBOL COMMON-LISP-USER::QWERTY>', 'symbol stringification');
is($cl->eval("(defpackage :qw)")->stringify, '#<PACKAGE QW>', 'package');
is($cl->eval("(defpackage \"qw\")")->stringify, '#<PACKAGE qw>', 'package');

my $lam = $cl->eval("(lambda (x y) (+ x y))");
is($lam->funcall(40,2),42,'funcall');
is(''.$lam,'#<CODE>');

my $lamstr = $cl->eval("(lambda (name) (format nil \"hello mister ~A\" name))");
is($lamstr->funcall("Twister"),"hello mister Twister",'funcall');

# autoloading
$cl->eval(<<"EOS");
(defun this (a)
  (make-string a :initial-element #\\t))
EOS
is($cl->this(5),'t'x5);
is($cl->this(50_000),'t'x50_000);

my $nil = $cl->eval("nil");
is($cl->format($nil,"[[~A]]","qwerty"),"[[qwerty]]");

# list as tied array
my $list = $cl->eval("'(a b c \"d\" qwerty)");
my $aref = $list->_tie;
is($#$aref,4);
is($aref->[3],"d");
is($aref->[-2],"d");
is($list->item(4)->stringify,"#<SYMBOL COMMON-LISP-USER::QWERTY>");
is($list->stringify,"#<LIST(5)>");

# char
is($cl->eval("#\\s")->stringify,"s");
is($cl->makeString(20,$cl->keyword("INITIAL-ELEMENT"), $cl->char("s")),"s"x20);

# bignums
my $bignum = $cl->eval("(expt 2 1000)");
is($bignum->stringify0, $cl->eval('(format nil "~A" (expt 2 1000))'));

# fractions
is($cl->eval("(/ 3 4)").'', "#<RATIO 3/4>");
is($cl->eval("3/4")->stringify,"#<RATIO 3/4>");
is($cl->eval("3/4000000000000000000000000000000")->stringify,"#<RATIO 3/4000000000000000000000000000000>");

# complex nums
my $cx = $cl->eval("(complex 0 1)");
my $lam1 = $cl->eval("(lambda (x y) (* x y))");
ok($lam1->funcall($cx, $cx) == -1); # wow :)


# other way round:

my $lisplist = $cl->eval(<<'EOS');
(progn
  ()()() ()()()()
  (perl-ev-list "qq/foo, bar, fluffy/ =~ /(\\w+)/g"))
EOS

#ok($lisplist.'' eq '#<LIST(3)');
# TODO #ok($lisplist->item(1) eq 'bar');

