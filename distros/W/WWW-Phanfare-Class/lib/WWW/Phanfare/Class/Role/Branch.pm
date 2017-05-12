package WWW::Phanfare::Class::Role::Branch;
use Moose::Role;
use MooseX::Method::Signatures;

# A Branch node must be able to tell type of child
# and produce a list of id=>names pairs of child nodes
requires '_childclass';
requires '_idnames';

# List of subnodes
#
has '_nodes' => (
  traits  => ['Array'],
  is      => 'rw',
  isa     => 'ArrayRef[Ref]',
  lazy_build => 1,
  handles => {
    list    => 'elements',
    _add     => 'push',
    _del     => 'delete',
    _indexget => 'accessor',
    _clear => 'clear',
  },
);

# Build a list of subnodes.
# Names and ID's come from required _idnames method.
# If ID eq name, then it means there is no ID
#
method _build__nodes {
  my $type = $self->_childclass;
  my @nodes;
  my $idname = $self->_idnames;
  for my $item ( @$idname ) {
    my $id = $item->{id};
    my $name = $item->{name};
    my $node = $type->new(
      parent => $self,
      name => $name,
      ( $name ne $id ? ( id=>$id ) : () ),
    );

    # Attributes are known by branch node
    $node->setattributes( $item->{attr} )
      if $item->{attr} and $node->can('setattributes');

    # Attributes are known by child node
    $node->_buildattributes if $node->can('_buildattributes');

    push @nodes, $node;
  }
  return \@nodes;
}

# Rebuild all child objects
#
method _rebuild {
  my $nodes = $self->_build__nodes;
  $self->_nodes( $nodes );
}

# Names of child nodes
# If multiple child nodes have same name, then append id to name of those
#
method names {
  my %name_count;
  ++$name_count{$_->name} for $self->list;
  return map {
    $name_count{$_->name} > 1
      ? $_->name .'.'. $_->id
      : $_->name
  } $self->list;
}

# Get a subnode, by name of name.id
#
method get ( Str $name ) {
  #warn "*** branch get node $name\n";
  my $index = $self->_index( $name );
  return unless defined $index;
  return $self->_indexget( $index );
}

# Index number of matching node
#
method _index ( Str $name ) {
  my $i = 0;
  for my $node ( $self->list ) {
    return $i if $node->id and $name eq $node->name .'.'. $node->id;
    return $i if               $name eq $node->name;
    ++$i;
  }
  return undef;
}

sub AUTOLOAD {
  my $self = shift @_;
  our $AUTOLOAD;

  my $name = $AUTOLOAD;
  $name =~ s/.*:://;

  #die caller if $name eq 'nodename';
  return $self->get($name);
}

# Create new child object and add to list.
# Let object write itself to phanfare if possible
# 
method add ( Str $name, Str $value?, Str $date? ) {
  my $type = $self->_childclass;
  my $node = $type->new( parent=>$self, name=>$name );
  $node->value( $value ) if $value;
  $node->attribute( 'image_date', $date ) if $date;
  if ( $node->can( '_write' ) ) {
    $node->_write or return;
    $self->_rebuild;
  } else {
    $self->_add( $node );
  }
  return $self->get( $name );
}

# Let child object remove itself from phanfare
# Then remove from list
#
method remove ( Str $name ) {
  my $node = $self->get( $name ) or return undef;
  if ( $node->can( '_delete' ) ) {
    $node->_delete && $self->_del( $self->_index( $name ) );
  }
}

# Extract id=>name pairs from a data structure converted from xml
#
method _idnamepair ( Ref $data, Str $label, HashRef $filter? ) {
  # If data only has one element we get a hashref. Convert it to array.
  $data = [ $data ] unless 'ARRAY' eq ref $data; 
  my($key,$value) = each %$filter if $filter;
  # Pairs of id=>name
  return [
    map {{
      id   => $_->{"${label}_id"},
      name => $_->{"${label}_name"},
      attr  => $_,
    }}
    grep {
      if ( $key and $value and $_->{$key} ) {
        1 if $_->{$key} =~ /^$value/;
      } else {
        1
      }
    }
    @$data
  ];
}

with 'WWW::Phanfare::Class::Role::Node';

=head1 NAME

WWW::Phanfare::Class::Role::Branch - Node with sub nodes.

=head1 DESCRIPTION

Create, read, update and delete child nodes.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
