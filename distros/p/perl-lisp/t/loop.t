print "1..1\n";

use Lisp::Interpreter qw(lisp_read_eval_print);
use Lisp::Subr::Core;

$testno=1;
sub ok  { print "ok ", $testno++, "\n" }
sub bad { print "not " }
*run = \&lisp_read_eval_print; # save some typing

$res = run(<<'EOT');

(setq a 10)
(setq sum 0)
(while (not (zerop a))
    (setq sum (+ sum a))
    (setq a (1- a))
)

(list sum)
EOT

print "$res\n";
bad unless $res eq "(55)";
ok;


