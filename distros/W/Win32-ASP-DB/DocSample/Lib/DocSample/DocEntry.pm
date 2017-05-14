use Win32::ASP::DBRecord;
use Error qw/:try/;

package DocSample::DocEntry;

@ISA = ('Win32::ASP::DBRecord');

use strict;

sub _DB {
  return $main::TheDB;
}

sub _FRIENDLY {
  return "Document Entry";
}

sub _READ_SRC {
  return 'DocEntries';
}

sub _WRITE_SRC {
  return 'DocEntries';
}

sub _PRIMARY_KEY {
  return ('DocID', 'EntryID');
}

sub _FIELDS {
  return $DocSample::DocEntry::fields;
}

$DocSample::DocEntry::fields = {
  Win32::ASP::Field->new(
    name => 'DocID',
    sec  => 'ro',
    type => 'int',
    desc => 'Doc ID',
  ),

  Win32::ASP::Field->new(
    name => 'EntryID',
    sec  => 'ro',
    type => 'int',
    desc => 'Entry ID',
  ),

  Win32::ASP::Field->new(
    name => 'Contents',
    sec  => 'rw',
    type => 'text',
    reqd => 1,
    formname => 'FormContents',
  ),
};

sub insert {
  my $self = shift;
  my(@ext_fields) = @_;

  $self->SUPER::insert('DocID', 'EntryID', @ext_fields);
}

sub row_check {
  my $self = shift;
  my($row) = @_;

  my $temp = $self->SUPER::row_check($row, grep(!/^DocID|EntryID$/, keys %{$self->_FIELDS}));
  $temp and $self->{edit}->{EntryID} = $row;
  return $temp;
}

1;
