############################################################################
#
# Win32::ASP::Field::text - implements text fields in the Win32-ASP-DB system
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

package Win32::ASP::Field::text;

@ISA = ('Win32::ASP::Field');

use strict;

sub _as_html_edit_rw {
  my $self = shift;
  my($record, $data) = @_;

  my $formname = $self->formname;
  my $value = $record->{$data}->{$self->name};
  my $help = $self->as_html_mouseover($record, $data);

  my $cols = $self->size;
  my $rows = $self->textrows;

  chomp(my $retval = <<ENDHTML);
<TEXTAREA ROWS="$rows" COLS="$cols" WRAP="SOFT" NAME="$formname" $help>$value</TEXTAREA>
ENDHTML
  return $retval;
}

sub _as_sql {
  my $self = shift;
  my($value) = @_;

  $self->check_value($value);

  defined $value or return 'NULL';

  $value =~ s/'/''/g;
  $value = "'$value'";
  return $value;
}

sub _size {
  my $self = shift;
  return 55;
}

sub _textrows {
  my $self = shift;
  return 4;
}

1;
