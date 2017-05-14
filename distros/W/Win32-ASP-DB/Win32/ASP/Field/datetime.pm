############################################################################
#
# Win32::ASP::Field::datetime - implements datetime fields in the Win32-ASP-DB system
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
use Win32::OLE::Variant;

package Win32::ASP::Field::datetime;

@ISA = ('Win32::ASP::Field');

use strict;

sub _check_value {
  my $self = shift;
  my($value) = @_;

  if (defined $value and $self->clean_datetime($value) eq '-1') {
    throw Win32::ASP::Error::Field::bad_value (field => $self, bad_value => $value,
        error => "The value is not in a legal datetime format.");
  }

  $self->SUPER::_check_value($value);
}

sub _read {
  my $self = shift;
  my($record, $results, $columns) = @_;

  my $name = $self->name;
  ref($columns) and !$columns->{$name} and return;
  $self->can_view($record) or return;
  my $temp = $results->Fields->Item($name);
  if ($temp) {
    my $value = $temp->Value;
    $value ne '' and $value = $self->clean_datetime($value);
    $record->{orig}->{$name} = $value;
  }
}

sub _post {
  my $self = shift;
  my($record, $row) = @_;

  $self->SUPER::_post($record, $row);

  my $name = $self->name;
  if (defined $record->{edit}->{$name}) {
    my $temp = $self->clean_datetime($record->{edit}->{$name});
    $temp ne '-1' and $record->{edit}->{$name} = $temp;
  }
}

sub _as_sql {
  my $self = shift;
  my($value) = @_;

  $self->check_value($value);

  defined $value or return 'NULL';

  $value = "'".$self->clean_datetime($value)."'";
  return $value;
}

sub _date_lcid {
  my $self = shift;
  my($DTobj) = @_;

  return "M/d/yyyy";
}

sub _time_lcid {
  my $self = shift;
  my($DTobj) = @_;

  return "h:mm:ss tt";
}

sub _format_date {
  my $self = shift;
  my($DTobj) = @_;

  return $DTobj->Date($self->date_lcid);
}

sub _format_time {
  my $self = shift;
  my($DTobj) = @_;

  my $temp = $DTobj->Time($self->time_lcid);
  my $temp2 = Win32::OLE::Variant->new(8, $temp);
  $temp2->ChangeType(7);
  $temp2->ChangeType(5);
  return $temp2 ? $temp : '';
}

{ my %memo;
sub _clean_datetime {
  my $self = shift;
  my($DTstr) = @_;

  unless (exists $memo{$DTstr}) {
    my $temp = Win32::OLE::Variant->new(8, $DTstr);
    $temp->ChangeType(7) or return -1;
    $memo{$DTstr} = $self->format_date($temp)." ".$self->format_time($temp);
  }
  return $memo{$DTstr};
}
}

1;
