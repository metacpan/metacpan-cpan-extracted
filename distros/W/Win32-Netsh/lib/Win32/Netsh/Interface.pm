package Win32::Netsh::Interface;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Win32::Netsh::Interface - Provide functions in that correlate to the Microsoft 
Windows netsh utility's interface context

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  use Win32::Netsh::Interface qw(interface_ipv4_info);
  
  my @ip_addresses = interface_ipv4_info(qq{Local Area Network});

=cut

##****************************************************************************
##****************************************************************************
use strict;
use warnings;
use 5.010;
use Readonly;
use Win32;
use Win32::Netsh;
use Win32::Netsh::Utils qw(:all);
use Data::Dumper;
use Exporter::Easy (
  EXPORT => [],
  OK     => [
    qw(interface_last_error interface_ipv4_info interface_ipv4_info_all interface_debug interface_info_all interface_info interface_enable)
  ],
  TAGS => [
    debug     => [qw(interface_debug),],
    interface => [qw(interface_info_all interface_info interface_enable)],
    ipv4      => [qw(interface_ipv4_info interface_ipv4_info_all)],
    all       => [qw(interface_last_error :debug :interface :ipv4),],
  ],
);

## Version string
our $VERSION = qq{0.02};

##-------------------------------------------------
## Module variables
##-------------------------------------------------
my $debug           = 0;
my $interface_error = qq{};

##-------------------------------------------------
## Lookup tables
##-------------------------------------------------
## Lookup table for interface ipv4 context
Readonly::Scalar my $IPV4_KEY_LOOKUP => {
  qq{DHCP enabled}    => qq{dhcp},
  qq{IP Address}      => qq{ip},
  qq{Subnet Prefix}   => qq{netmask},
  qq{Default Gateway} => qq{gateway},
  qq{Gateway Metric}  => qq{gw_metric},
  qq{InterfaceMetric} => qq{if_metric},
};

## Lookup table for interface context
Readonly::Scalar my $INTERFACE_KEY_LOOKUP => {
  qq{Type}                 => qq{type},
  qq{Administrative state} => qq{enabled},
  qq{Connect state}        => qq{state},
};

##****************************************************************************
## Functions
##****************************************************************************

=head1 FUNCTIONS

=cut

##****************************************************************************
##****************************************************************************

=head2 interface_debug($level)

=over 2

=item B<Description>

Set the debug level for the module

=item B<Parameters>

=over 4

=item I<$level>

Debug level

=back

=item B<Return>

=over 4

=item I<SCALAR>

Current debug level

=back

=back

=cut

##----------------------------------------------------------------------------
sub interface_debug
{
  my $level = shift;

  $debug = $level if (defined($level));

  return ($debug);
}

##----------------------------------------------------------------------------
##     @fn _netmask_add($info, $string)
##  @brief Parse the string and add the netmask to the given info hash
##  @param $info - Hash reference containing the netmask key
##  @paeam $string - String to parse
## @return NONE
##   @note
##----------------------------------------------------------------------------
sub _netmask_add
{
  my $info = shift;
  my $string = shift // qq{};

  if ($string =~ /\(mask (.*)\)/x)
  {
    if (my $mask = parse_ip_address($1))
    {
      push(@{$info->{netmask}}, $mask);
    }
  }

  return;
}

##----------------------------------------------------------------------------
##     @fn _parse_ipv4_response($lines)
##  @brief Parse the repsonse into an ipv4 info hash
##  @param $lines = Array reference of netsh response
## @return HASH reference or undef
##   @note
##----------------------------------------------------------------------------
sub _parse_ipv4_response
{
  my $lines = shift;
  my $info;

  print(qq{_parse_ipv4_response()\n}) if ($debug);
  print(Data::Dumper->Dump([$lines,], [qw(lines),]), qq{\n}) if ($debug >= 2);

IPV4_PARSE_LOOP:
  while (1)
  {
    my $line = shift(@{$lines});
    last IPV4_PARSE_LOOP unless (defined($line));
    print(qq{LINE: [$line]\n}) if ($debug);
    if (length($line) == 0)
    {
      ## This is a blank line

      ## If the info hash is defined, stop processing
      last IPV4_PARSE_LOOP if (defined($info));
    }
    elsif ($line =~ /Configuration \s+ for \s+ interface \s+ "(.*)"/x)
    {
      ## Initialize the hash
      $info            = initialize_hash_from_lookup($IPV4_KEY_LOOKUP);
      $info->{name}    = $1;
      $info->{ip}      = [];
      $info->{netmask} = [];
    }
    elsif ($line =~ /\A\s+ ([^:]+): \s+ (.*)\Z/x)
    {
      my $text  = str_trim($1);
      my $value = str_trim($2);
      print(qq{  TEXT:  [$text]\n  VALUE: [$value]\n}) if ($debug);

      if (my $key = get_key_from_lookup($text, $IPV4_KEY_LOOKUP))
      {
        if ($key eq qq{netmask})
        {
          _netmask_add($info, $value);
        }
        elsif ($key eq qq{ip})
        {
          if (my $ip = parse_ip_address($value))
          {
            push(@{$info->{ip}}, $ip);
          }
        }
        elsif ($key eq qq{gateway})
        {
          if (my $ip = parse_ip_address($value))
          {
            $info->{gateway} = $ip;
          }
        }
        else
        {
          $info->{$key} = $value;
        }
      }
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

=head2 interface_ipv4_info($name)

=over 2

=item B<Description>

Return a hash reference with the IPV4 information for the given interface

=item B<Parameters>

=over 4

=item I<$name>

Name of the interface

=back

=item B<Return>

=over 4

=item I<HASH reference>

HASH reference whose keys are as follows:

=over 6

=item I<name>

Name of the interface

=item I<dhcp>

Indicates if DHCP is enabled

=item I<ip>

Array reference containing IP addresses for the interface

=item I<netmask>

Array reference containing netmasks for the interface

=item I<gateway>

IP address of the default gateway for the interface

=item I<gw_metric>

Gateway metric

=item I<if_metric>

Interface metric

=back

=back

=back

=cut

##----------------------------------------------------------------------------
sub interface_ipv4_info
{
  my $name = shift // qq{};

  print(qq{interface_ipv4_info()\n}) if ($debug);

  my $command  = qq{interface ipv4 show addresses name="$name"};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  my $lines = [split(qq{\n}, $response)];

  return (_parse_ipv4_response($lines));
}

##****************************************************************************
##****************************************************************************

=head2 interface_ipv4_info_all()

=over 2

=item B<Description>

Return an array reference that contains hash reference with the IPV4 
information for each interface

=item B<Parameters>

NONE

=item B<Return>

=over 4

=item I<ARRAY reference>

Array reference to array of hash references whose keys are as follows:

=over 6

=item I<name>

Name of the interface

=item I<dhcp>

Indicates if DHCP is enabled

=item I<ip>

Array reference containing IP addresses for the interface

=item I<netmask>

Array reference containing netmasks for the interface

=item I<gateway>

IP address of the default gateway for the interface

=item I<gw_metric>

Gateway metric

=item I<if_metric>

Interface metric

=back

=back

=back

=cut

##----------------------------------------------------------------------------
sub interface_ipv4_info_all
{
  my $lines = [];
  my $all   = [];

  print(qq{interface_ipv4_info_all()\n}) if ($debug);

  my $command  = qq{interface ipv4 show addresses};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  @{$lines} = split(qq{\n}, $response);

  while (my $info = _parse_ipv4_response($lines))
  {
    push(@{$all}, $info);
  }

  if ($debug >= 2)
  {
    print(Data::Dumper->Dump([$all,], [qw(all),]), qq{\n});
  }
  return ($all);
}

##****************************************************************************
##****************************************************************************

=head2 interface_last_error()

=over 2

=item B<Description>

Return the error string associated with the last command

=item B<Parameters>

=over 4

=item I<NONE>

=back

=item B<Return>

=over 4

=item I<SCALAR>

Error string

=back

=back

=cut

##----------------------------------------------------------------------------
sub interface_last_error
{
  return ($interface_error);
}

##****************************************************************************
##****************************************************************************

=head2 interface_info_all()

=over 2

=item B<Description>

Return an reference to an array of hash references with interface information

=item B<Parameters>

=over 4

=item I<NONE>

=back

=item B<Return>

=over 4

=item I<ARRAY REFERENCE>

ARRAY reference of hash references whose keys are as follows:

=over 6

=item I<name>

Name of the interface

=item I<enabled>

Boolean indicating if the administrative state is enabled

=item I<state>

Indicates the connections state as Connected or Disconnected

=item I<type>

Indicates the type of interface

=back

=back

=back

=cut

##----------------------------------------------------------------------------
sub interface_info_all
{
  my $all = [];

  print(qq{interface_info_all()\n}) if ($debug);

  my $command  = qq{interface show interface};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  foreach my $line (split(qq{\n}, $response))
  {
    ## Parse each line
    if ($line =~ /\A(Enabled|Disabled)/x)
    {
      ## Originally used a RegEx, but found XP did not provide data in the 
      ## "State" column, so now using substr() to parse out the 
      my $enabled = 
      my $info = {
        enabled => ((uc(str_trim(substr($line, 0, 15))) eq qq{ENABLED}) ? 1 : 0),
        state   => str_trim(substr($line, 15, 15)),
        type    => str_trim(substr($line, 30, 17)),
        name    => str_trim(substr($line, 47)),
      };

      push(@{$all}, $info);
    }
  }

  if ($debug >= 2)
  {
    print(Data::Dumper->Dump([$all,], [qw(all),]), qq{\n});
  }
  return ($all);
}

##****************************************************************************
##****************************************************************************

=head2 interface_info($name)

=over 2

=item B<Description>

Return a hash references with interface information

=item B<Parameters>

=over 4

=item I<$name>

Name of the interface such as "Local Area Connection"

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

=item I<enabled>

Boolean indicating if the administrative state is enabled

=item I<state>

Indicates the connections state as Connected or Disconnected

=item I<type>

Indicates the type of interface

=back

=back

=back

=cut

##----------------------------------------------------------------------------
sub interface_info
{
  my $name = shift // qq{};
  my $info;

  print(qq{interface_info("$name")\n}) if ($debug);

  my $command  = qq{interface show interface name="$name"};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }

  foreach my $line (split(qq{\n}, $response))
  {
    if ($line =~ /\A\s+ ([^:]+): \s+ (.*)\Z/x)
    {
      my $text  = str_trim($1);
      my $value = str_trim($2);
      print(qq{  TEXT:  [$text]\n  VALUE: [$value]\n}) if ($debug);

      if (my $key = get_key_from_lookup($text, $INTERFACE_KEY_LOOKUP))
      {
        ## See if the variable is defined
        unless ($info)
        {
          ## Initialize the variable
          $info = initialize_hash_from_lookup($INTERFACE_KEY_LOOKUP);
          $info->{name} = $name;
        }

        ## Translate the enabled field into a boolean
        $value = ((uc($value) eq qq{ENABLED}) ? 1 : 0) if ($key eq qq{enabled});

        ## Save the field data
        $info->{$key} = $value;

      }
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

=head2 interface_enable($name, $enable)

=over 2

=item B<Description>

Enable / disable the specified interface

B<NOTE:> The script must be running with Administrator privileges for to be able to
enable or disable an interface

=item B<Parameters>

=over 4

=item I<$name>

Name of the interface to control

=item I<$enaable>

Boolean value indicating if the interface should be enabled

=back

=item B<Return>

=over 4

=item I<SCALAR>

=over 6

=item SCALAR

A "true" value indicates success

=item UNDEF

UNDEF or a "false" vale indicates an error. The error message can be retrieved
using interface_last_error()

=back

=back

=back

=cut

##----------------------------------------------------------------------------
sub interface_enable
{
  my $name = shift // qq{};
  my $enabled = shift // 1;

  $interface_error = qq{};

  print(qq{interface_enable("$name", $enabled)\n}) if ($debug);

  ## See if script is running as admin
  if (Win32::IsAdminUser())
  {
    ## Running as admin, clear any error
    $interface_error = qq{};
  }
  else
  {
    ## Not running as admin, set error and return
    $interface_error = qq{Must have Administrator privileges to enable or disable an interface!};
    return;
  }

  ## Set to the format the netsh command needs
  $enabled = ($enabled ? qq{ENABLED} : qq{DISABLED});
  my $command  = qq{interface set interface name="$name" admin=$enabled};
  my $response = netsh($command);
  if ($debug >= 2)
  {
    print(qq{COMMAND:  [netsh $command]\n});
    print(qq{RESPONSE: [$response]\n});
  }
  
  ## Trim the response
  $interface_error = str_trim($response);

  ## Return undef if we have an error
  return if ($interface_error);
  
  ## Return success
  return(1);
}

##****************************************************************************
## Additional POD documentation
##****************************************************************************

=head1 SEE ALSO

L<Win32::Netsh::Wlan> for examining and controlling the netsh wlan context
for wireless interfaces.

=head1 AUTHOR

Paul Durden E<lt>alabamapaul AT gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 by Paul Durden.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    ## End of module
__END__
