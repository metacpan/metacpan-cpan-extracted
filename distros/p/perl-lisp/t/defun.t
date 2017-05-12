print "1..1\n";

use Lisp::Interpreter qw(lisp_read_eval_print);
use Lisp::Subr::Core;

$testno=1;
sub ok  { print "ok ", $testno++, "\n" }
sub bad { print "not " }
*run = \&lisp_read_eval_print; # save some typing

$res = run(<<'EOT');

(defun sum2 (a b &optional c)
    (+ a b))
(setq ok1 (= (sum2 3 4) 7))

(defun sumn (&rest numbers)
    ; Silly implementation
    42)
(setq ok2 (= (sumn 21 21) 42))


;; Return testing results
(list ok1 ok2)
EOT

print "$res\n";
bad unless $res eq "(t t)";
ok;

