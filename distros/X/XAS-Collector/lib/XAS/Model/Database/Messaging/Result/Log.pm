package XAS::Model::Database::Messaging::Result::Log;

our $VERSION = '0.01';

use XAS::Class
  version => $VERSION,
  base    => 'DBIx::Class::Core',
  mixin   => 'XAS::Model::DBM'
;

__PACKAGE__->load_components( qw/ InflateColumn::DateTime OptimisticLocking / );
__PACKAGE__->table( 'log' );
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_increment => 1,
        sequence          => 'log_id_seq',
        is_nullable       => 0
    },
    hostname => {
        data_type   => 'varchar',
        size        => 254,
        is_nullable => 0
    },
    datetime => {
        data_type   => 'timestamp with time zone',
        timezone    => 'local',
        is_nullable => 0
    },
    type => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    level => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    facility => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    process => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    message => {
        data_type   => 'varchar',
        size        => 256,
        is_nullable => 0
    },
    pid => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 0
    },
    tid => {
        data_type   => 'varchar',
        size        => 32,
        is_nullable => 0
    },
    msgnum => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 0
    },
    revision => {
        data_type   => 'integer',
        is_nullable => 1
    }
);

__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->optimistic_locking_strategy('version');
__PACKAGE__->optimistic_locking_version_column('revision');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'log_hostname_idx', fields => ['hostname']);
    $sqlt_table->add_index(name => 'log_datetime_idx', fields => ['datetime']);
    $sqlt_table->add_index(name => 'log_type_idx', fields => ['type']);
    $sqlt_table->add_index(name => 'log_level_idx', fields => ['level']);
    $sqlt_table->add_index(name => 'log_facility_idx', fields => ['facility']);
    $sqlt_table->add_index(name => 'log_process_idx', fields => ['process']);

}

sub table_name {
    return __PACKAGE__;
}

1;

__END__
 
=head1 NAME

XAS::Model::Database::Messaging::Result::Log - Table for XAS Log entries

=head1 DESCRIPTION

The definition for the log table.

=head1 FIELDS

=head2 id

An automatic incremental index.

=over 4

=item B<data type> - bigint

=item B<is nullable> - no

=back

=head2 hostname

The name of the host that the entry is from.

=over 4

=item B<data type> - varchar
 
=item B<size> - 254

=item B<is nullable> - no

=back

=head2 datetime

The date and time when the record was created. 

=over 4

=item B<data type> - timestamp with time zone
 
=item B<timezone> - local

=item B<is nullable> - no

=back

=head2 level

The level of the alert. 

=over 4

=item B<data type> - varchar
 
=item B<size> - 32

=item B<is nullable> - no

=back

=head2 facility

The facility of the alert. 

=over 4

=item B<data type> - varchar
 
=item B<size> - 32

=item B<is nullable> - no

=back

=head2 process

The name of the process that generated the alert. 

=over 4

=item B<data type> - varchar
 
=item B<size> - 32

=item B<is nullable> - no

=back

=head2 message

The message. 

=over 4

=item B<data type> - varchar
 
=item B<size> - 256

=item B<is nullable> - no

=back

=head2 pid

The process id of process that generated the alert. 

=over 4

=item B<data type> - varchar
 
=item B<size> - 16

=item B<is nullable> - no

=back

=head2 tid

The id for the thread of the process that generated the alert. 

=over 4

=item B<data type> - varchar
 
=item B<size> - 32

=item B<is nullable> - no

=back

=head2 msgnum

The message number of the message for the alert.

=over 4

=item B<data type> - varchar
 
=item B<size> - 16

=item B<is nullable> - no

=back

=head2 revision

Used by L<DBIx::Class::OptimisticLocking|https://metacpan.org/pod/DBIx::Class::Optimisticlocking>
to manage changes for this record.

=over 4

=item B<data type> - integer
 
=item B<is nullable> - yes

=back

=head1 METHODS

=head2 sqlt_deploy_hook($sqlt_table)

This method is used when a database schema is being generated. It can be used
to add additional features.

=over 4

=item B<$sqlt_table>

The DBIx::Class class for this table.

=back

=head2 table_name

Used by the helper functions mixed in from L<XAS::Model::DBM|XAS::Model::DBM>.

=head1 SEE ALSO

=over 4

=item L<XAS::Collector|XAS::Collector>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, <kevin@kesteb.us>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
