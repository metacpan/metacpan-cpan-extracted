print "1..4\n";

use Lisp::Interpreter qw(lisp_read_eval_print);
use Lisp::Subr::Core;

$testno=1;
sub ok  { print "ok ", $testno++, "\n" }
sub bad { print "not " }
*run = \&lisp_read_eval_print; # save some typing

bad unless run("(< 3 4)") eq "t" &&
           run("(> 3 4)") eq "nil" &&
           run("(not (< 3 4))") eq "nil";
ok;

bad unless run("(and (= 3 3) (/= 3 4))") eq "t";
ok;

bad unless run("(not (not (null 333)))") eq "nil";
ok;

$res = run(<<'EOT');
; This test conditionals and stuff

(setq a 1)
(setq b 2)
(setq c 3)

(and (setq a 4) (setq b nil) (setq c 33))
(setq ok1 (and (= a 4) (null b) (= c 3)))

(setq a 1)
(setq b 2)
(setq c 3)

(setq c (or (setq a nil) (setq b 0)))
(setq ok2 (and (null a) (= b 0) (= c 0)))

(if (= 3 3) (setq ok3 t) (setq ok3 nil))
(setq ok5 nil)
(if (= 3 4) (setq ok4 nil) (setq ok4 t) (setq ok5 t))

(setq a 1)
(setq b 2)
(setq c 3)

(cond ((setq a 100) (setq b 100))
      ((setq c 100)))
(setq ok6 (and (= a 100) (= b 100) (/= c 100)))

(setq res (cond (nil (setq a 50))
	        (t 42)))  ; default
(setq ok7 (and (/= a 50) (= res 42)))

(list ok1 ok2 ok3 ok4 ok5 ok6 ok7)
EOT

#print "$res\n";
bad unless $res eq "(t t t t t t t)";
ok;
