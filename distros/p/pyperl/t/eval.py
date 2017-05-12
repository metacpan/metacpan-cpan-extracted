print "1..2"
import perl

perl.eval("""

Python::exec("
print 'ok 1'
n = 4
");

print "ok ", Python::eval("n/2"), "\n";

""")

