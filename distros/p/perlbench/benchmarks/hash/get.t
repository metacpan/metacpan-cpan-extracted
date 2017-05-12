#!perl

# Name: Look up keys in a hash
# Require: 4
# Desc:
#


require 'benchlib.pl';

$i = "abc";
for (1..1000) {
    $hash{$i} = 1;
    $i++;
}
#print "keys %hash = ", int(keys %hash), "\n";

&runtest(10, <<'ENDTEST');

   $a = $hash{'abc'};
   $a = $hash{'abe'};
   $a = $hash{'abf'};
   $a = $hash{'abo'};
   $a = $hash{'abn'};

   $a = $hash{'abe'};
   $a = $hash{'abf'};
   $a = $hash{'abo'};
   $a = $hash{'abn'};

   $a = $hash{$a};
   $a = $hash{$a};
   $a = $hash{$a};
   $a = $hash{$a};

   $a = $hash{'abeabeabeabeabc'};
   $a = $hash{'abeabeabeabeabd'};
   $a = $hash{'abeabeabeabeaba'};
   $a = $hash{'abeabeabeabeabd'};

ENDTEST
