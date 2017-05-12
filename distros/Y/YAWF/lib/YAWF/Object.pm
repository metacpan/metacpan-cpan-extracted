package YAWF::Object;

=pod

=head1 NAME

YAWF::Object - Base class for YAWF ojects

=head1 SYNOPSIS

  my $object = YAWF::Object->new(); # New item
  my $object = YAWF::Object->new( $id ); # Get item by primary key
  my $object = YAWF::Object->new( foo => bar ); # Search item (returns the first)

  my @objects = YAWF::Object->list({ foo => bar }); # Search for a list of items

=head1 DESCRIPTION

YAWF::Object is the base class for database objects. It abstracts DBIx::Class and
adds some nice functions which also could be used via Template::Toolkit.

Additional methods could be added to objects as needed.

=head1 USAGE EXAMPLE

Here is a sample defining an user object for MyProject:

  package MyProject::User;

  use strict;
  use warnings;
  
  use constant TABLE => 'Users';
  
  use YAWF::Object;
  
  our @ISA = ('YAWF::Object','MyProject::DB::Result::Users');
  
  1;

Extra features could be added on demand:

  package MyProject::User;

  use strict;
  use warnings;
  
  use constant TABLE => 'Users';
  
  use YAWF::Object;
  
  our @ISA = ('YAWF::Object','MyProject::DB::Result::Users');

  # A method for getting a list of all the friends of this user, could
  # be used from Template::Toolkit, too.
  sub friends {
      my $self = shift;
      return MyProject::Friends->list({ myuserid => $self->userid });
  }

  # Overriding a column name
  sub lastlogin {
      my $self = shift;
      if ((time - $self->to_time('lastlogin')) < 86400) {
          return 'today';
      } else {
          return 'long ago';
      }
  }
  
  1;

=head1 CLASS METHODS

=cut

use 5.006;
use strict;
use warnings;

use Time::Local ();

use YAWF;

our $VERSION = '0.01';

=pod

=head2 list

  my @objects = YAWF::Object->list(); # Get all items of a table (could be big!)
  my @objects = YAWF::Object->list({ foo => bar }); # Search for a list of items

=cut

sub list {
    my $class = shift;

    my $filter = shift || {};
    my $attributes = shift || {};

    my @joins;
    for (keys(%{$filter})) {
        next unless /^(\w+)\.\w+$/;
        push @joins,$1;
    }

    if (ref($attributes->{join}) eq 'ARRAY') {
        push @joins,@{$attributes->{join}};
    } elsif ($attributes->{join}) {
        push @joins,$attributes->{join};
    }

    $attributes->{join} = \@joins if $#joins > -1;

    return
      map { bless $_, $class; }
      ( YAWF->db->resultset( $class->TABLE )->search($filter,$attributes) );
}

=pod

=head2 count

  my $count = YAWF::Object->count(); # Get the number of items in this table
  my $count = YAWF::Object->count({ foo => bar }); # Get the number of items for this search

=cut

sub count {
    my $class = shift;

    my $filter = shift || {};
    my $attributes = shift || {};

    my @joins;
    for (keys(%{$filter})) {
        next unless /^(\w+)\.\w+$/;
        push @joins,$1;
    }

    if (ref($attributes->{join}) eq 'ARRAY') {
        push @joins,@{$attributes->{join}};
    } elsif ($attributes->{join}) {
        push @joins,$attributes->{join};
    }

    $attributes->{join} = \@joins if $#joins > -1;

    return YAWF->db->resultset( $class->TABLE )->search($filter,$attributes)->count;
}

=head1 METHODS

=head2 new

  my $object = YAWF::Object->new(); # New item
  my $object = YAWF::Object->new($id); # Get item by primary key
  my $object = YAWF::Object->new(foo => bar); # Search item (returns the first)

The C<new> constructor lets you create a new B<YAWF::Object> object.

The first syntax creates a new, empty item while the others return an existing
item from the database or undef if nothing was found.

=cut

sub new {
    my $class = shift;

    my $self;
    if ( $#_ > 0 ) {
        $self = YAWF->db->resultset( $class->TABLE )->single( {@_} )
          || YAWF->db->resultset( $class->TABLE )->new( {@_} );
    }
    elsif ( ( $#_ == 0 ) and defined( $_[0] ) and ($_[0] ne '') ) {
        $self = YAWF->db->resultset( $class->TABLE )->find(shift);
    }
    else {
        $self = YAWF->db->resultset( $class->TABLE )->new( {} );
    }

    return unless defined($self);

    return bless $self, $class;
}


=head2 flush

  $object->flush;

Write a YAWF object into the database with automatic selection of insert or update
depending on the objects state (new or existing).

Changes the variable used to call the method to the new object and also returns the
new object.

=cut

sub flush {

    # Don't use shift here as $_[0] needs to be changed on insert!!!

    if ( $_[0]->in_storage ) {
        return $_[0]->update;
    }
    else {

        # Reverse update the variable used for $_[0] using the stored object
        $_[0] = bless $_[0]->insert->get_from_storage, ref( $_[0] );
        return $_[0];
    }
}

=head2 to_time

  my $timestamp = $object->to_time($time_column);

Convertes an SQL ISO timestamp to an unixtime value.

=cut

sub to_time {
    my $self = shift;
    my $key  = shift;

    return unless defined($self->get_column($key));

    return Time::Local::timelocal( $6, $5, $4, $3, ( $2 - 1 ), $1 ) 
    if $self->get_column($key) =~
      /^(\d{4})\-(\d{2})\-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})\.\d{3}Z$/;

    return Time::Local::timelocal( $6, $5, $4, $3, ( $2 - 1 ), $1 ) 
    if $self->get_column($key) =~
            /^(\d{4})\-(\d{2})\-(\d{2}) (\d{2})\:(\d{2})\:(\d{2})(\.\d+)?(?:\+(\d+))?$/;

    return Time::Local::timelocal( 0, 0, 0, $3, ( $2 - 1 ), $1 ) 
    if $self->get_column($key) =~
            /^(\d{4})\-(\d{2})\-(\d{2})$/;

}

=head2 from_time

  my $timestamp = $object->from_time($time_column,$timestamp);

Inserts a timestamp into the database (converting it to SQL format).

=cut

sub from_time {
    my $self       = shift;
    my $key        = shift;
    my $time_value = shift;

    my @ts = localtime($time_value);
    ++$ts[4];
    $ts[5] += 1900;
    return $self->set_column( $key,"$ts[5]-$ts[4]-$ts[3] $ts[2]:$ts[1]:$ts[0]");

    # TODO: Get rid of DateTime::Format::Sybase here.
    return $self->set_column( $key,
        DateTime::Format::Sybase->format_datetime($time_value) );
}

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2011 Sebastian Willing.

=cut
