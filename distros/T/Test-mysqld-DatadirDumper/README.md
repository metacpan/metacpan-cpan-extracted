# NAME

Test::mysql::DatadirDumper - Dump mysql data directory for Test::mysqld

# SYNOPSIS

    use Test::mysql::DatadirDumper;
    my $datadir = 'path/to/datadir';
    Test::mysqld::DatadirDumper->new(
        datadir  => $datadir,
        ddl_file => 't/data/ddl.sql',
        fixtures => ['t/data/item.yml'],
    )->dump;

    # $datadir is usable as follows
    my $mysqld = Test::mysqld->new(
        my_cnf => {
          'skip-networking' => '',
        },
        copy_data_from => $datadir,
    );

# DESCRIPTION

Test::mysql::DatadirDumper is to dump data directory of mysql.
The directory is useful for [Test::mysql](http://search.cpan.org/perldoc?Test::mysql)'s `copy_data_from` option.

# CONSTRUCTOR

`new` is constructor and following options are available.

- `datadir:Str`

    Required. Data directory to be dumped.

- `ddl_file:Str`

    Required. Create statements for mysql.

- `fixtures:ArrayRef`

    Optional.

# METHOD

## `dump`

Dump data directory.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
