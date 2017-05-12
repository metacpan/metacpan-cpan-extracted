package XAS::Model::Schema;

use strict;
use warnings;

our $VERSION = '0.01';

use Badger::Filesystem 'File';
use XAS::Lib::Modules::Environment;
use base 'DBIx::Class::Schema::Config';

BEGIN {

    # ---------------------------------------------------------------------
    # Define DBIx::Class::Schema::Config configuration file locations
    #
    # Format of the configuration file is as follows:
    #
    # [progress]             - corresponds to what is given to opendb()
    # dbname = monitor       - name of the database
    # dsn = SQLite           - corresponds to the dbd driver
    # username = username    - the user context to use
    # password = password    - the password for that context
    #
    # When using ODBC with a user level DSN or a dynamic connection, you
    # should add the following items:
    #
    # driver = SQL Server
    # server = localhost,1234
    #
    # When using PostgresSQL (Pg), you can add the following items:
    #
    # port = 5432
    # host = localhost
    # sslmode = something
    # options = something
    #
    # Or a service name, which is not compatiable with the above.
    #
    # service = service name
    # 
    # There can be multiple stanzas, the first one that matches is used.
    # ---------------------------------------------------------------------

    my $env = XAS::Lib::Modules::Environment->new();
    my $path = $env->root;

    # -----------------------------------------------------------------
    # Defining where our database.ini file could be
    # -----------------------------------------------------------------

    if ($^O eq "MSWin32") {

        __PACKAGE__->config_paths([(
            File($path, 'etc', 'database')->path,
            File($ENV{USERPROFILE}, 'database')->path,
        )]);

    } else {

        __PACKAGE__->config_paths([(
            File($path, 'etc', 'xas', 'database')->path,
            File($ENV{HOME}, '.database')->path,
        )]);

    }

    # ---------------------------------------------------------------------
    # Defining our DBIx::Class exception handler
    # ---------------------------------------------------------------------

    __PACKAGE__->exception_action(\&XAS::Model::Schema::dbix_exceptions);

}

# ---------------------------------------------------------------------
# Set some default configuration options
# ---------------------------------------------------------------------

sub filter_loaded_credentials {
    my $class        = shift;
    my $config       = shift;
    my $connect_args = shift;

    $config = {} if ($config eq '');

    $config->{dbi_attr}->{AutoCommit} = 1;
    $config->{dbi_attr}->{PrintError} = 0;
    $config->{dbi_attr}->{RaiseError} = 1;

    if ($config->{dsn} eq 'SQLite') {

        $config->{dbi_attr}->{sqlite_use_immediate_transaction} = 1;
        $config->{dbi_attr}->{sqlite_see_if_its_a_number} = 1;
        $config->{dbi_attr}->{on_connect_call} = 'use_foreign_keys';

        $config->{dsn} = "dbi:$config->{dsn}:dbname=$config->{dbname}";

    } elsif ($config->{dsn} eq 'ODBC') {

        # http://dolio.lh.net/~apw/doc/HOWTO/HOWTO-Connect_Perl_to_SQL_Server.pdf
        #
        # a user level DSN or a dynamic connection needs the following:
        #
        # dbi:ODBC:Driver={driver};Server=server;Database=dbname
        #
        # a system level DSN needs the following:
        #
        # dbi:ODBC:dbname
        # 

        if (defined($config->{driver})) {

            $config->{dsn} = sprintf(
                "dbi:%s:Driver={%s};Database=%s;Server=%s",
                $config->{dsn}, $config->{driver},
                $config->{dbname}, $config->{server}
            );

        } else {

            $config->{dsn} = "dbi:$config->{dsn}:$config->{dbname}";
   
        }

    } elsif ($config->{dsn} eq 'Pg') {

        unless (defined($config->{service})) {

            $config->{dsn}  = "dbi:$config->{dsn}:dbname=$config->{dbname}";
            $config->{dsn} .= ";host=$config->{host}" if (defined($config->{host}));
            $config->{dsn} .= ";port=$config->{port}" if (defined($config->{port}));
            $config->{dsn} .= ";options=$config->{options}" if (defined($config->{options}));
            $config->{dsn} .= ";sslnode=$config->{sslmode}" if (defined($config->{sslmode}));

        } else {

            $config->{dsn} = "dbi:$config->{dsn}:service=$config->{service}";

        }

    } else {

        $config->{dsn} = "dbi:$config->{dsn}:dbname=$config->{dbname}";

    }

    return $config;

}

sub dbix_exceptions {
    my $error = shift;

    $error =~ s/dbix.class error - //;

    my $ex = XAS::Exception->new(
        type => 'dbix.class',
        info => sprintf("%s", $error)
    );

    $ex->throw;

}

sub opendb {
    my $class = shift;

    return $class->connect(@_);

}

1;

__END__

=head1 NAME

XAS::Model::Schema - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Model::Schema;
 use XAS::Mode::Database;

 XAS::Model::Database->schema('XAS::Model::Database::Testing');
 my $schema = XAS::Model::Schema->opendb('testing');

=head1 DESCRIPTION

This module loads database connection information from a file. This
file may be located in the users home directory or in the XAS config directory.
With the usual convention of the user specific file will override the global
generic file. This file is named database.ini.

Format of the configuration file is as follows:

 [progress]             - corresponds to what is given to opendb()
 dbname = monitor       - name of the database
 dsn = SQLite           - corresponds to the dbd driver
 user = username        - the user context to use
 password = password    - the password for that context

When using ODBC with a user level DSN or a dynamic connection, you
should add the following items:

 driver = SQL Server
 server = localhost,1234 - (host,port)

When using PostgresSQL (Pg), you can add the following items:

 port = 5432
 host = localhost
 sslmode = something
 options = something

Or a service name, which is not compatible with the above.

 service = service name

There can be multiple stanzas, the first one that matches is used.

=head1 METHODS

=head2 opendb($database)

This method makes the connection to the database. It takes these parameters:

=over 4

=item B<$database>

The name of the database. This is defined in the database.ini file.

=back

=head2 dbix_exceptions($error)

This method converts the internal DBIx::Class exceptions into a XAS exception.
It takes these parameters:

=over 4

=item B<$error>

The error string supplied by DBIx::Class

=back

=head2 filter_loaded_credentials($class, $config, $connect_args)

This method is an override for the one provided by L<DBIx::Class::Schema::Config|https://metacpan.org/pod/DBIx::Class::Schema::Config>.
It sets various defaults to be used when connecting to certain databases.
There are defaults for SQLite, PostgreSQL and ODBC connections. The following
parameters are supplied from DBIx::Class::Schema::Config.

=over 4

=item B<$class>

=item B<$config>

=item B<$connecti_args>

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Model|XAS::Model>

=item L<XAS|XAS>

=item L<DBIx::Class::Schema::Config|https://metacpan.org/pod/DBIx::Class::Schema::Config>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
