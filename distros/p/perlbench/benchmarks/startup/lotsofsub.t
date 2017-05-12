#!perl

# Name: Compile a lots of subroutines (test speed of compiler)
# Require: 4
# Desc:
#

$file = "test-$$.pl";
open(FILE, ">$file") || die;

$nosub = 1000;
$sub   = "aaaaa";

print FILE "#!./perl\n\n";

while ($nosub--) {

   print FILE <<EOT;

#  This is a simple subroutine that does not do much.
#  And this is some more comment text

sub $sub {
EOT
   print FILE <<'EOT';
   local($foo, $bar) = @_;
   # some random code below (we are just testing compilation speed here)
   if ($foo =~ /^(\d\d\d\d)(\d\d)(\d\d)$/) {
       $foo = "$1-$2-$3";
       $bar = $foo;
       &foo($foo);
       $bar++;
       $bar++;
       while ($bar++ < 1000) {
          chop($foo);
       }
   }
   &bar($bar);
}

EOT
} continue {
   $sub++;
}

#print FILE qq(print "OK\n";);
print FILE "1;\n";

close(FILE);
#exit;

#
# Now we start testing
#

require 'benchlib.pl';

&runtest(0.0003, <<'ENDTEST');

    # print "$^X $file\n";
    system $^X, $file;

ENDTEST

unlink($file);

