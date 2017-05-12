##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 00-Win32-Netsh.t
## Description: Test script for Win32::Netsh
##----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More 0.88;

BEGIN {
  require Test::More;
  
  unless ($^O eq qq{MSWin32})
  {
    Test::More::plan(
      skip_all => qq{Win32::Netsh::Interface is for MSWin32 only}
    );
  }
  
}

use Win32::Netsh;

## Make sure we can find the netsh command
my $passing = can_netsh();

ok($passing, qq{Netsh command found});

unless ($passing)
{
  my $path = netsh_path();
  BAIL_OUT(qq{Cannot locate netsh at "$path"});
}

done_testing;

__END__
