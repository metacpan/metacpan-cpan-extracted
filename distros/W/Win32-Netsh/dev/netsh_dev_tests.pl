#!/usr/bin/perl -w
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: netsh_dev_tests.pl
## Description: Script for testing the various module interfaces
##----------------------------------------------------------------------------
## CHANGES:
##
##----------------------------------------------------------------------------
use strict;
use warnings;
## Cannot use Find::Bin because script may be invoked as an
## argument to another script, so instead we use __FILE__
use File::Basename qw(dirname fileparse basename);
use File::Spec;
## Add script directory
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)));
## Add script directory/lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{lib});
## Add script directory/../lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{..},
  qq{lib});
use Getopt::Long;
use Pod::Usage;
use Cwd qw(abs_path);
use Data::Dumper;
use Win32::Netsh::Wlan qq(:all);
use Win32::Netsh::Interface qq(:all);

##--------------------------------------------------------
## A list of all command line options
## For GetOptions the following parameter indicaters are used
##    = Required parameter
##    : Optional parameter
##    s String parameter
##    i Integer parameter
##    f Real number (float)
## If a paramer is not indicated, then a value of 1
## indicates the parameter was found on the command line
##--------------------------------------------------------
#<<<  perltidy - start ignoring
my @CommandLineOptions = (
  "help",
  "man",
  "debug+",
  "interface=s@",
  "enable-interface=s@",
  "list-ipv4!",
  "list-interface!",
  "list-wlan!",
  "list-profile!",
  "wlan=s@",
  "profile=s@",
  "add-profile=s@",
  "delete-profile=s@",
  "ipv4=s@",
  "connect=s",
  "disconnect!",
  
);
#>>>  perltidy - stop ignoring

##--------------------------------------------------------
## A hash to hold all default values for command line
## options
##--------------------------------------------------------
my %gOptions = (
  help               => 0,
  man                => 0,
  debug              => 0,
  'enable-interface' => [],
  interface          => [],
  ipv4               => [],
  wlan               => [],
  profile            => [],
  'add-profile'      => [],
  'delete-profile'   => [],
  'list-ipv4'        => 0,
  'list-interface'   => 0,
  'list-wlan'        => 0,
  'list-profile'     => 0,
  connect            => qq{},
  disconnect         => 0,
);

##----------------------------------------------------------------------------
##     @fn process_commandline($allow_extra_args)
##  @brief Process all the command line options
##  @param $allow_extra_args - If TRUE, leave any unrecognized arguments in
##            @ARGV. If FALSE, consider unrecognized arguements an error.
##            (DEFAULT: FALSE)
## @return NONE
##   @note
##----------------------------------------------------------------------------
sub process_commandline
{
  my $allow_extra_args = shift;

  ## Pass through un-handled options in @ARGV
  Getopt::Long::Configure("pass_through");
  GetOptions(\%gOptions, @CommandLineOptions);

  ## See if --man was on the command line
  if ($gOptions{man})
  {
    pod2usage(
      -input    => \*DATA,
      -message  => "\n",
      -exitval  => 1,
      -verbose  => 99,
      -sections => '.*',     ## ALL sections
    );
  }

  ## See if --help was on the command line
  display_usage_and_exit(qq{}) if ($gOptions{help});

  ## Determine the path to the script
  $gOptions{ScriptPath} = abs_path($0);
  $gOptions{ScriptPath} =~ s!/?[^/]*/*$!!x;
  $gOptions{ScriptPath} .= "/" if ($gOptions{ScriptPath} !~ /\/$/x);

  ## See if we are running in windows
  if ($^O =~ /^MSWin/x)
  {
    ## Set the value
    $gOptions{IsWindows} = 1;
    ## Get the 8.3 short name (eliminates spaces and quotes)
    $gOptions{ScriptPathShort} = Win32::GetShortPathName($gOptions{ScriptPath});
  }
  else
  {
    ## Set the value
    $gOptions{IsWindows} = 0;
    ## Non-windows OSes don't care about short names
    $gOptions{ScriptPathShort} = $gOptions{ScriptPath};
  }

  ## See if there were any unknown parameters on the command line
  if (@ARGV && !$allow_extra_args)
  {
    display_usage_and_exit("\n\nERROR: Invalid "
        . (scalar(@ARGV) > 1 ? "arguments" : "argument") . ":\n  "
        . join("\n  ", @ARGV)
        . "\n\n");
  }

  return;
}

##----------------------------------------------------------------------------
##     @fn display_usage_and_exit($message, $exitval)
##  @brief Display the usage with the given message and exit with the given
##         value
##  @param $message - Message to display. DEFAULT: ""
##  @param $exitval - Exit vaule DEFAULT: 1
## @return NONE
##   @note
##----------------------------------------------------------------------------
sub display_usage_and_exit
{
  my $message = shift // qq{};
  my $exitval = shift // 1;

  pod2usage(
    -input   => \*DATA,
    -message => $message,
    -exitval => $exitval,
    -verbose => 1,
  );

  return;
}

##----------------------------------------------------------------------------
##     @fn sort_keys($hash)
##  @brief Sort the keys of the given hash returning an array reference
##  @param $hash - Hash reference of hash whose keys should be sorted
## @return ARRAY reference with keys in the desired order
##   @note
##----------------------------------------------------------------------------
sub sort_keys
{
  my $hash = shift // {};
  my $order = [];

  ## Iterate through the keys
  foreach my $key (sort(keys(%{$hash})))
  {
    ## See if this is the "name" key
    if (uc($key) eq qq{NAME})
    {
      ## Place name at front of list
      unshift(@{$order}, $key);
    }
    else
    {
      ## Add key to the list
      push(@{$order}, $key);
    }
  }
  return ($order);
}

##----------------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------------
## Set STDOUT to autoflush
$| = 1;    ## no critic (RequireLocalizedPunctuationVars)

## Parse the command line
process_commandline();

## Set debug level
wlan_debug($gOptions{debug});
interface_debug($gOptions{debug});

## Sort keys by default
$Data::Dumper::Sortkeys = \&sort_keys;

##---------------------------------------------
## Wireless interfaces
##---------------------------------------------
if ($gOptions{'list-wlan'})
{
  my $wlan_interfaces = wlan_interface_info_all();
  unless ($gOptions{debug})
  {
    print(qq{Wireless interfaces...\n});
    print(Data::Dumper->Dump([$wlan_interfaces,], [qw(wlan_interfaces),]),
      qq{\n});
  }
}

##---------------------------------------------
## Individual interfaces
##---------------------------------------------
if (scalar(@{$gOptions{wlan}}))
{
  foreach my $interface (@{$gOptions{wlan}})
  {
    my $interface_info = wlan_interface_info($interface);
    unless ($gOptions{debug})
    {
      print(qq{Interface "$interface"\n});
      print(Data::Dumper->Dump([$interface_info,], [qw(interface_info),]),
        qq{\n});
    }
  }
}

##---------------------------------------------
## Wireless profiles
##---------------------------------------------
if ($gOptions{'list-profile'})
{
  my $wlan_profiles = wlan_profile_info_all();
  unless ($gOptions{debug})
  {
    print(qq{Wireless profiles...\n});
    print(Data::Dumper->Dump([$wlan_profiles,], [qw(wlan_profiles),]), qq{\n});
  }
}

##---------------------------------------------
## Add wireless profiles
##---------------------------------------------
if (scalar(@{$gOptions{'add-profile'}}))
{
  foreach my $filename (@{$gOptions{'add-profile'}})
  {
    print(qq{Adding profile from "$filename"...});
    if (wlan_profile_add($filename))
    {
      print(qq{DONE\n});
    }
    else
    {
      print(qq{ERROR: }, wlan_last_error(), qq{\n});
    }
  }
}

##---------------------------------------------
## Connect to a wireless profile
##---------------------------------------------
if ($gOptions{connect})
{
  print(qq{Connecting to wireless profile "$gOptions{connect}"...});
  if (wlan_connect($gOptions{connect}))
  {
    print(qq{DONE\n});
  }
  else
  {
    print(qq{ERROR: }, wlan_last_error(), qq{\n});
  }
}

##---------------------------------------------
## Disconnect from wireless
##---------------------------------------------
if ($gOptions{disconnect})
{
  print(qq{Disconnecting wireless...});
  wlan_disconnect();
  print(qq{ DONE\n});
}


##---------------------------------------------
## Delete wireless profiles
##---------------------------------------------
if (scalar(@{$gOptions{'delete-profile'}}))
{
  foreach my $name (@{$gOptions{'delete-profile'}})
  {
    print(qq{Deleting profile "$name"...});
    if (wlan_profile_delete($name))
    {
      print(qq{DONE\n});
    }
    else
    {
      print(qq{ERROR: }, wlan_last_error(), qq{\n});
    }
  }
}

##---------------------------------------------
## All IPV4 interfaces
##---------------------------------------------
if ($gOptions{'list-ipv4'})
{
  my $ipv4_interfaces = interface_ipv4_info_all();
  unless ($gOptions{debug})
  {
    print(qq{IPv4 interfaces...\n});
    print(Data::Dumper->Dump([$ipv4_interfaces,], [qw(ipv4_interfaces),]),
      qq{\n});
  }
}

##---------------------------------------------
## Individual IPV4 interfaces
##---------------------------------------------
if (scalar(@{$gOptions{ipv4}}))
{
  foreach my $ipv4 (@{$gOptions{ipv4}})
  {
    my $ipv4_info = interface_ipv4_info($ipv4);
    unless ($gOptions{debug})
    {
      print(qq{IPV4 Interface "$ipv4"\n});
      print(Data::Dumper->Dump([$ipv4_info,], [qw(ipv4_info),]), qq{\n});
    }
  }
}

##---------------------------------------------
## All interfaces
##---------------------------------------------
if ($gOptions{'list-interface'})
{
  my $interfaces = interface_info_all();
  unless ($gOptions{debug})
  {
    print(qq{Interfaces...\n});
    print(Data::Dumper->Dump([$interfaces,], [qw(interfaces),]), qq{\n});
  }
}

##---------------------------------------------
## Individual interfaces
##---------------------------------------------
if (scalar(@{$gOptions{interface}}))
{
  foreach my $interface (@{$gOptions{interface}})
  {
    my $interface_info = interface_ipv4_info($interface);
    unless ($gOptions{debug})
    {
      print(qq{Interface "$interface"\n});
      print(Data::Dumper->Dump([$interface_info,], [qw(interface_info),]),
        qq{\n});
    }
  }
}

##---------------------------------------------
## Interface control
##---------------------------------------------
if (scalar(@{$gOptions{'enable-interface'}}))
{
  foreach my $interface (@{$gOptions{'enable-interface'}})
  {
    print(qq{Enabling "$interface"...});
    if (interface_enable($interface, 1))
    {
      print(qq{ DONE!\n});
    }
    else
    {
      print(qq{ERROR: }, interface_last_error(), qq{\n});
    }
  }
}

__END__

__DATA__

##----------------------------------------------------------------------------
## By placing the POD in the DATA section, we can use
##   pod2usage(input => \*DATA)
## even if the script is compiled using PerlApp, perl2exe or Perl::PAR
##----------------------------------------------------------------------------

=head1 NAME

netsh_dev_tests.pl - Script to exercise various functions in the Win32::Netsh
family of modules

=head1 SYNOPSIS

B<netsh_dev_tests.pl> {B<--help>}
{B<--list-interface>} 
{B<--interface> I<InterfaceName>}
{B<--enable-interface> I<InterfaceName>}
{B<--list-ipv4>} 
{B<--ipv4> I<InterfaceName>}
{B<--list-wlan>}
{B<--wlan> I<InterfaceName>}
{B<--list-profile>}
{B<--add-profile> I<WirelessProfileFilename>}
{B<--delete-profile> I<WirelessProfileName>}
{B<--connect> I<WirelessProfileName>}
{B<--disconnect>}
  
=head1 OPTIONS

=over 4

=item B<--list-interface>

List all the network interfaces

=item B<--interface> I<InterfaceName>

List interface details about the specified interface. 

Multiple --interface parameters can be provided

=item B<--enable-interface> I<InterfaceName>

Enable the specified specified interface. 

Multiple --enable-interface parameters can be provided

=item B<--list-ipv4>

List details about all the IPv4 connections

=item B<--ipv4> I<InterfaceName>

List IPv4 details about the specified interface. 

Multiple --ipv4 parameters can be provided

=item B<--list-wlan>

List details about all wireless interfaces

=item B<--wlan> I<InterfaceName>

List details about the specified wireless interface

Multiple --wlan parameters can be provided

=item B<--list-profile>

List details about all wireless profiles

=item B<--add-profile> I<WirelessProfileFilename>

Add the wireless profile using the wireless profile filename 

Multiple --add-profile parameters can be provided

=item B<--delete-profile> I<WirelessProfileName>

Delete the specified wireless profile 

Multiple --delete-profile parameters can be provided

=item B<--connect> I<WirelessProfileName>

Connect to the specified wireless profile 

=item B<--disconnect>

Disconnect any wireless connection 

=item B<--help>

Display basic help.

=item B<--man>

Display more detailed help.

=back

=head1 DESCRIPTION

The netsh_dev_tests.pl script is used to exercise various functions in the 
Win32::Netsh family of modules.

=cut

