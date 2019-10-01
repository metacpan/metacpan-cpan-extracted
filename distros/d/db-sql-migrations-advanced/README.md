# DB-SQL-Migrations-Advanced

This package provides a nice way to apply migrations from a directory.
It has the ability to also rollback migrations.

# Example

```perl
use DB::SQL::Migrations::Advanced;
my $migrator = DB::SQL::Migrations::Advanced->new(
    dbh     => $some_db_handle,
    folder  => $some_path,
);

$migrator->run;
```

```perl
use DB::SQL::Migrations::Advanced;
my $migrator = DB::SQL::Migrations::Advanced->new(
    dbh         => $some_db_handle,
    folder      => $some_path,
    rollback    => 1,
    steps       => 3,
);

$migrator->run;
```
