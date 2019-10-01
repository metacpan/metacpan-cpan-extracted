package DB::SQL::Migrations::Advanced;
use Mojo::Base -base;

use DBIx::MultiStatementDo;
use File::Basename;
use File::Slurp;

our $VERSION = '0.0.1';

has 'applied_migrations' => sub {
    my $self = shift;

    my $sth = $self->dbh->prepare(sprintf('SELECT * FROM %s', $self->table));

    $sth->execute;

    # Example result:
    # { 'migration_name_1.sql' => { date_applied => '2019-09-30', name => 'migration_name.sql', batch => 3 } }
    my $applied_migrations = $sth->fetchall_hashref('name');

    $sth->finish;

    return $applied_migrations;
};

has 'batch' => sub {
    my $self = shift;

    my $sth = $self->dbh->prepare(sprintf('SELECT `batch` FROM %s ORDER BY `batch` DESC LIMIT 1', $self->table));

    $sth->execute;

    my @rows = $sth->fetchrow_array;
    my $batch = $rows[0];

    $sth->finish;

    return $batch;
};

has 'dbh';

has 'folder' => sub { 'db_migrations' };

has 'migration_files_in_order' => sub {
    my $self = shift;
    
    my $dir = $self->folder;
    my @migration_files_in_order = sort <$dir/*.sql>;

    return \@migration_files_in_order;
};

has 'pending_migrations' => sub {
    my $self = shift;
    my @pending_migrations;

    foreach my $migration_file (@{ $self->migration_files_in_order }) {
        my $migration_key = $self->_migration_key($migration_file);

        push(@pending_migrations, $migration_file) if (!$self->applied_migrations->{$migration_key});
    }

    return \@pending_migrations;
};

has 'rollback' => sub { 0 };

has 'steps' => sub { 1 };

has 'table' => sub { 'schema_migrations' };

sub apply {
    my $self = shift;

    my @pending_migrations = @{ $self->pending_migrations };

    if (scalar(@pending_migrations)) {
        foreach my $migration (@pending_migrations) {
            print "Appling migration $migration\t\t";

            $self->_run_migration($self->_sql($migration));
            $self->_insert_into_schema_migrations($migration);

            print "OK\n";
        }

        print "\nDONE\n";

        return 1;
    }

    print "Nothing to migrate\n";

    return 1;
}

sub create_migrations_table {
    my $self = shift;

    my $table_name = $self->table;

    my $sql = "CREATE TABLE IF NOT EXISTS $table_name (
            `name` varchar(255) NOT NULL,
            `date_applied` datetime NOT NULL,
            `batch` int(11) NOT NULL DEFAULT '0',
            PRIMARY KEY (`name`)
        );
    ";

    $self->dbh->do($sql);
}

sub revert {
    my $self = shift;

    my $batch = $self->batch;
    my $steps = $self->steps;

    while ($steps--) {
        print "Reverting all migrations for batch #$batch\n";

        my $sth = $self->dbh->prepare(sprintf('SELECT `name` FROM %s WHERE `batch` = ? ORDER BY `date_applied` DESC', 
            $self->table,
        ));

        $sth->execute($batch);

        # Example result:
        # [['migration_3.sql'], ['migration_2.sql']]
        my $revert_migrations = $sth->fetchall_arrayref;

        $sth->finish;

        foreach my $row (@$revert_migrations) {
            my $migration = $row->[0];

            print "Reverting migration $migration\t\t";

            $self->_revert_migration($self->folder . '/'. $migration);
            $self->_remove_from_schema_migrations($migration);

            print "OK\n";
        }
    
        $batch--;
    }

    print "\nDONE\n";
}

sub run {
    my $self = shift;

    $self->create_migrations_table();

    if ($self->rollback) {
        return $self->revert;
    }

    return $self->apply;
}

sub _insert_into_schema_migrations {
    my ($self, $filename) = @_;

    my $migration_key = $self->_migration_key($filename);

    $self->dbh->do(sprintf('INSERT INTO %s (`name`, `date_applied`, `batch`) VALUES (?, NOW(), ?)',
        $self->table,
    ), undef, $migration_key, $self->batch + 1);

    $self->dbh->commit;
}

sub _migration_key {
    my ($self, $filename) = @_;

    # Use filename for the key
    my ($migration_key, $directories, $suffix) = fileparse($filename);

    return $migration_key;
}

sub _revert_migration {
    my ($self, $filename) = @_;

    my $sql = $self->_sql($filename);

    $self->_run_migration($sql);
}

sub _remove_from_schema_migrations {
    my ($self, $filename) = @_;

    my $migration_key = $self->_migration_key($filename);

    $self->dbh->do(sprintf('DELETE FROM %s WHERE `name` = ?', $self->table), undef, $migration_key);

    $self->dbh->commit;
}

sub _run_migration {
    my ($self, $sql) = @_;

    if (!$sql) {
        print "Got empty sql. Skipping\n";

        return;
    }

    my $batch = DBIx::MultiStatementDo->new(
        dbh      => $self->dbh,
        rollback => 0
    );

    $batch->dbh->{AutoCommit} = 0;
    $batch->dbh->{RaiseError} = 1;

    eval {
        $batch->do( $sql );
        $batch->dbh->commit;
        1
    } or do {
        print "FAILED\n";
        print "$@ \n";
        eval { $batch->dbh->rollback };

        die "Exiting due to failed migrations \n";
    };
}

sub _sql {
    my ($self, $filename) = @_;

    my $sql = read_file($filename);
    my ($up, $down) = split("-- DOWN\n", $sql);

    if ($self->rollback) {
        return $down;
    }

    return $up;
}

1;

=encoding utf8

=head1 NAME

DB::SQL::Migrations::Advanced - apply/rollback migrations from a directory

=head1 SYNOPSIS

    use DB::SQL::Migrations::Advanced;
    my $migrator = DB::SQL::Migrations::Advanced->new(
        dbh     => $some_db_handle,
        folder  => $some_path,
    );

    $migrator->run;

    use DB::SQL::Migrations::Advanced;
    my $migrator = DB::SQL::Migrations::Advanced->new(
        dbh         => $some_db_handle,
        folder      => $some_path,
        rollback    => 1,
        steps       => 3,
    );

    $migrator->run;

=head1 DESCRIPTION

L<DB::SQL::Migrations::Advanced> provides a nice way to apply migrations from a directory.
It has the ability to also rollback migrations.

=head1 ATTRIBUTES

L<DB::SQL::Migrations::Advanced> inherits all attributes from
L<Mojo::Base> and implements the following new ones.

=head2 applied_migrations

    Tell list of already applied migrations.

=head2 batch

    Tell value for the last batch of migrations.

=head2 dbh

    A database handler. (required)

=head2 folder

    Tell name of the folder that holds the migration files.
    Defaults to 'db_migrations'.

=head2 migration_files_in_order

    Migration files in alphabetical order.

=head2 pending_migrations

    Migrations that needs to be applied.

=head2 rollback

    Tell if you are looking to rollback some migrations.
    Defaults to 0.

=head2 steps

    In case you are looking to rollback mirations, you can specify how many steps.
    Defaults to 1.

=head2 table

    The name of the table that records the applied migrations.
    Defaults to 'schema_migrations'.

=head1 METHODS

L<DB::SQL::Migrations::Advanced> inherits all methods from
L<Mojo::Base> and implements the following new ones.

=head2 apply

    $migrator->apply

Apply all pending migrations.

=head2 create_migrations_table

    $migrator->create_migrations_table

Create migrations table if not exists.

=head2 revert

    $migrator->revert

Revert migrations.

=head2 run

    $migrator->run

Run migrations.
Will decide if it needs to apply/rollback based on given attributes.

=head2 _insert_into_schema_migrations

    $migrator->_insert_into_schema_migrations($filename)

Record migration filename as being applied.

=head2 _migration_key

    my $migration_key = $migrator->_migration_key($filename)

Retrieve the migration_key for a filename.

=head2 _revert_migration

    $migrator->_revert_migration($filename)

Revert migrations from filename.

=head2 _remove_from_schema_migrations

    $migrator->_remove_from_schema_migrations($filename)

Remove migration filename from table.

=head2 _run_migration

    $migrator->_run_migration($sql)

Run an sql.

=head2 _sql

    my $sql = $migrator->_sql($filename)

Retrieve the sql that needs to be run from a migration filename, based on apply/rollback.


=head1 AUTHOR

Adrian Crisan, <adrian.crisan88@gmail.com>

=cut
