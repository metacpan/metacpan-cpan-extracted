#----------------------------------------------------------------------
package Monitor;
#----------------------------------------------------------------------
# 
# This package monitors accesses to variables like this:
#   monitor (\$x, "x");
# Now, if you access $x, a trace message will be printed
#

require Exporter;
@ISA = ("Exporter");
@EXPORT = qw(monitor unmonitor);

use strict;


sub monitor {
   my ($r_var, $name) = @_;
   my ($type) = ref($r_var);
   if ($type =~ /SCALAR/) {
       return tie $$r_var, 'Monitor::Scalar', $r_var, $name;
   } elsif ($type =~ /ARRAY/) {
       return tie @$r_var, 'Monitor::Array', $r_var, $name;
   } elsif ($type =~ /HASH/) {
       return tie %$r_var, 'Monitor::Hash', $r_var, $name;
   } else {
       print STDERR "require ref. to scalar, array or hash" unless $type;
   }
}
sub unmonitor {
   my ($r_var) = @_;
   my ($type) = ref($r_var);
   my $obj;
   if ($type =~ /SCALAR/) {
       Monitor::Scalar->unmonitor($r_var);
   } elsif ($type =~ /ARRAY/) {
       Monitor::Array->unmonitor($r_var);
   } elsif ($type =~ /HASH/) {
       Monitor::Hash->unmonitor($r_var);
   } else {
       print STDERR "require ref. to scalar, array or hash" unless $type;
   } 
}

#------------------------------------------------------------------------
# Internal functions

package Monitor::Scalar;
sub TIESCALAR {
   my ($pkg, $rval, $name) = @_;
   my $obj = [$name, $$rval];
   bless $obj, $pkg;
   return $obj;
}

sub FETCH {
   my ($obj) = @_;
   my $val = $obj->[1];
   print STDERR 'Read    $', $obj->[0], " ... $val \n";
   return $val;
}
sub STORE {
   my ($obj, $val) = @_;
   print STDERR 'Wrote   $', $obj->[0], " ... $val \n";
   $obj->[1] = $val;
   return $val;
}

sub unmonitor {
   my ($pkg, $r_var) = @_;
   my $val;
   {
      my $obj = tied $$r_var;
      $val = $obj->[1];
      $obj->[0] = "_UNMONITORED_";
   }
   untie $$r_var;
   $$r_var = $val;
}

sub DESTROY {
   my ($obj) = @_;
   if ($obj->[0] ne '_UNMONITORED_') {
      print STDERR 'Died    $', $obj->[0];
   }
}

package Monitor::Array;

sub TIEARRAY {
   my ($pkg, $rarray, $name) = @_;
   my $obj = [$name, [@$rarray]];
   bless $obj, $pkg;
   return $obj;
}

sub FETCH {
   my ($obj, $index) = @_;
   my $val = $obj->[1]->[$index];
   print STDERR 'Read    $', $obj->[0], "[$index] ... $val\n";
   return $val;
}

sub STORE {
   my ($obj, $index, $val) = @_;
   print STDERR 'Wrote   $', $obj->[0], "[$index] ... $val\n";
   $obj->[1]->[$index] = $val;
   return $val;
}


sub DESTROY {
   my ($obj) = @_;
   if ($obj->[0] ne '_UNMONITORED_') {
      print STDERR 'Died    %', $obj->[0];
   }
}

sub unmonitor {
   my ($pkg, $r_var) = @_;
   my $r_array;
   {
      my $obj = tied @$r_var;
      $r_array = $obj->[1];
      $obj->[0] = "_UNMONITORED_";
   }
   untie @$r_var;
   @$r_var = @$r_array;
   
}

package Monitor::Hash;
sub TIEHASH {
   my ($pkg, $rhash, $name) = @_;
   my $obj = [$name, {%$rhash}];
   return (bless $obj, $pkg);
}

sub CLEAR {
   my ($obj) = @_;
   print STDERR 'Cleared %', $obj->[0], "\n";
}

sub FETCH {
   my ($obj, $index) = @_;
   my $val = $obj->[1]->{$index};
   print STDERR 'Read    $', $obj->[0], "{$index} ... $val\n";
   return $val;
}

sub STORE {
   my ($obj, $index, $val) = @_;
   print STDERR 'Wrote   $', $obj->[0], "{$index} ... $val\n";
   $obj->[1]->{$index} = $val;
   return $val;
}

sub DESTROY {
   my ($obj) = @_;
   if ($obj->[0] ne '_UNMONITORED_') {
      print STDERR 'Died    %', $obj->[0];
   }
}
sub unmonitor {
   my ($pkg, $r_var) = @_;
   my $r_hash;
   {
      my $obj = tied %$r_var;
      $r_hash = $obj->[1];
      $obj->[0] = "_UNMONITORED_";
   }
   untie %$r_var;
   %$r_var = %$r_hash;
}

if (!caller) {
   #TEST DRIVER : To test this package, invoke as "perl Monitor.pm"

   package main;

   print "TESTING Scalar Monitor\n\n";
   my $x;  my $a;
   Monitor::monitor (\$x, "x");
   $x = 10;
   $a = $x;
   Monitor::unmonitor(\$x);
   print "\$x ===> $x\n";
   
   print "\nTESTING Array Monitor\n\n";
   my @x = (1, 2, 3);
   Monitor::monitor (\@x, "x");
   $x [3] = 100;
   Monitor::unmonitor(\@x);
   print "\@x ===> @x\n";
 
   print "\nTESTING Hash Monitor\n\n";
   my %x ;
   Monitor::monitor (\%x, "hash");
   $x{"India"} = "N. Delhi";
   $x{"USA"} = "Washington";
   Monitor::unmonitor(\%x);
   $, = " ";
   print "\%x ===> ", %x, "\n";
}

1;
