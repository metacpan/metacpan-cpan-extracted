############################################################################
#
# Win32::ASP::Field::timestamp - implements timestamp fields in the Win32-ASP-DB system
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

package Win32::ASP::Field::timestamp;

@ISA = ('Win32::ASP::Field');

use strict;

sub _read {
  my $self = shift;
  my($record, $results, $columns) = @_;

  my $name = $self->name;
  ref($columns) and !$columns->{$name} and return;
  $self->can_view($record) or return;
  if ($results->Fields->Item($name)) {
    my $temp = uc(unpack('H*', $results->Fields->Item($name)->Value));
    $temp =~ s/^0+//;
    $record->{orig}->{$name} = $temp;
  }
}

sub _as_html_view {
  my $self = shift;
  my($record, $data) = @_;

  return '';
}

sub _as_html_edit_ro {
  my $self = shift;
  my($record, $data) = @_;

  my $formname = $self->formname;
  my $value = $record->{$data}->{$self->name};

  chomp(my $retval = <<ENDHTML);
<INPUT TYPE="HIDDEN" NAME="$formname" VALUE="$value">
ENDHTML
  $retval .= $self->as_html_view;
  return $retval;
}

1;
