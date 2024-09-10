package Tree::Navigator::Node::DBI;
use utf8;
use Moose;
use namespace::autoclean;
extends 'Tree::Navigator::Node';

use DBI;

use Params::Validate qw/validate/;

sub MOUNT {
  my ($class, $mount_args) = @_;
  my @mount_point = %{$mount_args->{mount_point} || {}};
  $mount_args->{mount_point} = validate(@mount_point , {
    dbh  => {isa => 'DBI::db'},
   });
}

sub is_parent { return 1 }

sub _children {
  my $self  = shift;
  return [qw/Tables Rows/];
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
  my $dbh   = $self->mount_point->{dbh};
  return {dbh   => $dbh->{Name}};
}


__PACKAGE__->meta->make_immutable;

package Tree::Navigator::Node::DBI::Tables;
use Moose;
use namespace::autoclean;
extends 'Tree::Navigator::Node';

sub is_parent { return 1 }

sub _children {
  my $self  = shift;
  my $dbh = $self->mount_point->{dbh};

  my %args 
    = (catalog => undef, schema => undef, table => undef, type => "TABLE");
  my $tables_sth = $dbh->table_info(@args{qw/catalog schema table type/});
  my $tables     = $tables_sth->fetchall_arrayref({TABLE_NAME => 1});
  return [map {$_->{TABLE_NAME}} @$tables];
}

sub _child {
  my ($self, $table_name)  = @_;
  return Tree::Navigator::Node::DBI::Table->new(
    mount_point => $self->mount_point,
    path        => ($self->path . "/" . $table_name),
   );
}

package Tree::Navigator::Node::DBI::Table;
use Moose;
use namespace::autoclean;
extends 'Tree::Navigator::Node';

sub is_parent { return 1 }

sub _children {
  my $self  = shift;
  my $dbh   = $self->mount_point->{dbh};
  my $table = $self->last_path;

  my %args 
    = (catalog => undef, schema => undef, table => $table, column => undef);
  my $columns_sth = $dbh->column_info(@args{qw/catalog schema table column/});
  my $columns     = $columns_sth->fetchall_arrayref({COLUMN_NAME => 1});
  return [map {$_->{COLUMN_NAME}} @$columns];
}

sub _child {
  my ($self, $col_name)  = @_;
  return Tree::Navigator::Node::DBI::Column->new(
    mount_point => $self->mount_point,
    path        => ($self->path . "/" . $col_name),
   );
}

sub _attributes {
  my $self  = shift;
  my $dbh   = $self->mount_point->{dbh};
  my $table = $self->last_path;
  my %args = (catalog => undef, schema => undef, table => $table);
  my @primary_key = $dbh->primary_key(@args{qw/catalog schema table/});
  return {primary_key => join(";", @primary_key) || ''};
}

package Tree::Navigator::Node::DBI::Column;
use Moose;
use namespace::autoclean;
extends 'Tree::Navigator::Node';

sub is_parent { return 0  }
sub _children { return [] }

sub _attributes {
  my $self  = shift;
  my $dbh   = $self->mount_point->{dbh};
  my ($col, $table) = reverse split "/", $self->path;
  my %args 
    = (catalog => undef, schema => undef, table => $table, column => $col);
  my $columns_sth = $dbh->column_info(@args{qw/catalog schema table column/});
  my $col_info    = $columns_sth->fetchrow_hashref;
  my %attrs;
  while (my ($col, $info) = each %$col_info) {
    $attrs{$col} = $info if $info;
  }
  return \%attrs;
}


package Tree::Navigator::Node::DBI::Rows;
use Moose;
use namespace::autoclean;
extends 'Tree::Navigator::Node';

sub is_parent { return 1 }

sub _children {
  my $self  = shift;
  my $dbh = $self->mount_point->{dbh};

  # TODO
  return [];
}


1; # End of Tree::Navigator::Node::DBI



__END__

=encoding utf8

=head1 NAME

Tree::Navigator::Node::DBI - navigating in a DBI database

=cut


