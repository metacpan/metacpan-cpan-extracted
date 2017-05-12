#                              -*- Mode: Perl -*- 
# $Basename: Handle.pm $
# $Revision: 1.1 $
# Author          : Ulrich Pfeifer
# Created On      : Mon May 31 15:53:55 1999
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Mon May 31 15:54:22 1999
# Language        : Perl

package WAIT::Table::Handle;
use Carp;
use strict;

sub new {
  my ($type, $database, $name) = @_;
  bless [$database, $name], $type;
}

sub database {shift->[0]}

sub name {shift->[1]}

sub table {
  my $self = shift;
  $self->database->{tables}->{$self->name};
}

sub DESTROY {}

sub AUTOLOAD {
  my $func = $WAIT::Table::Handle::AUTOLOAD;
  $func =~ s/.*:://;
  my $self = $_[0];
  my ($database, $name) = @$self;
  # warn "database[$database]name[$name]func[$func]\@_[@_]";
  if (defined $database->{tables}->{$name}) {
    if ($func eq 'drop') {
      $database->drop_table(name => $name);
      undef $_[0];
      1;
    } else {
      shift @_;
      if ($func eq 'open') {
        $database->{tables}->{$name}->$func(mode => $database->{mode}, @_);
      } else {
        $database->{tables}->{$name}->$func(@_);
      }
    }
  } else {
    croak("Invalid handle.
DEBUG: func[$func] self[$self] database[$database]\n");
  }
}


1;
