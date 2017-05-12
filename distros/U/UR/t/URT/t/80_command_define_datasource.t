use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use IO::File;
use Test::More;

my ($oracle,$postgres,$mysql);
BEGIN {
    eval "use DBD::mysql";
    eval "use DBD::Pg";
    eval "use DBD::Oracle";
    $oracle = $INC{"DBD/Oracle.pm"};
    $mysql = $INC{"DBD/mysql.pm"};
    $postgres = $INC{"DBD/Pg.pm"};
    
    my $tests = 33;
    $tests += 12 if $oracle; 
    $tests += 12 if $postgres; 
    $tests += 12 if $mysql;
    plan tests => $tests;
}

BEGIN {
    use_ok('UR::Namespace::Command::Define::Datasource');
    use_ok('UR::Namespace::Command::Define::Datasource::Sqlite');
    use_ok('UR::Namespace::Command::Define::Datasource::Oracle');
    use_ok('UR::Namespace::Command::Define::Datasource::Mysql');
    use_ok('UR::Namespace::Command::Define::Datasource::Pg');
}

my $data_source_dir = URT->get_base_directory_name() . '/DataSource/';
my @FILES_TO_DELETE = map { $data_source_dir . $_ }
                      qw(
                          TestcaseSqlite.pm
                          TestcaseSqlite.sqlite3
                          TestcaseSqlite2.pm
                          TestcaseOracle.pm
                          TestcaseMysql.pm
                          TestcasePg.pm
                       );
push @FILES_TO_DELETE, '/tmp/TestcaseSqlite.sqlite3';

chdir $data_source_dir;

my $cleanup_files = sub { unlink @FILES_TO_DELETE };

&$cleanup_files;


UR::Namespace::Command::Define::Datasource->dump_status_messages(0); # don't print to the terminal
# SQLite
{ 
    my($delegate_class, $create_params) = UR::Namespace::Command::Define::Datasource->resolve_class_and_params_for_argv(
                      qw(sqlite --dsname TestcaseSqlite)
                  );
    ok($delegate_class, "Resolving parameters for define datasource, delegate class $delegate_class");
    
    my $command = $delegate_class->create(%$create_params);
    ok($command,'Created command obj for defining SQLite DS');
    ok($command->execute(),'Executed SQLite define');

    my $expected_path = $command->namespace_path . '/DataSource/TestcaseSqlite.sqlite3';
    ok(-f $expected_path, 'Created SQLite database file');
    $expected_path = $command->namespace_path . '/DataSource/TestcaseSqlite.pm';
    ok(-f $expected_path, 'Created SQLite DS module');

    my $src = _read_file($expected_path);
    # Not an exhaustive syntax check, just look for some things
    like($src, qr/package URT::DataSource::TestcaseSqlite/, 'package line looks ok');
    like($src, qr/class URT::DataSource::TestcaseSqlite/, 'class line looks ok');
    like($src, qr/is.*UR::DataSource::SQLite/, "'is' line looks ok");
    like($src, qr/sub server \{ \S+\/URT\/DataSource\/TestcaseSqlite.sqlite3/, 'server line looks ok');
    unlike($src, qr/sub owner/, 'No owner line, as expected');
    unlike($src, qr/sub login/, 'No login line, as expected');
    unlike($src, qr/sub auth/, 'No auth line, as expected');

    &$cleanup_files;
}

{
    my $db_file = '/tmp/TestcaseSqlite.sqlite3';
    IO::File->new($db_file, 'w')->close();
    my($delegate_class, $create_params) = UR::Namespace::Command::Define::Datasource->resolve_class_and_params_for_argv(
                      qw(sqlite --dsname TestcaseSqlite2 --server /tmp/TestcaseSqlite.sqlite3 )
                  );
    ok($delegate_class, "Resolving parameters for define datasource, delegate class $delegate_class");

    my $command = $delegate_class->create(%$create_params);
    ok($command,'Created command obj for defining SQLite DS');
    ok($command->execute(),'Executed SQLite define');

    my $expected_path = '/tmp/TestcaseSqlite.sqlite3';
    ok(-f $expected_path, 'Created SQLite database file');
    $expected_path = $command->namespace_path . '/DataSource/TestcaseSqlite2.pm';
    ok(-f $expected_path, 'Created SQLite DS module');

    my $src = _read_file($expected_path);
    # Not an exhaustive syntax check, just look for some things
    like($src, qr/package URT::DataSource::TestcaseSqlite/, 'package line looks ok');
    like($src, qr/class URT::DataSource::TestcaseSqlite/, 'class line looks ok');
    like($src, qr/is.*UR::DataSource::SQLite/, "'is' line looks ok");
    like($src, qr/sub server \{ '\/tmp\/TestcaseSqlite.sqlite3/, 'server line looks ok');
    unlike($src, qr/sub owner/, 'No owner line, as expected');
    unlike($src, qr/sub login/, 'No login line, as expected');
    unlike($src, qr/sub auth/, 'No auth line, as expected');

    # Don't remove the files because we want to test failure next
}

{
    my($delegate_class, $create_params) = UR::Namespace::Command::Define::Datasource->resolve_class_and_params_for_argv(
                      qw(sqlite --dsname TestcaseSqlite)
                  );
    ok($delegate_class, "Resolving parameters for define datasource, delegate class $delegate_class");

    my $command = $delegate_class->create(%$create_params);
    ok($command,'Created command obj for defining SQLite DS');
    $command->dump_error_messages(0);
    ok(! $command->execute(), 'Execute correctly returned failure');
    my $message = $command->error_message;
    is($message,'A data source named URT::DataSource::TestcaseSqlite already exists',
         'Error message mentions the target datasource module already exists');
    &$cleanup_files;
}


# Oracle
if($oracle)
{
    my($delegate_class, $create_params) = UR::Namespace::Command::Define::Datasource->resolve_class_and_params_for_argv(
                      qw(oracle --dsname TestcaseOracle --owner foo --login me --auth passwd)
                  );
    ok($delegate_class, "Resolving parameters for define datasource, delegate class $delegate_class");

    my $command = $delegate_class->create(%$create_params);
    ok($command,'Created command obj for defining Oracle DS');

    open my $old_stderr, ">&STDERR";
    close(STDERR);
    $command->dump_error_messages(0);
    # The execute() here will fail because TestcaseOracle isn't a real database
    # and the connection test at the end of the command will fail
    my $retval = eval { $command->execute() };
    open STDERR, ">&", $old_stderr;

    ok(!$retval,'Executing Oracle define failed as expected');
    like($@, qr/Failed to connect to the database/, 'Failure was because it could not connect to the database');

    my $expected_path = $command->namespace_path . '/DataSource/TestcaseOracle.pm';
    ok(-f $expected_path, 'Created Oracle DS module');

    my $src = _read_file($expected_path);
    # Not an exhaustive syntax check, just look for some things
    like($src, qr/package URT::DataSource::TestcaseOracle/, 'package line looks ok');
    like($src, qr/class URT::DataSource::TestcaseOracle/, 'class line looks ok');
    like($src, qr/is.*UR::DataSource::Oracle/, "'is' line looks ok");
    like($src, qr/sub server \{ 'TestcaseOracle' \}/, 'server line looks ok');
    like($src, qr/sub owner \{ 'foo' \}/, 'owner line looks ok');
    like($src, qr/sub login \{ 'me' \}/, 'login line looks ok');
    like($src, qr/sub auth \{ 'passwd' \}/, 'auth line looks ok');

    &$cleanup_files;
}
else {
    diag "skipping Oracle tests since DBD::Oracle is not installed and configured";
}




# PostgreSQL
if ($postgres)
{
    my($delegate_class, $create_params) = UR::Namespace::Command::Define::Datasource->resolve_class_and_params_for_argv(
                      qw(pg --dsname TestcasePg --owner foo --login me --auth passwd)
                  );
    ok($delegate_class, "Resolving parameters for define datasource, delegate class $delegate_class");

    my $command = $delegate_class->create(%$create_params);
    ok($command,'Created command obj for defining Pg DS');

    $command->dump_error_messages(0);
    open my $old_stderr, ">&STDERR";
    close(STDERR);
    # The execute() here will fail because TestcasePg isn't a real database
    # and the connection test at the end of the command will fail
    my $retval = eval { $command->execute() };
    open STDERR, ">&", $old_stderr;

    ok(!$retval,'Executing Pg define failed as expected');
    like($@, qr/(Failed to connect to the database)|(Can't load \S+ for module DBD::Pg)/, 'Failure was because it could not connect to the database');

    my $expected_path = $command->namespace_path . '/DataSource/TestcasePg.pm';
    ok(-f $expected_path, 'Created Pg DS module');

    my $src = _read_file($expected_path);
    # Not an exhaustive syntax check, just look for some things
    like($src, qr/package URT::DataSource::TestcasePg/, 'package line looks ok');
    like($src, qr/class URT::DataSource::TestcasePg/, 'class line looks ok');
    like($src, qr/is.*UR::DataSource::Pg/, "'is' line looks ok");
    like($src, qr/sub server \{ 'TestcasePg' \}/, 'server line looks ok');
    like($src, qr/sub owner \{ 'foo' \}/, 'owner line looks ok');
    like($src, qr/sub login \{ 'me' \}/, 'login line looks ok');
    like($src, qr/sub auth \{ 'passwd' \}/, 'auth line looks ok');

    &$cleanup_files;
}
else {
    diag "skipping PostgreSQL tests since DBD::pg is not installed";
}


# MySQL
if($mysql)
{
    my($delegate_class, $create_params) = UR::Namespace::Command::Define::Datasource->resolve_class_and_params_for_argv(
                      qw(mysql --dsname TestcaseMysql --owner foo --login me --auth passwd)
                  );
    ok($delegate_class, "Resolving parameters for define datasource, delegate class $delegate_class");

    my $command = $delegate_class->create(%$create_params);
    ok($command,'Created command obj for defining Mysql DS');

    $command->dump_error_messages(0);
    open my $old_stderr, ">&STDERR";
    close(STDERR);
    # The execute() here will fail because TestcaseMysql isn't a real database
    # and the connection test at the end of the command will fail
    my $retval = eval { $command->execute() };
    open STDERR, ">&", $old_stderr;

    ok(!$retval,'Executing Mysql define failed as expected');
    like($@, qr/Failed to connect to the database/, 'Failure was because it could not connect to the database');

    my $expected_path = $command->namespace_path . '/DataSource/TestcaseMysql.pm';
    ok(-f $expected_path, 'Created Mysql DS module');

    my $src = _read_file($expected_path);
    # Not an exhaustive syntax check, just look for some things
    like($src, qr/package URT::DataSource::TestcaseMysql/, 'package line looks ok');
    like($src, qr/class URT::DataSource::TestcaseMysql/, 'class line looks ok');
    like($src, qr/is.*UR::DataSource::MySQL/, "'is' line looks ok");
    like($src, qr/sub server \{ 'TestcaseMysql' \}/, 'server line looks ok');
    like($src, qr/sub owner \{ 'foo' \}/, 'owner line looks ok');
    like($src, qr/sub login \{ 'me' \}/, 'login line looks ok');
    like($src, qr/sub auth \{ 'passwd' \}/, 'auth line looks ok');

    &$cleanup_files;
}
else {
    diag "skipping MySQL tests since DBD::mysql is not installed";
}




sub _read_file {
    my $path = shift;

    my $fh = IO::File->new($path);
    die "Can't open $path: $!" unless $fh;

    # Read in the whole file
    local $/;
    undef $/;
    my $src = <$fh>;
    $fh->close();
    return $src;
}

