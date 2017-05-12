use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 25;
use Cwd;
use File::Temp;

my $test_directory = Cwd::abs_path(File::Basename::dirname(__FILE__));

my $original_cwd = Cwd::getcwd();

my $temp_dir = File::Temp::tempdir(CLEANUP => 1);

ok(UR::Object::Type->define(
       class_name => 'URT::Command::TestBase',
       is => 'UR::Namespace::Command::Base',
   ),
   'Define test command class');

URT::Command::TestBase->dump_error_messages(0);
URT::Command::TestBase->queue_error_messages(1);


chdir ($temp_dir) || die "Can't chdir to $temp_dir: $!";
my $namespace_name = URT::Command::TestBase->resolve_namespace_name_from_cwd();
ok(!defined($namespace_name), 'resolve_namespace_name_from_cwd returns nothing when not in a namespace directory');

my $cmd = URT::Command::TestBase->create();
ok(!$cmd, 'Cannot create command when pwd is not inside a namespace dir');
my $error_message = join("\n",URT::Command::TestBase->error_messages());
like($error_message,
     qr(Could not determine namespace name),
     'Error message was correct');


my $lib_path = URT::Command::TestBase->resolve_lib_path_for_namespace_name('URT');
my($expected_lib_path) = ($test_directory =~ m/^(.*)\/URT\/t/);
is($lib_path, $expected_lib_path, 'resolve_lib_path_for_namespace_name found the URT namespace');


$cmd = URT::Command::TestBase->create(namespace_name => 'URT');
ok($cmd, 'Created command in a temp dir with forced namespace_name');
is($cmd->namespace_name, 'URT', 'namespace_name is correct');

$expected_lib_path = $INC{'URT.pm'};
$expected_lib_path =~ s/\/URT.pm$//;
is($cmd->lib_path, $expected_lib_path, 'lib_path is correct');

chdir($test_directory) || die "Can't chdir to $test_directory: $!";
$cmd = URT::Command::TestBase->create();
ok($cmd, 'Created command in the URT test dir and did not force namespace_name');

$lib_path = $cmd->lib_path;
is($lib_path, $expected_lib_path, 'lib_path is correct');


chdir($lib_path) || die "Can't chdir to $lib_path: $!";
is($cmd->working_subdir, '.', 'when pwd is lib_path, working_subdir is correct');

chdir($test_directory) || die "Can't chdir to $test_directory";
is($cmd->working_subdir, 'URT/t', 'When pwd is the test directory, working_subdir is correct');

chdir($temp_dir) || die "Can't chdir to $temp_dir: $!";
my $expected_working_subdir = $lib_path . ('../' x scalar(my @l = split('/', Cwd::abs_path($lib_path)))) . $temp_dir;
#is($cmd->working_subdir, $expected_working_subdir, 'when pwd is somwehere in /tmp, working_subdir is correct');

chdir($original_cwd);

my $expected_namespace_path = $INC{'URT.pm'};
$expected_namespace_path =~ s/\.pm$//;
is($cmd->namespace_path, $expected_namespace_path, 'namespace_path is correct');

is($cmd->command_name, 'u-r-t test-base', 'command_name is correct');

# This needs to be updated if we ever drop in a new module under URT/
my @expected_modules = sort qw(URT/34Baseclass.pm URT/38Primary.pm URT/43Primary.pm URT/FakeDBI.pm URT/ObjWithHash.pm URT/Thingy.pm
                               URT/34Subclass.pm URT/38Related.pm URT/43Related.pm URT/RAMThingy.pm URT/Vocabulary.pm
                               URT/TestRole.pm
                               URT/Context/Testing.pm URT/DataSource/CircFk.pm URT/DataSource/Meta.pm
                               URT/DataSource/SomeFile.pm URT/DataSource/SomeFileMux.pm URT/DataSource/SomeMySQL.pm
                               URT/DataSource/SomeOracle.pm URT/DataSource/SomePostgreSQL.pm URT/DataSource/SomeSQLite.pm
                               URT/Test.pm);
my @modules = sort $cmd->_modules_in_tree();
# remove modules created by the 'ur update classes-from-db' test that may be running in parallel
@modules = grep { $_ !~ m/Car.pm|Person.pm|Employee.pm/ } @modules; 
is_deeply(\@modules, \@expected_modules, '_modules_in_tree with no args is correct');

my @expected_class_names = sort qw(URT::34Baseclass URT::38Primary URT::43Primary URT::FakeDBI URT::ObjWithHash URT::Thingy
                                   URT::34Subclass URT::38Related URT::43Related URT::RAMThingy URT::Vocabulary
                                   URT::TestRole
                                   URT::Context::Testing URT::DataSource::CircFk URT::DataSource::Meta
                                   URT::DataSource::SomeFile URT::DataSource::SomeFileMux URT::DataSource::SomeMySQL
                                   URT::DataSource::SomeOracle URT::DataSource::SomePostgreSQL URT::DataSource::SomeSQLite
                                   URT::Test);
my @class_names = sort $cmd->_class_names_in_tree;
# remove classes created by the 'ur update classes-from-db' test that may be running in parallel
@class_names = grep { $_ !~ m/URT::Car|URT::Person|URT::Employee/ } @class_names; 
is_deeply(\@class_names, \@expected_class_names, '_class_names_in_tree with no args is correct');


@modules = sort $cmd->_modules_in_tree( qw( URT/34Baseclass.pm URT/DataSource/Meta.pm URT/Something/NonExistent.pm
                                            URT::34Baseclass URT::DataSource::SomeOracle URT::NotAModule ) );
@expected_modules = sort qw( URT/34Baseclass.pm URT/DataSource/Meta.pm URT/34Baseclass.pm URT/DataSource/SomeOracle.pm );
is_deeply(\@modules, \@expected_modules, '_modules_in_tree with args is correct');

eval {
    my @tests = (
        [q(Foo::Bar) , 1],
        [q(Foo'Bar)  , 1],
        [q(Foo_Bar)  , 1],
        [q(FooBar)   , 1],
        [q(Foo0::Bar), 1],
        [q(Foo::0Bar), 1],
        [q(Foo.d)    , ''],
        [q(0Foo::Bar), ''],
    );
    for my $test (@tests) {
        my ($class_name, $is_valid) = @$test;
        my $msg = $is_valid
                    ? "valid: $class_name"
                    : "invalid: $class_name";
        is(UR::Util::is_valid_class_name($class_name),
            $is_valid,
            $msg);
    }
};
