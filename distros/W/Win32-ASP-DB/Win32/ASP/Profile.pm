############################################################################
#
# Win32::ASP::Profile - provides quick and dirty profiling for web performance
#                       testing in the Win32-ASP-DB system
#
# Author: Toby Everett
# Revision: 0.02
# Last Change:
############################################################################
# Copyright 1999, 2000 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
############################################################################

use Benchmark;

package Win32::ASP::Profile;

use strict;

=head1 NAME

Win32::ASP::Profile - provides quick and dirty profiling for web performance testing

=head1 SYNOPSIS

  use Win32::ASP::Profile;

=head1 DESCRIPTION

C<Win32::ASP::Profile> outputs rudimentary profiling information at the end of each web page
through the use of C<BEGIN> and C<END>.  The C<BEGIN> subroutine initializes some information when
the web page is first created and the C<END> subroutine computes the time it took for the web page
to be create and appends that to the end of the web page.

To use, simply include the line

  use Win32::ASP::Profile;

on any web page you want to profile.  If you are using a default C<*.INC> file, you can stick that
line in the include file and thus garner profiling information on all your ASP pages.

=cut

sub BEGIN {
  $Win32::ASP::Profile::start = Benchmark->new;
  $Win32::ASP::Profile::start_tick = Win32::GetTickCount();
}

sub END {
  my $end = Benchmark->new;
  my $end_tick = Win32::GetTickCount();

  my $delta = Benchmark::timediff($end, $Win32::ASP::Profile::start);
  my $deltastr = Benchmark::timestr($delta);
  $deltastr =~ s/\s+\d+//;
  $deltastr = sprintf("%0.2f", ($end_tick - $Win32::ASP::Profile::start_tick)/1000).$deltastr;

  $main::Response->Write("<HR>$deltastr");
}

1;
