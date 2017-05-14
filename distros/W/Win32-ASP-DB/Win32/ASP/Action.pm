############################################################################
#
# Win32::ASP::Action - an abstract parent class for Actions
#                      in the Win32-ASP-DB system
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

use Class::SelfMethods;
use Error qw/:try/;
use Win32::ASP::Error;

package Win32::ASP::Action;
@ISA = ('Class::SelfMethods');

use strict;

sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);

  return($self->name, $self);
}

sub _label {
  my $self = shift;
  return $self->name;
}

sub _has_verify {
  my $self = shift;
  return 1;
}

sub _dest {
  my $self = shift;
  return $self->has_verify ? './action.asp' : './action2.asp';
}

sub _permit {
  my $self = shift;
  my($record) = @_;
  return 1;
}

sub _safety {
  my $self = shift;
  my($record) = @_;

  unless ($self->permit($record)) {
    my $identifier = join(", ", map {"$_ $record->{orig}->{$_}"} $record->_PRIMARY_KEY);
    throw Win32::ASP::Error::DBRecord::no_permission(action => $self->label, identifier => $identifier);
  }
}

sub _effect {
  my $self = shift;
  my($record) = @_;
}

sub _effect_from_asp {
  my $self = shift;
  my($record, @params) = @_;

  my $action = $main::Request->querystring('action')->item;
  my(@primary_keys) = map {$main::Request->querystring($_)->item} $record->_PRIMARY_KEY;

  $record->read(@primary_keys);
  $self->safety($record);
  if (exists $record->_FIELDS->{timestamp}) {
    $record->set_timestamp($main::Request->QueryString('timestamp')->item);
  } else {
    $record->edit;
  }
  $self->effect($record, @params);
}

sub _disp_trigger {
  my $self = shift;
  my($record) = @_;

  if ($self->permit($record)) {
    my(%parameters) = map {($_, $record->{orig}->{$_})} $record->_PRIMARY_KEY;
    exists $record->_FIELDS->{timestamp} and $parameters{timestamp} = $record->{orig}->{timestamp};
    $parameters{action} = $self->name;
    my $url = Win32::ASP::FormatURL($self->dest, %parameters);
    (my $label = $self->label) =~ s/ /\&nbsp\;/g;
    return "<A HREF=\"$url\">$label</A>";
  }
}

sub _disp_verify {
  my $self = shift;
  my($record) = @_;

  my $verify_msg = $self->verify_msg($record);
  my(%primary_keys) = map {($_, $main::Request->QueryString($_)->Item)} $record->_PRIMARY_KEY;
  my $yesurl = Win32::ASP::FormatURL('./action2.asp', &Win32::ASP::QueryStringList);
  my $view_record = $self->view_record($record);
  return <<ENDHTML;
$verify_msg<P>
<A HREF="$yesurl">Confirm</A><P>
$view_record
ENDHTML
}

sub _disp_success {
  my $self = shift;
  my($record) = @_;

  my $success_msg = $self->success_msg($record);
  my $view_record = $self->view_record($record);
  return "$success_msg<P>\n$view_record";
}

sub _verify_msg {
  my $self = shift;
  my($record) = @_;

  (my $label = $self->label) =~ s/ /\&nbsp\;/g;
  my $identifier = $self->identifier($record);

  return "Are you sure you want to $label $identifier?";
}

sub _success_msg {
  my $self = shift;
  my($record) = @_;

  (my $label = $self->label) =~ s/ /\&nbsp\;/g;
  my $identifier = $self->identifier($record);

  return "The action $label was successfully completed on $identifier.";
}

sub _view_record {
  my $self = shift;
  my($record) = @_;

  my(%primary_keys) = map {($_, $main::Request->QueryString($_)->Item)} $record->_PRIMARY_KEY;
  my $url = Win32::ASP::FormatURL('./view.asp', %primary_keys);
  my $identifier = $self->identifier($record);

  return "Return to viewing <A HREF=\"$url\">$identifier</A>.";
}

sub _identifier {
  my $self = shift;
  my($record) = @_;

  my(%primary_keys) = map {($_, $main::Request->QueryString($_)->item)} $record->_PRIMARY_KEY;
  return join(', ', map {"$_ $primary_keys{$_}"} $record->_PRIMARY_KEY);
}





package Win32::ASP::Action::Insert;

@Win32::ASP::Action::Insert::ISA = ('Win32::ASP::Action');

sub _name {
  my $self = shift;
  return 'insert';
}

sub _label {
  my $self = shift;
  return 'Add New';
}

sub _permit {
  my $self = shift;
  my($record) = @_;

  return $record->can_insert;
}

sub _dest {
  my $self = shift;
  return './insert.asp';
}

package Win32::ASP::Action::Edit;

@Win32::ASP::Action::Edit::ISA = ('Win32::ASP::Action');

sub _name {
  my $self = shift;
  return 'edit';
}

sub _label {
  my $self = shift;
  return 'Edit';
}

sub _permit {
  my $self = shift;
  my($record) = @_;

  return $record->can_update;
}

sub _dest {
  my $self = shift;
  return './edit.asp';
}

package Win32::ASP::Action::Delete;

@Win32::ASP::Action::Delete::ISA = ('Win32::ASP::Action');

sub _name {
  my $self = shift;
  return 'delete';
}

sub _label {
  my $self = shift;
  return 'Delete';
}

sub _disp_success {
  my $self = shift;
  my($record) = @_;

  return $self->success($record);
}

sub _success {
  my $self = shift;
  my($record) = @_;

  my $identifier = $self->identifier($record);

  return "$identifier was successfully deleted.";
}

sub _permit {
  my $self = shift;
  my($record) = @_;

  return $record->can_delete;
}

sub _effect {
  my $self = shift;
  my($record) = @_;

  $record->delete;
}

1;
