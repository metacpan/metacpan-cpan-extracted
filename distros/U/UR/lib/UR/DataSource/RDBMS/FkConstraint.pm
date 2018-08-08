use strict;
use warnings;

package UR::DataSource::RDBMS::FkConstraint;

use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS::FkConstraint',
    is => ['UR::DataSource::RDBMS::Entity'],
    dsmap => 'dd_fk_constraint',
    er_role => '',
    id_properties => [qw/data_source table_name r_table_name fk_constraint_name/],
    properties => [
        data_source                      => { type => 'varchar', len => undef, sql => 'data_source' },
        data_source_obj                  => { type => 'UR::DataSource', id_by => 'data_source'},
        namespace                        => { calculate_from => [ 'data_source'],
                                              calculate => q( (split(/::/,$data_source))[0] ) },
        fk_constraint_name               => { type => 'varchar', len => undef, sql => 'fk_constraint_name' },
        owner                            => { type => 'varchar', len => undef, is_optional => 1, sql => 'owner' },
        r_owner                          => { type => 'varchar', len => undef, is_optional => 1, sql => 'r_owner' },
        r_table_name                     => { type => 'varchar', len => undef, sql => 'r_table_name' },
        table_name                       => { type => 'varchar', len => undef, sql => 'table_name' },
        last_object_revision             => { type => 'timestamp', len => undef, sql => 'last_object_revision' },
    ],
    data_source => 'UR::DataSource::Meta',
);

#UR::Object::Type->bootstrap_object(__PACKAGE__);

sub _fk_constraint_column_class {
    if (shift->isa('UR::Object::Ghost')) {
        return 'UR::DataSource::RDBMS::FkConstraintColumn::Ghost';
    } else {
        return 'UR::DataSource::RDBMS::FkConstraintColumn';
    }
}

sub _table_classes {
    if (shift->isa('UR::Object::Ghost')) {
        return ('UR::DataSource::RDBMS::Table::Ghost', 'UR::DataSource::RDBMS::Table');
    } else {
        return ('UR::DataSource::RDBMS::Table', 'UR::DataSource::RDBMS::Table::Ghost');
    }
}

sub get_with_special_params {
    my($class,$rule,%args) = @_;

#$DB::single = 1;
    my $column_name = delete $args{'column_name'};
    my $r_column_name = delete $args{'r_column_name'};

    my @fks = $class->get($rule);
    return $class->context_return(@fks) unless ($column_name || $r_column_name);
    
    my @objects;
    foreach my $fk ( @fks ) {
        my %fkc_args = ( data_source => $fk->data_source,
                         table_name => $fk->table_name,
                         r_table_name => $fk->r_table_name,
                       );
        $fkc_args{'column_name'} = $column_name if $column_name;
        $fkc_args{'r_column_name'} = $r_column_name if $r_column_name;
        
        my @fkc = UR::DataSource::RDBMS::FkConstraintColumn->get(%fkc_args);

        push @objects,$fk if @fkc;
    }
    return $class->context_return(@objects);
}


sub create {
    my $class = shift;

    my $params = { $class->define_boolexpr(@_)->normalize->params_list };
    my $column_name = delete $params->{'column_name'};
    my $r_column_name = delete $params->{'r_column_name'};

    if ($column_name || $r_column_name) {
        $column_name = [ $column_name ] unless (ref $column_name);
        $r_column_name = [ $r_column_name ] unless (ref $r_column_name);

        unless (scalar @$column_name == scalar @$r_column_name) {
            Carp::confess('column_name list and r_column_name list must be the same length');
            return undef;
        }
    }
        
    my $self = $class->SUPER::create($params);

    while ($column_name && @$column_name) {
        my $col_name = shift @$column_name;
        my $r_col_name = shift @$r_column_name;
         
        my $col_class = $self->_fk_constraint_column_class;
        $col_class->create(data_source        => $self->data_source,
                           fk_constraint_name => $self->fk_constraint_name,
                           table_name         => $self->table_name,
                           column_name        => $col_name,
                           r_table_name       => $self->r_table_name,
                           r_column_name      => $r_col_name);
    }

    return $self;
}
   
     
        

sub get_related_column_objects {
    my($self,$prop_name) = @_;

    my @fkcs = UR::DataSource::RDBMS::FkConstraintColumn->get(
                  data_source        => $self->data_source,
                  table_name         => $self->table_name,
                  r_table_name       => $self->r_table_name,
                  fk_constraint_name => $self->fk_constraint_name,
               );
    return @fkcs unless $prop_name;

    return map { $_->$prop_name } @fkcs;
}

sub column_names {
    return shift->get_related_column_objects('column_name');
}

sub r_column_names {
    return shift->get_related_column_objects('r_column_name');
}

sub column_name_map {
my $self = shift;

    my @fkcs = $self->get_related_column_objects();
    return map { [ $_->column_name, $_->r_column_name ] } @fkcs;
}


sub _get_related_table {
my($self,$table_name) = @_;

    foreach my $try_class ( $self->_table_classes ) {
        my $table = $try_class->get(data_source => $self->data_source,
                                    table_name  => $table_name);
        return $table if $table;
    }
    return undef;
}


sub get_table {
my $self = shift;
    return $self->_get_related_table($self->table_name);
}

sub get_r_table {
my $self = shift;
    return $self->_get_related_table($self->r_table_name);
}



1;


=pod

=head1 NAME 

UR::DataSource::RDBMS::FkConstraint - metadata about a data source's foreign keys

=head1 DESCRIPTION

This class represents instances of foreign keys in a data source.  They are 
maintained by 'ur update classes' and stored in the namespace's MetaDB.

=cut
