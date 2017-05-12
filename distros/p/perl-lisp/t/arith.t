print "1..27\n";

use Lisp::Interpreter qw(lisp_read_eval_print);
use Lisp::Subr::All;

$testno=1;
sub ok  { print "ok ", $testno++, "\n" }
sub bad { print "not " }
*run = \&lisp_read_eval_print; # save some typing

bad unless run("'33") eq "33";
ok;

bad unless run("(+ 1)") eq "1";
ok;

bad unless run("(+ 1 1)") eq "2";
ok;

bad unless run("(+ 1 2 3 4)") eq "10";
ok;

bad unless run("(+ 1 (+ 2 (+ 3 (+ 4))))") eq "10";
ok;

bad unless run("(1+ 1)") eq "2";
ok;

bad unless run("(- 1)") == -1;
ok;

bad unless run("(- -1)") == 1;
ok;

bad unless run("(- 10 5)") == 5;
ok;

bad unless run("(- 10 4 3 2 1)") == 0;
ok;

bad unless run("(1- 10)") == 9;
ok;

bad unless run("(* 3)") == 3;
ok;

bad unless run("(* 3 3)") == 9;
ok;

bad unless run("(* 3 3 3)") == 27;
ok;

bad unless run("(/ 9 3)") == 3;
ok;

bad unless run("(% 9 3)") == 0;
ok;

bad unless run("(max 1 2 3)") == 3;
ok;
bad unless run("(max 2 3 1)") == 3;
ok;
bad unless run("(max 3 1 2)") == 3;
ok;
bad unless run("(min -10 -90 100)") == -90;
ok;

bad unless run("(+ (* (max 3 4 1) (- 10 (1+ 9))) (+ 3 4))") == 7;
ok;

bad unless run("(list (floatp 33.33) (floatp t))") eq "(t nil)";
ok;
bad unless run("(list (integerp 42) (integerp 33.3))") eq "(t nil)";
ok;
bad unless run("(list (numberp 33.33) (numberp t))") eq "(t nil)";
ok;
bad unless run("(list (zerop 0) (zerop 33))") eq "(t nil)";
ok;

#
# Test some of the Perl functions
# 

bad unless abs(run("(cos (sin 10))") - cos(sin(10))) < 0.0000001;
ok;

$badrand=0;
$randsum=0;
for (1 .. 100) {
    my $r = run("(int (rand 10))");
    $randsum += $r;
    $badrand++ if $r < 0 || $r > 10;
}
$badrand++ if $randsum < 300 || $randsum > 700; # real bad luck if this happens
bad if $badrand;
ok;

