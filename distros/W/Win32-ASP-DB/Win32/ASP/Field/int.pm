############################################################################
#
# Win32::ASP::Field::int - implements int fields in the Win32-ASP-DB system
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

use Win32::ASP::Field;
use Error qw/:try/;
use Win32::ASP::Error;

package Win32::ASP::Field::int;

@ISA = ('Win32::ASP::Field');

use strict;

sub _check_value {
  my $self = shift;
  my($value) = @_;

  if (defined $value and int($value) ne $value) {
    throw Win32::ASP::Error::Field::bad_value (field => $self, bad_value => $value,
        error => "The value is not an integer");
  }

  $self->SUPER::_check_value($value);
}

sub _as_sql {
  my $self = shift;
  my($value) = @_;

  $self->check_value($value);

  defined $value or return 'NULL';
  return int($value);
}

1;
