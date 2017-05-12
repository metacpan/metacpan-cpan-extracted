print "1..9\n";

use Lisp::Reader  qw(lisp_read);
use Lisp::Printer qw(lisp_print);
use Lisp::Symbol  qw(symbolp symbol);
use Lisp::Cons    qw(consp);
use Lisp::Vector  qw(vectorp);

$form = lisp_read("a b (a b)");

print "not " unless @$form == 3 &&
                    symbolp($form->[0]) &&
                    $form->[0]->name eq "a" &&
                    symbolp($form->[1]) &&
                    $form->[1]->name eq "b" &&
                    !symbolp($form->[2]) &&
                    symbolp($form->[2][0]) &&
                    $form->[2][0]->name eq "a";
print "ok 1\n";

print lisp_print($form), "\n";
print "not " unless lisp_print($form) eq "(a b (a b))";
print "ok 2\n";

$form = lisp_read('10.10.10 +10.10 1e2 -.2E-3 10 \10 ;comment');
print "not " unless @$form == 6 &&
                    symbolp($form->[0]) &&
	            $form->[0]->name eq "10.10.10" &&
                    abs($form->[1] - 10.10)  < 0.000001 &&
                    abs($form->[2] - 100.0)  < 0.000001 &&
                    abs($form->[3] + 0.0002) < 0.000001 &&
                    $form->[4] == 10 &&
	            symbolp($form->[5]) && 
                    $form->[5]->name eq "10";
print "ok 3\n";


$form = lisp_read("(a . b)");
print "not " unless consp($form) &&
                    consp($form->[0]) &&
                    $form->[0]->car == symbol("a") &&
                    $form->[0]->cdr == symbol("b");
print "ok 4\n";

#print Lisp::Printer::dump($form);

$form = lisp_read(<<'EOT');
;
; Comment
;
a
b ; comment
(c ;comment
 d
)

"string ; not a \"comment\""

symbol-with-\;-semicolon-and-\ -space-and-\(\)

EOT

#$Lisp::Reader::DEBUG++;
#print Lisp::Printer::dump($form);

print "not " unless @$form == 5 &&
                    symbolp($form->[0]) &&
                    symbolp($form->[1]) &&
                    consp($form->[2]) &&
	            $form->[3] eq 'string ; not a "comment"' &&
                    symbolp($form->[4]) &&
		    $form->[4]->name eq "symbol-with-;-semicolon-and- -space-and-()";
print "ok 5\n";


eval {
   lisp_read("a #<foo>");
};
print "not " unless $@ =~ /^invalid-read-syntax/;
print "ok 6\n";

my $q = symbol("quote");

$form = lisp_read(q('a '(a b (c)) '\a '?a '10));
print lisp_print($form), "\n";
print "not " unless @$form == 5 &&
                    consp($form->[0]) && $form->[0][0] == $q &&
                    consp($form->[1]) && $form->[1][0] == $q &&
                    consp($form->[2]) && $form->[2][0] == $q &&
                    consp($form->[3]) && $form->[3][0] == $q &&
                    consp($form->[4]) && $form->[4][0] == $q &&
                    $form->[0][1] == symbol("a") &&
	            consp($form->[1][1]) && @{$form->[1][1]} == 3 &&
		    $form->[2][1] == symbol("a") &&
		    $form->[3][1] == ord("a") &&
		    $form->[4][1] == 10;
print "ok 7\n";

$form = lisp_read(q([a b [a (b c)] (a b)]));
print lisp_print($form), "\n";
print "not " unless @$form == 1 &&
                    vectorp($form->[0]) &&
                    @{$form->[0]} == 4;
print "ok 8\n";

$form = lisp_read(q(?a ?\a ?\r ?\n ?x ?\x ?\C-m ?\C-M ?\^m ?\^M ?\015
                    "f\M-erep\370lse" "fo\
o" ?\M-\H-\C-X
                   ));
print lisp_print($form), "\n";
print "not " unless $form->[0] == 97 &&
                    $form->[1] == 7 &&
                    $form->[2] == 13 &&
                    $form->[3] == 10 &&
                    $form->[4] == 120 &&
                    $form->[5] == 120 &&
                    $form->[6] == 13 &&
                    $form->[7] == 13 &&
                    $form->[8] == 13 &&
                    $form->[9] == 13 &&
                    $form->[10] == 13 &&
	            $form->[11] eq "fårepølse" &&
	            $form->[12] eq "foo" &&
                    1;
print "ok 9\n";
