use strict;
use Test::More;

use WebGPU::Direct;

my %bypass = (
  BindGroupEntry => 1,
);

foreach my $name ( sort keys %WebGPU::Direct:: )
{
  next
      if $name !~ m/^[[:upper:]]/xms;

  my $fn = WebGPU::Direct->can("new$name");
  next
      if !$fn;

  next
      if $bypass{$name};

  local $@;
  my $obj = eval { WebGPU::Direct->$fn };
  isnt( $obj, undef, "Was able to get a new $name object" ) || diag( explain $@);

  # Temporarily ignore the DESTORY function, in case it has an error
  my $destroy = eval "\\*WebGPU::Direct::$name\::DESTROY";
  local *$destroy = sub {};
  eval { undef $obj };

  #diag(explain $obj);
}

done_testing;
