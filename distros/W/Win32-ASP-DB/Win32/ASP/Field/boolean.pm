############################################################################
#
# Win32::ASP::Field::boolean - implements boolean fields in the Win32-ASP-DB system
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

use Win32::ASP::Field::bit;
use Error qw/:try/;
use Win32::ASP::Error;

package Win32::ASP::Field::boolean;

@ISA = ('Win32::ASP::Field::bit');

use strict;

sub _as_sql {
  my $self = shift;
  my($value) = @_;

  $self->check_value($value);
  return -$value;
}

1;
