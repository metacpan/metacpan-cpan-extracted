use strict;
use warnings;

package UR::DataSource::RDBMS::Table;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS::Table',
    is => ['UR::DataSource::RDBMS::Entity'],
    dsmap => 'dd_table',
    id_properties => [qw/data_source table_name/],
    properties => [
        data_source                      => { type => 'varchar', len => undef, sql => 'data_source' },
        data_source_obj                  => { type => 'UR::DataSource', id_by => 'data_source'}, 
        namespace                        => { calculate_from => [ 'data_source'],
                                              calculate => q( (split(/::/,$data_source))[0] ) },
        owner                            => { type => 'varchar', len => undef, is_optional => 1, sql => 'owner' },
        table_name                       => { type => 'varchar', len => undef, sql => 'table_name' },
        er_type                          => { type => 'varchar', len => undef, sql => 'er_type', is_optional => 1 },
        last_ddl_time                    => { type => 'timestamp', len => undef, sql => 'last_ddl_time', is_optional => 1 },
        last_object_revision             => { type => 'timestamp', len => undef, sql => 'last_object_revision' },
        remarks                          => { type => 'varchar', len => undef, is_optional => 1, sql => 'remarks' },
        table_type                       => { type => 'varchar', len => undef, sql => 'table_type' },
    ],
    data_source => 'UR::DataSource::Meta',
);

sub _related_class_name {
    my($self,$subject) = @_;

    my $class = ref($self);  
    
    # FIXME  This seems kinda braindead, but is probably faster than using s///
    # Is it really the right thing?
    my $pos = index($class, '::Table');  
    substr($class, $pos + 2, 5, $subject);  # +2 to keep the "::"

    return $class;
}
   
sub _fk_constraint_class {
    return shift->_related_class_name('FkConstraint');
}

sub _pk_constraint_class {
    return shift->_related_class_name('PkConstraintColumn');
}
    
sub _unique_constraint_class {
    return shift->_related_class_name('UniqueConstraintColumn');
}

sub _table_column_class {
    return shift->_related_class_name('TableColumn');
}

sub _bitmap_index_class { 
    return shift->_related_class_name('BitmapIndex');
}

sub columns {
    my $self = shift;

    my $col_class = $self->_table_column_class;
    return $col_class->get(data_source => $self->data_source, table_name => $self->table_name);
}

sub column_names {
    return map { $_->column_name } shift->columns;
}

sub primary_key_constraint_columns {
    my $self = shift;

    my $pk_class = $self->_pk_constraint_class;
    my @pks = $pk_class->get(data_source => $self->data_source, table_name  => $self->table_name);
    my @pks_with_rank = map { [ $_->rank, $_ ] } @pks;
    return map { $_->[1] }
           sort { $a->[0] <=> $b->[0] }
           @pks_with_rank;
}


sub primary_key_constraint_column_names {
    return map { $_->column_name } shift->primary_key_constraint_columns;
}


sub fk_constraints {
    my $self = shift;

    my $fk_class = $self->_fk_constraint_class;
    my @fks = $fk_class->get(data_source => $self->data_source, table_name => $self->table_name);
    return @fks;
}

sub fk_constraint_names {
    return map { $_->fk_constraint_name } shift->fk_constraints;
}


sub ref_fk_constraints {
    my $self = shift;

    my $fk_class = $self->_fk_constraint_class;
    my @fks = $fk_class->get(data_source => $self->data_source, r_table_name => $self->table_name);
    return @fks;
}

sub ref_fk_constraint_names {
    return map { $_->fk_constraint_name } shift->ref_fk_constraints;
}


sub unique_constraint_column_names {
    my($self,$constraint) = @_;

    my @c;
    if ($constraint) {
        @c = $self->unique_constraints(constraint_name => $constraint);
    } else {
        @c = $self->unique_constraints();
    }
    my %names = map {$_->column_name => 1 } @c;
    return keys %names;
}

sub unique_constraint_names {
    my $self = shift;

    my %names = map { $_->constraint_name => 1 } $self->unique_constraints;
    return keys %names;
}

sub unique_constraints {
    my $self = shift;

    my $uc_class = $self->_unique_constraint_class;
    my @c = $uc_class->get( data_source => $self->data_source, table_name => $self->table_name, @_);

    return @c;
}

sub bitmap_indexes {
    my $self = shift;

    my $bi_class = $self->_bitmap_index_class;
    my @bi = $bi_class->get(data_source => $self->data_source, table_name => $self->table_name);
    return @bi;
}


sub bitmap_index_names {
    return map { $_->bitmap_index_name } shift->bitmap_indexes;
}

# FIXME Due to a "bug" in getting class objects, you need to pass in namespace => 'name' as
# arguments to get this to work.
sub handler_class {
    my $self = shift;

    return UR::Object::Type->get(table_name => $self->table_name, @_);
}

sub handler_class_name {
    my $self = shift;

    return $self->handler_class(@_)->class_name;
}

sub delete {
    my $self = shift;

    my @deleteme = ( $self->fk_constraints,
                     $self->bitmap_indexes,
                     $self->primary_key_constraint_columns,
                     $self->columns, 
                   );
    for my $obj ( @deleteme ) {
        $obj->delete;
        unless ($obj->isa('UR::DeletedRef')) {
            Carp::confess("Failed to delete $obj ".$obj->{'id'});
        }
    }
    $self->SUPER::delete();
    return $self;
}
    


1;

=pod

=head1 NAME

UR::DataSource::Meta::RDBMS::Table - Object-oriented class for RDBMS table objects.

=head1 SYNOPSIS

  $t = UR::DataSource::Meta::RDBMS::Table->get(
                      data_source => 'Namespace::DataSource::Name',
                      table_name => 'MY_TABLE_NAME');
  @c = $t->column_names;
  @f = $t->fk_constraint_names;

=head1 DESCRIPTION

Objects of this class represent a table in a database.  They are 
primarily used by the class updating logic in the command line tool
C<ur update classes>, but can be retrieved and used in any application.
Their instances come from from the MetaDB (L<UR::DataSource::Meta>) which
is partitioned and has one physical database per Namespace.

=head2 Related Metadata Methods

=over 4

=item @col_objs = $t->columns();

=item @col_names = $t->column_names();

=item @fk_objs = $t->fk_constraints();

=item @fk_names = $t->fk_constraint_names();

=item @ref_fk_objs = $t->ref_fk_constraints();

=item @ref_fk_names = $t->ref_fk_constraint_names();

=item @pk_objs = $t->primary_key_constraint_columns();

=item @pk_col_names = $t->primary_key_constraint_column_names();

=item @bi_objs = $t->bitmap_indexes();

=item @bi_names = $t->bitmap_index_names();

Return related metadata objects (or names) for the given table object.

=back

=cut

