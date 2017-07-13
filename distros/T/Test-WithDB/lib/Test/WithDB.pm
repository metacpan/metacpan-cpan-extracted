package Test::WithDB;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use DBI;
use POSIX qw(strftime);
use Test::More 0.98 ();
use UUID::Random;

use Mo qw(build default);

has config_path    => (is => 'ro');
has config_profile => (is => 'ro');
has name_pattern   => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;

    $self->{config_path}    //= $ENV{TWDB_CONFIG_PATH};
    $self->{config_profile} //= $ENV{TWDB_CONFIG_PROFILE};
    $self->{name_pattern}   //= $ENV{TWDB_NAME_PATTERN} // 'testdb_%Y%m%d_%H%M%S_%u';

    if (!$self->{config_path}) {
        # we're being tiny here, otherwise we'll use File::HomeDir
        my $home = $ENV{HOME} // $ENV{HOMEPATH}
            or die "Can't determine home directory";
        for ("$home/test-withdb.ini", "$home/twdb.ini") {
            $self->{config_path} = $_;
            last if -f $_;
        }
    }

    $self->{_created_dbs} = [];
    $self->_init;
}

sub _read_config {
    require Config::IOD::Reader;

    my $self = shift;
    my $path = $self->{config_path};
    my $cfg0 = Config::IOD::Reader->new->read_file($path);
    my $profile = $self->{config_profile} // 'GLOBAL';
    my $cfg = $cfg0->{$profile};
    die "Config profile '$profile' not found in config file '$path'"
        unless $cfg;
    for (qw/admin_dsn admin_user admin_pass
            user_dsn user_user user_pass/) {
        die "Required config '$_' not defined in config file '$path'"
            unless exists $cfg->{$_};
    }
    $self->{_config} = $cfg;
}

sub _init {
    my $self = shift;

    $self->_read_config;
    my $cfg = $self->{_config};

    my ($driver) = $cfg->{admin_dsn} =~ /^dbi:([^:]+)/;
    if ($driver !~ /^(Pg|mysql|SQLite)$/) {
        die "Sorry, DBI driver '$driver' is not supported yet";
    }

    $self->{_admin_dbh} = DBI->connect(
        $cfg->{admin_dsn}, $cfg->{admin_user}, $cfg->{admin_pass},
        {RaiseError=>1});
    $self->{_driver} = $driver;
}

sub _new_name {
    my $self = shift;

    my $uuid = do {
        local $_ = UUID::Random::generate();
        s/-//g;
        $_;
    }; # 32 character hex

    my $time = strftime("%Y%m%d%H%M%S", localtime);

    my %patterns = (
        '%' => '%',
        'U' => $uuid,
        'u' => substr($uuid,  0, 8),
        'Y' => substr($time,  0, 4),
        'm' => substr($time,  4, 2),
        'd' => substr($time,  6, 2),
        'H' => substr($time,  8, 2),
        'M' => substr($time, 10, 2),
        'S' => substr($time, 12, 2),
    );

    my $dbname = $self->{name_pattern};
    $dbname =~ s!\%(.)!exists $patterns{$1} ? $patterns{$1} : "%$1"!eg;
    $dbname;
}

sub create_db {
    my $self = shift;

    my $dbname = $self->_new_name;
    my $cfg = $self->{_config};

    # XXX allow specifying more options
    Test::More::note("Creating test database '$dbname' ...");
    log_debug     ("Creating test database '$dbname' ...");
    if ($self->{_driver} eq 'Pg') {
        $self->{_admin_dbh}->do("CREATE DATABASE $dbname OWNER ".
                                    "$cfg->{user_user}");
    } elsif ($self->{_driver} eq 'mysql') {
        $self->{_admin_dbh}->do("CREATE DATABASE $dbname");
        $self->{_admin_dbh}->do("GRANT ALL ON $dbname.* TO ".
                                    "'$cfg->{user_user}'\@'localhost'");
    } elsif ($self->{_driver} eq 'SQLite') {
        # we don't need to do anything
    }
    push @{ $self->{_created_dbs}  }, $dbname;

    my $dsn = $cfg->{user_dsn};
    $dsn =~ s/dbname=[^;]*//;
    if ($self->{_driver} eq 'SQLite') {
        my $dir = $cfg->{sqlite_db_dir} // '.';
        $dsn .= ";dbname=$dir/$dbname";
    } else {
        $dsn .= ";dbname=$dbname";
    }

    {
        my $sql = $cfg->{init_sql_admin};
        last unless $sql;
        my $dbh = DBI->connect($dsn, $cfg->{admin_user}, $cfg->{admin_pass},
                               {RaiseError=>1});
        for my $st (ref($sql) eq 'ARRAY' ? @$sql : ($sql)) {
            Test::More::note("Initializing database by admin: $st ...");
            log_debug     ("Initializing database by admin: $st ...");
            $dbh->do($st);
        }
    }

    my $dbh = DBI->connect($dsn, $cfg->{user_user}, $cfg->{user_pass},
                           {RaiseError=>1});
    {
        my $sql = $cfg->{init_sql_user};
        last unless $sql;
        for my $st (ref($sql) eq 'ARRAY' ? @$sql : ($sql)) {
            Test::More::note("Initializing database by test user: $st ...");
            log_debug     ("Initializing database by test user: $st ...");
            $dbh->do($st);
        }
    }
    push @{ $self->{_dbhs} }, $dbh;
    $dbh;
}

sub drop_dbs {
    my $self = shift;

    my $cfg = $self->{_config};
    my $dbs = $self->{_created_dbs};

    for (0..@$dbs-1) {
        my $dbname = $dbs->[$_];
        my $dbh = $self->{_dbhs}[$_];
        $dbh->disconnect;
        Test::More::note("Dropping test database '$dbname' ...");
        log_debug     ("Dropping test database '$dbname' ...");
        if ($self->{_driver} eq 'SQLite') {
            my $dir = $cfg->{sqlite_db_dir} // '.';
            my $path = "$dir/$dbname";
            unlink $path or die "Can't unlink file '$path': $!";
        } else {
            $self->{_admin_dbh}->do("DROP DATABASE $dbname");
        }
    }
}

sub created_dbs {
    my $self = shift;
    @{ $self->{_created_dbs} };
}

sub done {
    my $self = shift;
    return if $self->{_done}++;

    my $passing = Test::More->builder->is_passing;

    if ($passing && !$ENV{TWDB_KEEP_TEMP_DBS}) {
        $self->drop_dbs;
    } else {
        my $dbs = $self->{_created_dbs};
        if (@$dbs) {
            if ($passing) {
                Test::More::diag(
                    "TWDB_KEEP_TEMP_DBS is set, not removing databases created during testing ".
                        "(".join(", ", @$dbs).")");
                log_info(
                    "TWDB_KEEP_TEMP_DBS is set, not removing databases created during testing ".
                        "(".join(", ", @$dbs).")");
            } else {
                Test::More::diag(
                    "Tests failing, not removing databases created during testing ".
                        "(".join(", ", @$dbs).")");
                log_error(
                    "Tests failing, not removing databases created during testing ".
                        "(".join(", ", @$dbs).")");
            }
        }
    }
}

sub DESTROY {
    my $self = shift;
    $self->done;
}

1;
# ABSTRACT: Framework for testing application using database

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::WithDB - Framework for testing application using database

=head1 VERSION

This document describes version 0.09 of Test::WithDB (from Perl distribution Test-WithDB), released on 2017-07-10.

=head1 SYNOPSIS

In your C<~/test-withdb.ini>:

 admin_dsn ="dbi:Pg;host=localhost"
 admin_user="postgres"
 admin_pass="adminpass"

 user_dsn ="dbi:Pg;host=localhost"
 user_user="someuser"
 user_pass="somepass"

 # optional: SQL statements to initialize DB by test user after created
 init_sql_admin=CREATE EXTENSION citext

 # optional: SQL statements to initialize DB by test user after created
 init_sql_user=

In your test file:

 use Test::More;
 use Test::WithDB;

 my $twdb = Test::WithDB->new(
     #config_path => '...', # defaults to TWDB_CONFIG_PATH env or ~/test-withdb.ini or ~/twdb.ini
     #config_profile => '...', # defaults to TWDB_CONFIG_PROFILE env or undef
     #name_pattern => '...', # defaults to TWDB_NAME_PATTERN env or 'testdb_%u'
 );

 my $dbh = $twdb->create_db; # create db with random name

 # do stuffs with dbh

 my $dbh2 = $twdb->create_db; # create another db

 # do more stuffs

 $twdb->done; # will drop all created databases, unless tests are not passing

=head1 DESCRIPTION

This class (C<Test::WithDB>, or TWDB for short) provides a simple framework for
testing application that requires database. It is meant to work with
L<Test::More> (or to be more exact, any L<Test::Builder>-based module). It
offers an easy way to create random databases and initialize them so they are
ready for testing. More functionalities will be added in the future.

To work with TWDB, first, you supply a configuration file containing admin and
normal user's connection information (the admin info is needed to create
databases). Then, you call one or more C<create_db()> to create one or more
databases for testing. The database will be created with random names.

At the end of testing, when you call C<< $twdb->done >>, the class will do this
check:

 if (Test::More->builder->is_passing) {
     # drop all created databases
 } else {
    diag "Tests failing, not removing databases created during testing: ...";
 }

So when testing fails, you can inspect the database.

Currently only supports Postgres, MySQL, and SQLite; and tested mostly with
Postgres.

=for Pod::Coverage ^(BUILD)$

=head1 CONFIGURATION

=head2 *admin_dsn => str

=head2 *admin_user => str

=head2 *admin_pass => str

=head2 *user_dsn => str

=head2 *user_user => str

=head2 *user_pass => str

=head2 init_sql_admin => str|array

=head2 init_sql_user => str|array

=head2 sqlite_db_dir => str (default: .)

=head1 ATTRIBUTES

=head2 config_path => str (default: C<~/test-withdb.ini> or C<~/twdb.ini>).

Path to configuration file. File will be read using L<Config::IOD::Reader>.

=head2 config_profile => str (default: GLOBAL)

Pick section in configuration file to use.

=head2 name_pattern => str (default: C<testdb_%Y%m%d_%H%M%S_%u>)

Pattern for random database name, where several sprintf-/strftime-style C<%X>
directives are recognized:

=over

=item * C<%%>

Literal percentage sign

=item * C<%U>

32-character random UUID hex. It is recommended that at least you add either
this or C<%u>.

=item * C<%u>

8-character prefix of random UUID hex. It is recommended that at least you add
either this or C<%u>. If you use C<%u> instead of C<%U>, it is recommended that
you also add timestamp.

=item * C<%Y>

4-digit year of current time.

=item * C<%m>

2-digit month (01-12) of current time.

=item * C<%d>

2-digit day of month (01-31) of current time.

=item * C<%H>

2-digit hour (00-23) of current time.

=item * C<%M>

2-digit minute (00-59) of current time.

=item * C<%S>

2-digit second (00-60) of current time.

=back

You should make sure that the database name won't exceed the maximum length
allowed by the database software (e.g. 64 character for some SQL databases).

=head1 METHODS

=head2 new(%attrs) => obj

=head2 $twdb->create_db

Create a test database with random name according to C<name_pattern>.

=head2 $twdb->created_dbs => LIST

Return a list of temporary databases already created by this instance.

=head2 $twdb->done

Finish testing. Will drop all created databases unless tests are not passing or
C<TWDB_KEEP_TEMP_DBS> is set to true.

Called automatically during DESTROY (but because object destruction order are
not guaranteed, e.g. DBI database handle might get destroyed first preventing
proper database deletion to work, it's best that you explicitly call C<done()>
yourself).

=head2 $twdb->drop_dbs

Explicitly delete created temporary databases, regardless of whether tests are
passing or C<TWDB_KEEP_TEMP_DBS> is set.

=head1 ENVIRONMENT

=head2 TWDB_CONFIG_PATH => str

Set default C<config_path>.

=head2 TWDB_CONFIG_PROFILE => str

Set default C<config_profile>.

=head2 TWDB_NAME_PATTERN => str

Set default C<name_pattern>.

=head2 TWDB_KEEP_TEMP_DBS => bool

Can be set to true to keep C<done()> from automatically dropping databases.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-WithDB>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-WithDB>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-WithDB>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBIx::TempDB>

L<Test::More>, L<Test::Builder>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
