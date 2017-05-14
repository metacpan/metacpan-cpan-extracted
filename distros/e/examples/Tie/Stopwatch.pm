package Stopwatch;

sub TIESCALAR {
   my ($pkg) = @_;
   my $obj = time();  # $obj stores the time at last reset.
   return (bless \$obj, $pkg);
}

sub FETCH {
   my ($r_obj) = @_;
   # Return the time elapsed since it was last reset 
   return (time() - $$r_obj); 
}

sub STORE {
   my ($r_obj, $val) = @_;
   # Ignore the value. Any write to it is seen as a reset
   return ($$r_obj = time());
}

1;


package main;
if (!caller()) {
   # Test driver;
   tie $s1, 'Stopwatch';
   $s1 = 0;
   sleep(2);
   print $s1;
   $s1 = 0;
   sleep(5);
   print $s1;
}