###########################################################################
### Trinket::Directory::DataAccess
###
### Access to data storage and indexing of persistent objects.
###
### $Id: DataAccess.pm,v 1.2 2001/02/16 07:23:11 deus_x Exp $
###
### TODO:
###
###########################################################################

package Trinket::Directory::DataAccess;

use strict;
use vars qw($VERSION @ISA @EXPORT $DESCRIPTION $AUTOLOAD);
no warnings qw( uninitialized );

# {{{ Begin POD

=head1 NAME

Trinket::Directory::DataAccess - Data access backend for object directory

=head1 DESCRIPTION

TODO

=cut

# }}}

# {{{ METADATA

BEGIN
  {
    $VERSION      = "0.0";
    @ISA          = qw( Exporter );
    $DESCRIPTION  = 'Base abstract class for data access backends';
  }

# }}}

use Exporter;
use Carp qw( croak cluck );

# {{{ METHODS

=head1 METHODS

=over 4

=cut

# }}}

# {{{ new(): Object constructor

=item $data = new Trinket::Directory::DataAccess::BackendName();

Object constructor, accepts a hashref of named properties with which to
initialize the object.  In initialization, the object's set methods
are called for each of initializing properties passed.  '

=cut

sub new
  {
    my $class = shift;

    my $self = {};

    bless($self, $class);
    $self->init(@_);
    return $self;
  }

# }}}
# {{{ init(): Object initializer

sub init
  {
    no strict 'refs';
    my ($self, $props) = @_;

  }

# }}}

# {{{ create()

=item $dir->create($params)

Create a new object directory, destroys any existing directory
associated with the given parameters.

=cut

sub create
  {
    my ($self, $name, $params) = @_;

    croak(ref($self)."->create() not implemented.");

    return 1;
  }

# }}}
# {{{ open()

=item $dir->open($params)

TODO

=cut

sub open
  {
    my ($self, $dir_name, $params) = @_;

    croak(ref($self)."->open() not implemented.");

    return 1;
  }

# }}}
# {{{ close()

=item $dir->close($params)

TODO

=cut

sub close
  {
    my ($self, $params) = @_;

    croak(ref($self)."->close() not implemented.");

    return 1;
  }

# }}}

# {{{ store_object():

sub store_object
  {
    my ($self, $obj) = @_;
    my $id;

    croak(ref($self)."->store_object() not implemented.");

    return $id;
  }

# }}}
# {{{ retrieve_object():

sub retrieve_object
  {
    my ($self, $id) = @_;
    my $obj;

    croak(ref($self)."->retrieve_object() not implemented.");

    return $obj;
  }

# }}}
# {{{ delete_object

sub delete_object
  {
    my ($self, $id, $obj) = @_;

    croak(ref($self)."->delete_object() not implemented.");

    return 1;
  }

# }}}
# {{{ search_objects

sub search_objects
  {
    my ($self, $parsed) = @_;
    my @ids;

    croak(ref($self)."->search_objects() not implemented.");

    return @ids;
  }

# }}}

# {{{ is_ready():

sub is_ready
  {
    my $self = shift;

    return undef if (!defined $self->{directory});

    return ( $self->{directory}->{created} eq 1 );
  }

# }}}

# {{{ DESTROY

sub DESTROY
  {
    ## no-op to pacify warnings
  }

# }}}

# {{{ End POD

=back

=head1 AUTHOR

Maintained by Leslie Michael Orchard <F<deus_x@pobox.com>>

=head1 COPYRIGHT

Copyright (c) 2000, Leslie Michael Orchard.  All Rights Reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# }}}

1;
__END__

