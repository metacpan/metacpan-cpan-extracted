
# Using typeglob representation for objects
#
package File;
use Symbol;
sub open {
   my ($pkg, $filename) = @_;
   $obj = gensym();
   open ($obj, $filename) || die "$!";
   bless $obj, $pkg;
}

sub put_back {
   my ($r_obj, $line) = @_;
   ${*$r_obj} = $line;
}

sub next_line {
   my ($r_obj) = @_;
   if (${*$r_obj}) {
       $retval = ${*$r_obj};
       ${*$r_obj} = "";
   } else {
       $retval = <$r_obj>;
   }
   $retval;
}
sub DESTROY {
  print "DESTROY called \n";
}
1;
package main;
$obj = File->open("typeglob.pm");
print $obj->next_line();
$obj->put_back("------------------------\n");
print $obj->next_line();
print $obj->next_line();
