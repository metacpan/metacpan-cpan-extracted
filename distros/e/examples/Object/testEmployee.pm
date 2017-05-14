use Employee;
use Benchmark;

package HashEmp;
sub new {
   bless {name => 'ram', age => 23};
}
sub age {
   $_[0]->{age};
}

package main;
$o  = Employee->new(name => "ram", age => 32);
$o1 = HashEmp->new();
print $o->age, " ", $o1->{age},"\n";

# Measure speed of accessors for  objects built using ObjectTemplate
# and an ordinary hash
timethese (100000,
   {"Employee", '$x = $o->age',
    "HashEmp" , '$x = $o1->age'
   }
);
