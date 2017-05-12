package Win32::Netsh::Wlan;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Win32::Netsh::Wlan - Provide functions in that correlate to the Microsoft 
Windows netsh utility's wlan context

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  use Win32::Netsh::Wlan qw(wlan_interface_info_all);
  
  my @wireless_if = wlan_interface_info_all();

=cut

##****************************************************************************
##****************************************************************************
use strict;
use warnings;
use 5.010;
use Readonly;
use Win32::Netsh;
use Win32::Netsh::Utils qw(:all);
use Data::Dumper;
use Exporter::Easy (
  EXPORT => [],
  OK     => [
    qw(
      wlan_connect
      wlan_disconnect
      wlan_interface_info_all
      wlan_interface_info
      wlan_profile_info_all
      wlan_profile_info
      wlan_debug
      )
  ],
  TAGS => [
    connect => [qw(wlan_connect wlan_disconnect),],
    debug   => [qw(wlan_debug),],
    profile => [
      qw(
        wlan_profile_info_all
        wlan_profile_info
        wlan_profile_add
        wlan_profile_delete
        )
    ],
    interface => [qw(wlan_interface_info_all wlan_interface_info)],
    all       => [qw(wlan_last_error :debug :connect :profile :interface),],
  ],
);

## Version string
our $VERSION = qq{0.02};

my $debug = 0;

my $wlan_error = qq{};
##-------------------------------------------------
##-------------------------------------------------
Readonly::Scalar my $WLAN_IF_KEY_LOOKUP => {
  qq{Name}                 => qq{name},
  qq{Description}          => qq{description},
  qq{GUID}                 => qq{guid},
  qq{Physical address}     => qq{mac_address},
  qq{State}                => qq{state},
  qq{SSID}                 => qq{ssid},
  qq{BSSID}                => qq{bssid},
  qq{Network type}         => qq{net_type},
  qq{Radio type}           => qq{radio},
  qq{Authentication}       => qq{auth},
  qq{Cipher}               => qq{cipher},
  qq{Connection mode}      => qq{mode},
  qq{Channel}              => qq{channel},
  qq{Receive rate (Mbps)}  => qq{rx_rate},
  qq{Transmit rate (Mbps)} => qq{tx_rate},
  qq{Signal}               => qq{signal},
};

Readonly::Scalar my $WLAN_PROFILE_KEY_LOOKUP => {
  qq{Name}            => qq{name},
  qq{Network type}    => qq{net_type},
  qq{Radio type}      => qq{radio},
  qq{Authentication}  => qq{auth},
  qq{Cipher}          => qq{cipher},
  qq{Connection mode} => qq{mode},
  qq{SSID name}       => qq{ssid},
  qq{SSID names}      => qq{ssid},
};

##****************************************************************************
## Functions
##****************************************************************************

=head1 FUNCTIONS

=cut

##****************************************************************************
##****************************************************************************

=head2 wlan_debug($level)

=over 2

=item B<Description>

Set the debug level for the module

=item B<Parameters>

$level - Debug level

=item B<Return>

SCALAR - Current debug level

=back

=cut

##----------------------------------------------------------------------------
sub wlan_debug
{
  my $level = shift;

  $debug = $level if (defined($level));

  return ($debug);
}

##****************************************************************************
##****************************************************************************

=head2 wlan_interface_info_all()

=over 2

=item B<Description>

Return a reference to a list of hashes that describe the wireless interfaces
available

=item B<Parameters>

NONE

=item B<Return>

ARRAY reference of hash references whose keys are as follows:

=over 4

=item I<name>

Name of the interface

=item I<description>

Description of the interface

=item I<guid>

GUID associated with the interface

=item I<mac_address>

IEEE MAC address of the interfaces as a string
with the format "xx:xx:xx:xx:xx:xx" where xx is a
hexadecimal number between 00 and ff

=item I<state>

Disconnected, discovering, or connected

=item I<ssid >

SSID of connected wireless network

=item I<bssid>

IEEE MAC address of the associated accees point as 
a string with the format "xx:xx:xx:xx:xx:xx" where xx
is a hexadecimal number between 00 and ff

=item I<net_type>

String indicating "Infrastructure" or "Ad hoc" mode for the connection

=item I<radio>

String indicating if connection is 802.11b 802.11n etc.

=item I<auth>

String indicating the type of authentication for the connection

=item I<cipher>

String indicating the cypher type

=item I<mode>

String indicating connection mode

=item I<channel>

RF channel used for connection

=item I<rx_rate>

Receive rate in Mbps

=item I<tx_rate>

Receive rate in Mbps

=item I<signal>

Signal strength as a percentage

=back

=back

=cut

##----------------------------------------------------------------------------
sub wlan_interface_info_all
{
  my $interfaces = [];
  my $interface;

  print(qq{wlan_interface_info_all()\n}) if ($debug);

  my $command  = qq{wlan show interface};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  foreach my $line (split(qq{\n}, $response))
  {
    print(qq{LINE: [$line]\n}) if ($debug);

    if ($line =~ /\A\s+ ([^:]+) \s+ : \s+ (.*)\Z/x)
    {
      my $text  = str_trim($1);
      my $value = str_trim($2);
      print(qq{  TEXT:  [$text]\n  VALUE: [$value]\n}) if ($debug);

      if (my $key = get_key_from_lookup($text, $WLAN_IF_KEY_LOOKUP))
      {
        ## See if this is the name key
        if ($key eq qq{name})
        {
          ## If an interface is defined, push it onto the list
          push(@{$interfaces}, $interface) if (defined($interface));
          ## Initialize the interface ahsh
          $interface = initialize_hash_from_lookup($WLAN_IF_KEY_LOOKUP);
        }

        ## Store the value in the hash
        $interface->{$key} = $value;
      }
    }
  }

  ## If an interface is defined, push it onto the list
  push(@{$interfaces}, $interface) if (defined($interface));

  if ($debug >= 2)
  {
    print(Data::Dumper->Dump([$interfaces,], [qw(interfaces),]), qq{\n});
  }
  return ($interfaces);
}

##****************************************************************************
##****************************************************************************

=head2 wlan_interface_info($name)

=over 2

=item B<Description>

Return a reference to a hash that describes the wireless interface

=item B<Parameters>

=over 4

=item I<$name>

Name of the interface such as "Wireless Network Connection"

=back

=item B<Return>

=over 4

=item I<UNDEF>

Indicates the named interface could not be found

=item I<HASH reference>

Hash reference whose keys are as follows:

=over 6

=item I<name>

Name of the interface

=item I<description>

Description of the interface

=item I<guid>

GUID associated with the interface

=item I<mac_address>

IEEE MAC address of the interfaces as a string
with the format "xx:xx:xx:xx:xx:xx" where xx is a
hexadecimal number between 00 and ff

=item I<state>

Disconnected, discovering, or connected

=item I<ssid >

SSID of connected wireless network

=item I<bssid>

IEEE MAC address of the associated accees point as 
a string with the format "xx:xx:xx:xx:xx:xx" where xx
is a hexadecimal number between 00 and ff

=item I<net_type>

String indicating "Infrastructure" or "Ad hoc" mode for the connection

=item I<radio>

String indicating if connection is 802.11b 802.11n etc.

=item I<auth>

String indicating the type of authentication for the connection

=item I<cipher>

String indicating the cypher type

=item I<mode>

String indicating connection mode

=item I<channel>

RF channel used for connection

=item I<rx_rate>

Receive rate in Mbps

=item I<tx_rate>

Receive rate in Mbps

=item I<signal>

Signal strength as a percentage

=back

=back

=back

=cut

##----------------------------------------------------------------------------
sub wlan_interface_info
{
  my $name = shift;

  print(qq{wlan_interface_info("$name")\n}) if ($debug);

  ## Make sure a name was provided
  unless ($name)
  {
    ## Set the module error message
    $wlan_error = qq{No name provided!};
    print($wlan_error, qq{\n}) if ($debug >= 2);
    return;
  }

  ## Reset the module error message
  $wlan_error = qq{};

  foreach my $interface (@{wlan_interface_info_all()})
  {
    if (uc($name) eq uc($interface->{name}))
    {
      if ($debug >= 2)
      {
        print(Data::Dumper->Dump([$interface,], [qw(interface),]), qq{\n});
      }
      return ($interface);
    }
  }

  ## Set the module error message
  $wlan_error = qq{Could locate wireless interface "$name"};
  print($wlan_error, qq{\n}) if ($debug >= 2);
  return;

}

##****************************************************************************
##****************************************************************************

=head2 wlan_profile_info($name)

=over 2

=item B<Description>

Return a hash reference with details of the given profile name

=item B<Parameters>

=over 4

=item I<$name>

Name of the profile

=back

=item B<Return>

=over 4

=item I<UNDEF>

Indicates profile not found

=item I<HASH Reference>

Hash reference whose keys are as follows:

=over 6

=item I<name>

Name of the profile

=item I<interface>

Name of the interface

=item I<ssid>

Array reference to the list of SSIDs of the wireless network

=item I<net_type>

String indicating "Infrastructure" or "Ad hoc" mode for the connection

=item I<radio>

String indicating if connection is 802.11b 802.11n etc.

=item I<auth>

String indicating the type of authentication for the connection

=item I<cipher>
String indicating the cypher type

=item I<mode>
String indicating connection mode

=back

=back

=back

=cut

##----------------------------------------------------------------------------
sub wlan_profile_info
{
  my $name = shift // qq{};

  print(qq{wlan_profile_info("$name")\n}) if ($debug);

  ## Make sure a name was provided
  unless ($name)
  {
    ## Set the module error message
    $wlan_error = qq{No name provided!};
    print($wlan_error, qq{\n}) if ($debug >= 2);
    return;
  }

  my $command  = qq{wlan show profile name="$name"};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  my $lines = [split(qq{\n}, $response)];

  return (_parse_profile_info($lines));
}

##****************************************************************************
##****************************************************************************

=head2 wlan_profile_info_all()

=over 2

=item B<Description>

Return an array reference of hash references with details of the profiles

=item B<Parameters>

NONE

=item B<Return>

ARRAY reference of hash references corresponding to each profile. Each hash
reference has the following keys:

=over 4

=item I<name>

Name of the profile

=item I<interface>

Name of the interface

=item I<ssid>

Array reference to the list of SSIDs of the wireless network

=item I<net_type>

String indicating "Infrastructure" or "Ad hoc" mode for the connection

=item I<radio>

String indicating if connection is 802.11b 802.11n etc.

=item I<auth>

String indicating the type of authentication for the connection

=item I<cipher>
String indicating the cypher type

=item I<mode>
String indicating connection mode

=back

=back

=cut

##----------------------------------------------------------------------------
sub wlan_profile_info_all
{
  my $list     = [];
  my $command  = qq{wlan show profile name="*"};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  my $lines = [split(qq{\n}, $response)];

  while (my $info = _parse_profile_info($lines))
  {
    push(@{$list}, $info);
  }

  if ($debug >= 2)
  {
    print(Data::Dumper->Dump([$list,], [qw(all),]), qq{\n});
  }
  return ($list);
}

##----------------------------------------------------------------------------
##     @fn _parse_profile_info($lines)
##  @brief Parse the reponse lines and return a wireless profile info hash
##         reference
##  @param $lines - Array reference to linse of response data
## @return HASH reference with the following keys:
##         name      - Name of the profile
##         interface - Name of the interface
##         ssid      - SSID of the wireless network
##         net_type  - String indicating "Infrastructure" or "Ad hoc" mode
##                     for the connection
##         radio     - String indicating if connection is 802.11b 802.11n etc.
##         auth      - String indicating the type of authentication for the
##                     connection
##         cipher    - String indicating the cypher type
##         mode      - String indicating connection mode
##   @note
##----------------------------------------------------------------------------
sub _parse_profile_info
{
  my $lines = shift // [];
  my $info;
  my $last_key = qq{};

  print(qq{_parse_profile_info()\n}) if ($debug);
  print(Data::Dumper->Dump([$lines,], [qw(lines),]), qq{\n}) if ($debug >= 2);

PROFILE_INFO_PARSE_LOOP:
  while (1)
  {
    my $line = shift(@{$lines});
    last PROFILE_INFO_PARSE_LOOP unless (defined($line));
    print(qq{LINE: [$line]\n}) if ($debug);
    if ($line =~ /Profile \s (.*) \s on \s interface \s (.*) :/x)
    {
      ## See if we already have a hash defined
      if (defined($info))
      {
        ## Put this line back on the list
        unshift(@{$lines}, $line);
        ## Stop parsing
        last PROFILE_INFO_PARSE_LOOP;
      }

      ## Initialize the hash
      print(qq{  INITIALIZING HASH\n}) if ($debug);
      $info = initialize_hash_from_lookup($WLAN_PROFILE_KEY_LOOKUP);
      $info->{ssid} = [];
      $info->{name} = $1;
      $info->{interface} = $2;
    }
    elsif ($line =~ /\A\s+ ([^:]+) \s *: \s+ (.*)\Z/x)
    {
      my $text  = str_trim($1);
      my $value = str_trim($2);
      print(qq{  + TEXT:  [$text]\n  + VALUE: [$value]\n}) if ($debug);
      if (my $key = get_key_from_lookup($text, $WLAN_PROFILE_KEY_LOOKUP))
      {
        print(qq{  + KEY:   [$key]\n}) if ($debug);
        ## Remove the enclosing " for the SSID
        $value = substr($value, 1, -1) if ($key eq qq{ssid});
        $value = substr($value, 8, -2) if ($key eq qq{mode});
        if (ref($info->{$key}) eq qq{ARRAY})
        {
          push(@{$info->{$key}}, $value);
        }
        else
        {
          $info->{$key} = $value;
        }
        $last_key = $key;
      }
    }
    elsif (($last_key eq qq{ssid}) and ($line =~ /"([^"]*)"/x))
    {
      my $ssid = $1;
      print(qq{  + VALUE: [$ssid]\n  + KEY:   [$last_key]\n}) if ($debug);
      push(@{$info->{$last_key}}, $ssid);
    }
  }

  if ($debug >= 2)
  {
    print(Data::Dumper->Dump([$info,], [qw(info),]), qq{\n});
  }
  return ($info);
}

##****************************************************************************
##****************************************************************************

=head2 wlan_profile_add($filename, $options)

=over 2

=item B<Description>

Add the given profile with the specified options. If no options are provided
then the profile will be added for all interfaces and all users

=item B<Parameters>

=over 4

=item I<$filename>

Filename of the XML file containing the wireless profiles

=item I<$options>

Optional hash reference with the following keys:

=over 6

=item interface

Name of the interface for the profile

=item user

User scope (all or current)

=back

=back 

=item B<Return>

UNDEF on error, or 1 for success

=back

=cut

##----------------------------------------------------------------------------
sub wlan_profile_add
{
  my $filename = shift // qq{};
  my $options  = shift // {};

  print(qq{wlan_profile_add("$filename")\n}) if ($debug);

  ## Make sure a name was provided
  unless ($filename)
  {
    ## Set the module error message
    $wlan_error = qq{No filename provided!};
    print($wlan_error, qq{\n}) if ($debug >= 2);
    return;
  }

  ## Reset the module error message
  $wlan_error = qq{};

  my $command = qq{wlan add profile filename="$filename"};
  $command .= qq{ user=$options->{user}}             if ($options->{user});
  $command .= qq{ interface="$options->{interface}"} if ($options->{interface});
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  return (1) if ($response =~ /\A Profile \s (.*) \s is \s added/x);

  ## Set the module error message
  $wlan_error = str_trim($response);
  print($wlan_error, qq{\n}) if ($debug >= 2);

  return;
}

##****************************************************************************
##****************************************************************************

=head2 wlan_profile_delete($name)

=over 2

=item B<Description>

Delete the specified profile if it exists

=item B<Parameters>

=over 4

=item I<$name>

Name of the profile to delete

=back

=item B<Return>

UNDEF on error, or 1 for success

=back

=cut

##----------------------------------------------------------------------------
sub wlan_profile_delete
{
  my $name = shift;

  print(qq{wlan_profile_delete("$name")\n}) if ($debug);

  ## Make sure a name was provided
  unless ($name)
  {
    ## Set the module error message
    $wlan_error = qq{No name provided!};
    print($wlan_error, qq{\n}) if ($debug >= 2);
    return;
  }

  ## Reset the module error message
  $wlan_error = qq{};

  my $command  = qq{wlan delete profile name="$name"};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  return (1) if ($response =~ /\A Profile \s "(.*)" \s is \s deleted/x);

  ## Set the module error message
  $wlan_error = str_trim($response);
  print($wlan_error, qq{\n}) if ($debug >= 2);

  return;
}

##****************************************************************************
##****************************************************************************

=head2 wlan_last_error()

=over 2

=item B<Description>

Return the error string associated with the last wlan command

=item B<Parameters>

NONE

=item B<Return>

SCALAR - error string

=back

=cut

##----------------------------------------------------------------------------
sub wlan_last_error
{
  return ($wlan_error);
}

##****************************************************************************
##****************************************************************************

=head2 wlan_connect($name)

=over 2

=item B<Description>

Connect to the wireless network specified in the named profile

=item B<Parameters>

=over 4

=item I<$name>

Name of the profile to use to connect.

=back

=item B<Return>

UNDEF on error, or 1 for success

=back

=cut

##----------------------------------------------------------------------------
sub wlan_connect
{
  my $name = shift // qq{};

  print(qq{wlan_connect("$name")\n}) if ($debug);

  ## Make sure a name was provided
  unless ($name)
  {
    ## Set the module error message
    $wlan_error = qq{No name provided!};
    print($wlan_error, qq{\n}) if ($debug >= 2);
    return;
  }

  ## Reset the module error message
  $wlan_error = qq{};

  my $command  = qq{wlan connect name="$name"};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  return (1) if ($response =~ /successfully/x);

  ## Set the module error message
  $wlan_error = str_trim($response);
  print($wlan_error, qq{\n}) if ($debug >= 2);

  return;
}

##****************************************************************************
##****************************************************************************

=head2 wlan_disconnect()

=over 2

=item B<Description>

Disconnect any current connection

=item B<Parameters>

=over 4

=item I<NONE>

=back

=item B<Return>

=over 4

=item I<NONE>

=back

=back

=cut

##----------------------------------------------------------------------------
sub wlan_disconnect
{
  print(qq{wlan_disconnect()\n}) if ($debug);

  ## Reset the module error message
  $wlan_error = qq{};

  my $command  = qq{wlan disconnect};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  return;
}


##****************************************************************************
## Additional POD documentation
##****************************************************************************

=head1 SEE ALSO

L<Win32::Netsh::Interface> for examining and controlling the netsh interface
context including interface ipv4.

=head1 AUTHOR

Paul Durden E<lt>alabamapaul AT gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 by Paul Durden.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    ## End of module
__END__
