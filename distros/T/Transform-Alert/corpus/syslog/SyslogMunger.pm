package TestMunger;

my $cnt = 1;
sub munge {
   my ($class, $vars) = @_;
   
   $vars->{p}{message} =~ s/TransformAlert\[\d+\]:\s*//;
   
   # without this, syslogs would be 1:1 and constantly loop
   return $cnt++ % 10 ? $vars : undef;
}

1;
