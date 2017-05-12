# Win32/Uptime.pm
#
# Copyright (c) 2007-2010 Serguei Trouchelle. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: Uptime.pm 22 2010-09-23 23:04:07Z stro $
#
# History:
#  1.02  2010/09/24 Patch by John Ciolfi (RT#61520)
#                   Some cleanup
#  1.01  2007/05/16 Initial revision

=head1 NAME

Win32::Uptime - Calculate uptime for Win32 systems

=head1 VERSION

1.02

=head1 SYNOPSIS

 use Win32::Uptime;
 print Win32::Uptime::uptime(); # in milliseconds

=head1 DESCRIPTION

Win32::Uptime

=head1 METHODS

=head2 uptime

This method retrieves the number of milliseconds that have elapsed since the
system was started.

If uptime is more than notorious 49.7 days, and you have pagefile in your
system, it will be calculated correctly. If not, you lose.

Takes no parameters.

=head1 AUTHORS

Serguei Trouchelle E<lt>F<stro@cpan.org>E<gt>

=head1 COPYRIGHT

Copyright (c) 2007-2010 Serguei Trouchelle. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package Win32::Uptime;

use strict;
use warnings;

use Config;

$Win32::Uptime::VERSION = "1.02";
our $INT_VALUE = 4294967296; # GetTickCount uses this value

our $Registry;

use Win32::API;
use Win32::TieRegistry 0.20 (
  'TiedRef' => \$Registry,
  'Delimiter' => "/",
  'ArrayValues' => 1,
  'SplitMultis' => 1,
  'AllowLoad' => 1,
  qw( REG_SZ REG_EXPAND_SZ REG_DWORD REG_BINARY REG_MULTI_SZ
      KEY_READ KEY_ALL_ACCESS ),
);

sub uptime {
  my $GetTickCount;

  # Check GetTickCount64 (Vista/Longhorn/7), if your machine have it.

  $GetTickCount = Win32::API->new("kernel32", "int GetTickCount64()");

  my $ticks;

  if ($GetTickCount) {
      $ticks = $GetTickCount->Call();
  } else  {
      my $swap;

      # Not a Vista, will use old GetTickCount
      $GetTickCount = Win32::API->new("kernel32", "int GetTickCount()");

      # And check swap file to see maybe uptime is more than 49 day
      $swap = $Registry->{"LMachine/SYSTEM/CurrentControlSet/Control/Session Manager/Memory Management/PagingFiles"};
      if ($swap->[0]->[0] =~ /^(.*?)\s+\d+\s+\d+$/x) {
          # If there's many files, first of them would be ok.
          $swap = $1;
          my (undef, undef, undef, undef, undef, undef, undef, undef, $atime,
              undef, undef, undef, undef) = stat($swap);
          $swap = time - $atime;
      } else {
          $swap = 0;
      }

      # How many "49 day" intervals passed since pagefile creation?
      #
      # Also, pagefile is created AFTER GetTickCount's zero, so it will be
      # 0.9something if uptime is less than 49 days.

      my $q = int 1000 * $swap / $INT_VALUE;

      $ticks = $GetTickCount->Call();

      # Adjust to stave off 49 day reset
      $ticks += $q * $INT_VALUE if $q;

      # "if $q" is here because benchmarking says it's 3 times faster with "if"
      # when $q = 0, and only 20% slower when $q > 0. Perl seems to multiply it
      # anyway without optimization.
  }

  return $ticks;
}

1;
