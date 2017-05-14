use Win32::ASP::DBRecord;
use Error qw/:try/;
use DocSample::DocEntryGroup;

package DocSample::Document;

@ISA = ('Win32::ASP::DBRecord');

use strict;

sub _DB {
  return $main::TheDB;
}

sub _FRIENDLY {
  return "Document";
}

sub _READ_SRC {
  return 'DocumentsFull';
}

sub _WRITE_SRC {
  return 'Documents';
}

sub _PRIMARY_KEY {
  return ('DocID');
}

sub _FIELDS {
  return $DocSample::Document::fields;
}

$DocSample::Document::fields = {
  Win32::ASP::Field->new(
    name => 'DocID',
    sec  => 'ro',
    type => 'int',
    desc => 'Doc ID',
  ),

  Win32::ASP::Field->new(
    name => 'Title',
    sec  => 'rw',
    type => 'varchar',
    reqd => 1,
    size => 50,
    maxl => 50,
  ),

  Win32::ASP::Field->new(
    name => 'CatCode',
    sec  => 'ro',
    type => 'varchar',
    desc => 'CatCode',
  ),

  Win32::ASP::Field->new(
    name => 'Category',
    sec  => 'rw',
    type => 'varchar',
    reqd => 1,

    _standard_option_list => [
      class     => 'DocSample::Document',
      writename => 'CatCode',
      table     => 'CatCodes',
      field     => 'CatCode',
      desc      => 'Description'
    ],
  ),

  Win32::ASP::Field->new(
    name => 'Author',
    sec  => 'ro',
    type => 'varchar',
  ),

  Win32::ASP::Field->new(
    name => 'LastEditor',
    sec  => 'ro',
    type => 'varchar',
    desc => 'Last Editor',
  ),

  Win32::ASP::Field->new(
    name => 'CreateTS',
    sec  => 'ro',
    type => 'datetime',
    desc => 'Create Time',
  ),

  Win32::ASP::Field->new(
    name => 'LastEditTS',
    sec  => 'ro',
    type => 'datetime',
    desc => 'Last Edit Time',
  ),

  Win32::ASP::Field->new(
    name => 'Hidden',
    sec  => 'rw',
    type => 'boolean',
  ),

  Win32::ASP::Field->new(
    name => 'Locked',
    sec  => 'ro',
    type => 'boolean',
  ),

};

sub _ACTIONS {
  return $DocSample::Document::actions;
}

$DocSample::Document::actions = {
  Win32::ASP::Action::Insert->new,

  Win32::ASP::Action::Edit->new,

  Win32::ASP::Action::Delete->new,

  Win32::ASP::Action->new(
    name   => 'lock',
    label  => 'Lock',
    verify_msg => sub {
      my $self = shift;
      my($record) = @_;
      my $identifier = $self->identifier($record);
      return "Do you wish to lock $identifier?";
    },

    success_msg => sub {
      my $self = shift;
      my($record) = @_;
      my $identifier = $self->identifier($record);
      return "$identifier was successfully locked.";
    },

    permit => sub {
      my $self = shift;
      my($record) = @_;

      Win32::ASP::Get('user_info')->{role} eq 'E' or return 0;
      return $record->{orig}->{Locked} ? 0 : 1;
    },

    effect => sub {
      my $self = shift;
      my($record) = @_;

      $record->_DB->begin_trans;
      {
        $record->{edit}->{Locked} = 1;
        $record->update('Locked');
      }
      $record->_DB->commit_trans;
    },
  ),

  Win32::ASP::Action->new(
    name   => 'unlock',
    label  => 'Unlock',
    verify_msg => sub {
      my $self = shift;
      my($record) = @_;
      my $identifier = $self->identifier($record);
      return "Do you wish to unlock $identifier?";
    },

    success_msg => sub {
      my $self = shift;
      my($record) = @_;
      my $identifier = $self->identifier($record);
      return "$identifier was successfully unlocked.";
    },

    permit => sub {
      my $self = shift;
      my($record) = @_;

      Win32::ASP::Get('user_info')->{role} eq 'E' or return 0;
      return $record->{orig}->{Locked} ? 1 : 0;
    },

    effect => sub {
      my $self = shift;
      my($record) = @_;

      $record->_DB->begin_trans;
      {
        $record->{edit}->{Locked} = 0;
        $record->update('Locked');
      }
      $record->_DB->commit_trans;
    },
  ),

  Win32::ASP::Action->new(
    name   => 'hide',
    label  => 'Hide',
    verify_msg => sub {
      my $self = shift;
      my($record) = @_;
      my $identifier = $self->identifier($record);
      return "Do you wish to hide $identifier?";
    },

    success_msg => sub {
      my $self = shift;
      my($record) = @_;
      my $identifier = $self->identifier($record);
      return "$identifier was successfully hidden.";
    },

    permit => sub {
      my $self = shift;
      my($record) = @_;

      $record->can_update or return 0;
      return $record->{orig}->{Hidden} ? 0 : 1;
    },

    effect => sub {
      my $self = shift;
      my($record) = @_;

      $record->_DB->begin_trans;
      {
        $record->{edit}->{Hidden} = 1;
        $record->update('Hidden');
      }
      $record->_DB->commit_trans;
    },
  ),

  Win32::ASP::Action->new(
    name   => 'unhide',
    label  => 'Unhide',
    verify_msg => sub {
      my $self = shift;
      my($record) = @_;
      my $identifier = $self->identifier($record);
      return "Do you wish to unhide $identifier?";
    },

    success_msg => sub {
      my $self = shift;
      my($record) = @_;
      my $identifier = $self->identifier($record);
      return "$identifier was successfully unhidden.";
    },

    permit => sub {
      my $self = shift;
      my($record) = @_;

      $record->can_update or return 0;
      return $record->{orig}->{Hidden} ? 1 : 0;
    },

    effect => sub {
      my $self = shift;
      my($record) = @_;

      $record->_DB->begin_trans;
      {
        $record->{edit}->{Hidden} = 0;
        $record->update('Hidden');
      }
      $record->_DB->commit_trans;
    },
  ),
};

sub _CHILDREN {
  return $DocSample::Document::children;
}

$DocSample::Document::children = {
  docentries => {
    type  => 'DocSample::DocEntryGroup',
    pkext => 'EntryID',
  },
};


sub init {
  my $self = shift;

  $self->SUPER::init;

  my $user_info = Win32::ASP::Get('user_info');
  $self->{orig}->{Author} = $user_info->{username};
  $self->{orig}->{LastEditor} = $user_info->{username};
}

sub insert {
  my $self = shift;
  my(@ext_fields) = @_;

  $self->{edit}->{Author} = Win32::ASP::Get('user_info')->{username};
  my($sec, $min, $hour, $day, $month, $year) = localtime(time);
  $self->{edit}->{CreateTS} = sprintf("%02i/%02i/%04i %02i:%02i:%02i", $month+1, $day, $year+1900, $hour, $min, $sec);
  $self->{edit}->{LastEditor} = $self->{edit}->{Author};
  $self->{edit}->{LastEditTS} = $self->{edit}->{CreateTS};
  $self->SUPER::insert('Author', 'CreateTS', 'LastEditor', 'LastEditTS', @ext_fields);
}

sub update {
  my $self = shift;
  my(@ext_fields) = @_;

  if (@ext_fields) {
    $self->SUPER::update(@ext_fields);
  } else {
    $self->{edit}->{LastEditor} = Win32::ASP::Get('user_info')->{username};
    my($sec, $min, $hour, $day, $month, $year) = localtime(time);
    $self->{edit}->{LastEditTS} = sprintf("%02i/%02i/%04i %02i:%02i:%02i", $month+1, $day, $year+1900, $hour, $min, $sec);
    $self->SUPER::update('LastEditor', 'LastEditTS');
  }
}

sub role {
  my $self = shift;

  my $user_info = Win32::ASP::Get('user_info');

  $self->read;

  $user_info->{role} eq 'E' and return 'E';
  $user_info->{role} eq 'A' and $user_info->{username} eq $self->{orig}->{Author} and
      return $self->{orig}->{Locked} ? 'R' : 'A';
  $user_info->{role} =~ /^[RA]$/ and !$self->{orig}->{Hidden} and return 'R';
  return;
}

sub can_view {
  my $self = shift;
  return $self->role ? 1 : 0;
}

sub can_insert {
  my $self = shift;

  return Win32::ASP::Get('user_info')->{role} =~ /^[AE]$/ ? 1 : 0;
}

sub can_update {
  my $self = shift;
  return $self->role =~ /^[AE]$/ ? 1 : 0;
}

sub gen_docentries_table {
  my $self = shift;
  my($data, $viewtype) = @_;

  return $self->{docentries}->gen_docentries_table($data, $viewtype);
}

sub action_disp_all_triggers {
  my $self = shift;

  my(@actions) = qw(edit delete lock unlock hide unhide);

  return join(" |\n", map {$self->action_disp_trigger($_)} @actions);
}

1;
