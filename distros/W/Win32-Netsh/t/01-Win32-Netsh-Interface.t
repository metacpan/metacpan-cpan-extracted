##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 01-Win32-Netsh-Interface.t
## Description: Test script for Win32::Netsh::Interface
##----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More 0.88;

BEGIN {
  require Test::More;
  
  unless ($^O eq qq{MSWin32})
  {
    Test::More::plan(skip_all => 'Win32::Netsh::Interface is for MSWin32 only');
  }
}

use Win32::Netsh::Interface qw(:all);

## Get a list of all interfaces
my $interfaces = interface_info_all();

## Make sure an ARRAY reference was returned
is(ref($interfaces), qq{ARRAY}, qq{interface_info_all() returns ARRAY refernce});

## Test indvidual interface  
SKIP:
{
  ## shift off the first interface
  my $interface = shift(@{$interfaces});
  
  ## Skip tests if no interface was found
  skip(qq{No interface returned}, 4) unless ($interface);
  
  ## Make sure a hash reference was shifted from the array
  is(ref($interface), qq{HASH}, qq{Interfaces is a list of hashes});
  
  ## Make sure the "name" key exists
  ok(exists($interface->{name}), qq{Interface name exists});
  
  ## Save the name to use for testing interface_info()
  my $name = $interface->{name};
  
  my $info = interface_info($name);
  
  ## Make sure interface_info() returned a hash
  is(ref($info), qq{HASH}, qq{interface_info("$name") returned a hash});
  
  ## Make sure this matches what interface_info_all() returned
  is_deeply($info, $interface, qq{interface_info() matches info from interface_info_all()});

}


done_testing;

__END__
