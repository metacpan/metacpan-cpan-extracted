package Text::DHCPparse;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(leaseparse leaseparsenc);

$VERSION = '0.10';

sub leaseparse {
   my $logfile = shift;
   my ( %list, $ip );
   open FILE, $logfile or die;

   while (<FILE>) {
      next if /^#|^$/;
      if (/^lease (\d+\.\d+\.\d+\.\d+)/) {
         $ip = $1; 
         $list{$ip} = sprintf("%-17s", $ip);
      }
      /^\s*hardware ethernet (.*);/ && ($list{$ip} .= sprintf("%-19s", $1));
      /^\s*starts \d (.*);/ && ($list{$ip} .= sprintf("%-21s", $1));
      /^\s*(abandoned).*/ && ($list{$ip} .= sprintf("%-19s", $1));
      /^\s*client-hostname "(.*)";/ && ($list{$ip} .= sprintf("%-17s", $1));
   }

   close FILE;

   # make all entries 74 characters long to format properly
   foreach (keys %list) {
      #$list{$_} = sprintf("%-74s", $list{$_}) if (length$list{$_} < 76);
      $list{$_} = sprintf("%-74.74s", $list{$_});
   }

   return \%list;
}

sub leaseparsenc {
# Same as leaseparse, but no colons in MAC and field is 5 characters shorter
   my $logfile = shift;
   my ( %list, $ip );
   open FILE, $logfile or die;

   while (<FILE>) {
      next if /^#|^$/;
      if (/^lease (\d+\.\d+\.\d+\.\d+)/) {
         $ip = $1; 
         $list{$ip} = sprintf("%-17s", $ip);
      }
      if ( /^\s*hardware ethernet (.*);/) {
         (my $mac =  $1) =~ s/://g;
         $list{$ip} .= sprintf("%-14s", $mac);
      }
      /^\s*starts \d (.*);/ && ($list{$ip} .= sprintf("%-21s", $1));
      /^\s*(abandoned).*/ && ($list{$ip} .= sprintf("%-14s", $1));
      /^\s*client-hostname "(.*)";/ && ($list{$ip} .= sprintf("%-17s", $1));
   }

   close FILE;

   # make all entries 69 characters long to format properly
   foreach (keys %list) {
      #$list{$_} = sprintf("%-69s", $list{$_}) if (length$list{$_} < 76);
      $list{$_} = sprintf("%-69.69s", $list{$_});
   }

   return \%list;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Text::DHCPparse - Perl extension for parsing dhcpd lease files

=head1 SYNOPSIS

  use Text::DHCPparse;

=head1 DESCRIPTION

The basic premise of the Text::DHCPparse module is to parse the lease file
from an ISC DHCPd server.  This is useful for quick reporting on active 
leases or for tracking purposes.  The resulting hash reference is a fixed 
length record with the key being the IP address for the lease, and the
value being the lease info in the following format:

   Characters       Field
   ----------  --------------------
     1 - 17    IP Address
    18 - 38    Last Lease Timestamp
    39 - 57    Hardware Address
    58 - 74    Client Hostname


The following is if you are using the no colon function:
   Characters       Field
   ----------  --------------------
     1 - 17    IP Address
    18 - 38    Last Lease Timestamp
    39 - 52    Hardware Address
    53 - 69    Client Hostname

(All fields have a minimum 2-space field delimiter for formatting.)

WARNING:  Always use a copy of your 'dhcpd.leases' file - never use an
original from a live server!

The following is a simple piece of code to show the functionality of
the Text::DHCPparse module:

   #!/usr/bin/perl

   use Text::DHCPparse;

   $return = leaseparse('/tmp/dhcpd.leases');

   foreach (keys %$return) {
      print "$return->{$_}\n";
   }

The following code can be used to take the output from Text::DHCPparse 
and separate it into individual fields if you don't like the fixed
length record:

   #!/usr/bin/perl

   use Text::DHCPparse;

   $return = leaseparse('/tmp/dhcpd.leases');

   foreach (keys %$return) {
      ($ip, $time, $mac, $name) = unpack("A17 A21 A19 A30", $return->{$_});
      # code to handle the '$ip $time $mac & $name' variables
   }

The exported function leaseparsenc works exactly the same, but it removed
colons from the MAC address and shortens the record by 5 characters.

=head1 AUTHOR

John D. Shearer <dhcpparse@netguy.org>

=head1 SEE ALSO

perl(1).

=head1 COPYRIGHT

Copyright (c) 2001 John D. Shearer.  All rights reverved.
This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
