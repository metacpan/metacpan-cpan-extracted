package Tree::Navigator::Node::DBIDM;
use utf8;
use Moose;

use DBI;
use DBIx::DataModel;
use Params::Validate qw/validate/;
use namespace::autoclean;

extends 'Tree::Navigator::Node';


sub MOUNT {
  my ($class, $mount_args) = @_;
  my @mount_point = %{$mount_args->{mount_point} || {}};
  $mount_args->{mount_point} = validate(@mount_point , {
    schema  => {isa => 'DBIx::DataModel::Schema'},
   });

  $mount_args->{mount_point}{schema}->dbh
    or die "schema has no dbh";
}


sub _children {
  my $self  = shift;
  return [qw/Table Row/];
}


sub _child {
  my ($self, $child_path) = @_;
  my $class = ref $self;
  my $subclass = $class . "::" . $child_path;
  return $subclass->new(mount_point => $self->mount_point,
                        path        => $child_path);
}

sub _attributes {
  my $self  = shift;
  my $schema = $self->mount_point->{schema};
  return {class => (ref $schema || $schema),
          dbh   => $schema->dbh->{Name}};
}


__PACKAGE__->meta->make_immutable;

package Tree::Navigator::Node::DBIDM::Tables;
use strict;
use warnings;

sub _children {
  my $self  = shift;
  my $schema = $self->mount_point->{schema};
  return [map {$_->name} $schema->meta->tables];
}

sub _child {
  my ($self, $child_name)  = @_;
  return Tree::Navigator::Node::DBIDM::Table->new(
    mount_point => $self->mount_point,
    path        => ($self->path . "/" . $child_name),
   );
}

package Tree::Navigator::Node::DBIDM::Table;
use strict;
use warnings;




1; # End of Tree::Navigator::Node::DBIDM


__END__

=encoding utf8

=head1 NAME

Tree::Navigator::Node::DBIDM - 

=cut


