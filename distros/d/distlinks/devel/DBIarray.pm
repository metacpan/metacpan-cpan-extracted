# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

package App::Distlinks::DBIarray;
use 5.010;
use strict;
use warnings;
use DBI;
use base 'Tie::Array';

our $VERSION = 11;

sub TIEARRAY {
  my ($class, $dbh, $table) = @_;
  $dbh->do ("CREATE TABLE $table (
               key INTEGER  NOT NULL  PRIMARY KEY,
               value TEXT)");

  return bless { low => 0,
                 count => 0,
                 dbh   => $dbh }, $class;
}

sub FETCHSIZE {
  my ($self) = @_;
  return $self->{'count'};
}

sub FETCH {
  my ($self, $n) = @_;
  return $self->{'dbh'}->do ("SELECT value FROM $self->{'table'} WHERE key=?",
                   $self->{'low'} + $n);
}

sub STORE {
  my ($self, $n, $value) = @_;
  return $self->{'dbh'}->do
    ("INSERT OR REPLACE INTO $self->{'table'} (key,value) (?,?)",
     $self->{'low'} + $n, $value);
}

sub STORESIZE {
  my ($self, $n) = @_;
  return $self->{'dbh'}->do ("DELETE FROM $self->{'table'} WHERE key>=?",
                   $self->{'low'} + $n);
}

sub EXISTS {
  my ($self, $n) = @_;
  return $self->{'dbh'}->do
    ("SELECT value FROM $self->{'table'} WHERE key=?",
     $self->{'low'} + $n);
}

sub DELETE {
  my ($self, $n) = @_;
  return $self->{'dbh'}->do ("DELETE FROM $self->{'table'} WHERE key=?",
                             $self->{'low'} + $n);
}

sub CLEAR {
  my ($self, $n) = @_;
  $self->{'count'} = 0;
  return $self->{'dbh'}->do ("DELETE FROM $self->{'table'}");
}

sub PUSH {
  my $self = shift;
  while (@_) {
    $self->{'dbh'}->do
      ("INSERT INTO $self->{'table'} (key,value) VALUES (?,?)",
       $self->{'low'} + $self->{'count'}++, shift @_);
  }
}

sub POP {
  my ($self) = @_;
  return $self->{'dbh'}->do ("DELETE FROM $self->{'table'} WHERE key=?",
                             $self->{'low'} + --$self->{'count'});
}

sub SHIFT {
  my ($self) = @_;
  return $self->{'dbh'}->do ("DELETE FROM $self->{'table'} WHERE key=?",
                   $self->{'low'}++);
}

sub UNSHIFT {
  my $self = shift;
  while (@_) {
    return $self->{'dbh'}->do
      ("INSERT INTO $self->{'table'} (key,value) VALUES (?,?)",
       --$self->{'low'}, shift @_);
  }
}

1;
__END__
