print "1..10\n";

use Lisp::Printer qw(lisp_print);
use Lisp::Symbol  qw(symbol);

$testno=1;
sub ok  { print "ok ", $testno++, "\n" }
sub bad { print "not " }


bad unless lisp_print(33) eq "33";
ok;

bad unless lisp_print(33.3) eq "33.3";
ok;

bad unless lisp_print("foo") eq '"foo"';
ok;

bad unless lisp_print('foo\bar"baz') eq '"foo\\\\bar\"baz"';
ok;

bad unless lisp_print() eq "nil";
ok;

bad unless lisp_print(undef) eq "nil";
ok;

bad unless lisp_print(symbol("nil")) eq "nil";
ok;

bad unless lisp_print(symbol("t")) eq "t";
ok;

bad unless lisp_print([3, 4, [5, 6]]) eq "(3 4 (5 6))";
ok;

bad unless lisp_print(bless [3, 4], "Lisp::Cons") eq "(3 . 4)";
ok;
