##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 02-Win32-Netsh-Wlan.t
## Description: Test script for Win32::Netsh::Wlan
##----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More 0.88;
use File::Basename qw(dirname fileparse basename);
use File::Spec;

BEGIN {
  require Test::More;
  
  unless ($^O eq qq{MSWin32})
  {
    Test::More::plan(skip_all => qq{Win32::Netsh::Wlan is for MSWin32 only});
  }
  
  require Win32::Netsh;
  unless (Win32::Netsh::netsh_context_found(qq{wlan}))
  {
    Test::More::plan(
      skip_all => qq{WLAN context not supported on this system.}
    );
  }
  
  use_ok(qq{Win32::Netsh::Wlan}, (qw(:all)));

}

##---------------------------------------
## List of profiles to use for testing
##---------------------------------------
my @test_profiles = (
  { filename => qq{win32-netsh-wlan-single.xml},
    info => {
      name => qq{Win32-Netsh-Wlan-Single},
      auth => qq{Open},
      cipher => qq{None},
      interface => qq{Wireless Network Connection},
      mode => qq{automatical},
      net_type => qq{Infrastructure},
      radio => qq{[ Any Radio Type ]},
      ssid => [qq{SSID-Single}],
      },
  },
  {
    filename => qq{win32-netsh-wlan-dual.xml},
    info => {
      name => qq{Win32-Netsh-Wlan-Dual},
      auth => qq{Open},
      cipher => qq{None},
      interface => qq{Wireless Network Connection},
      mode => qq{automatical},
      net_type => qq{Infrastructure},
      radio => qq{[ Any Radio Type ]},
      ssid => [
                 qq{SSID-Dual-01},
                 qq{SSID-Dual-02}
               ]
      },
  },
  );

##---------------------------------------
## Use the module
##---------------------------------------


##---------------------------------------
## Test wlan interface related calls
##---------------------------------------
## Get a list of all interfaces
my $interfaces = wlan_interface_info_all();

## Make sure an ARRAY reference was returned
is(ref($interfaces), qq{ARRAY}, qq{wlan_interface_info_all() returns ARRAY refernce});

## Test indvidual interface  
SKIP:
{
  ## shift off the first interface
  my $interface = shift(@{$interfaces});
  
  ## Skip tests if no interface was found
  skip(qq{No interface returned}, 4) unless ($interface);
  
  ## Make sure a hash reference was shifted from the array
  is(ref($interface), qq{HASH}, qq{Interface is a hash reference});
  
  ## Make sure the "name" key exists
  ok(exists($interface->{name}), qq{Interface name exists});
  
  ## Save the name to use for testing interface_info()
  my $name = $interface->{name};
  
  my $info = wlan_interface_info($name);
  
  ## Make sure interface_info() returned a hash
  is(ref($info), qq{HASH}, qq{wlan_interface_info("$name") returned a hash});
  
  ## Make sure this matches what interface_info_all() returned
  is_deeply($info, $interface, qq{wlan_interface_info() matches info from wlan_interface_info_all()});

}

##---------------------------------------
## Test wlan profile related calls
##---------------------------------------
## Add the profiles
foreach my $test_profile (@test_profiles)
{
  ## Build the filename
  my $filename = File::Spec->catfile(
      File::Spec->splitdir(dirname(__FILE__)), 
      qq{..},
      qq{xt},
      $test_profile->{filename}
      );
  ## Add the profile
  ok(
    wlan_profile_add($filename),
    qq{Adding profile "$test_profile->{filename}"}
  );
}

## Verify wlan_profile_info_all
my $all_profiles = wlan_profile_info_all();

## Make sure an ARRAY reference was returned
is(ref($all_profiles), qq{ARRAY}, qq{wlan_profile_info_all() returns ARRAY refernce});

## Test indvidual interface  
SKIP:
{
  ## shift off the first interface
  my $profile = shift(@{$all_profiles});
  
  ## Skip tests if no interface was found
  skip(qq{No profile returned}, 2) unless ($profile);
  
  ## Make sure a hash reference was shifted from the array
  is(ref($profile), qq{HASH}, qq{Profile is a hash reference});
  
  ## Make sure the "name" key exists
  ok(exists($profile->{name}), qq{Profile name exists});
}

## Test individual profile info
foreach my $test_profile (@test_profiles)
{
  my $profile = wlan_profile_info($test_profile->{info}->{name});
  
  ## Make sure a hash reference was shifted from the array
  is(ref($profile), qq{HASH}, qq{Profile is a hash reference});
  
  is_deeply(
    $profile, 
    $test_profile->{info},
    qq{Profile info for "$test_profile->{info}->{name}"}
    );
}

## Delete the profiles
foreach my $test_profile (@test_profiles)
{
  ## Delete the profile
  ok(
    wlan_profile_delete($test_profile->{info}->{name}), 
    qq{Deleting profile "$test_profile->{info}->{name}"}
  );
}


done_testing;

__END__
