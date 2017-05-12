use strict;
use warnings;

use File::Spec;
use Cwd;

use Test::More 'tests' => 37;
BEGIN { use_ok( 'cPanel::SyncUtil', ':all' ) }

print "\n";

my $cwd     = Cwd::getcwd();
my $type_hr = {
    qw(
      / d
      /etc d
      /etc/foo d
      /etc/bar d
      /etc/bar/diddly d
      /etc/foo/cPanel d
      /etc/foo/Cpanel d
      /etc/foo/DDDDDD d
      /etc/foo/AAAAAAA d
      /etc/file f
      /etc/bar/wop f
      /etc/kibble/dog f
      /etc/link l
      /etc/l l
      /etc/abcdef l
      )
};
is_deeply(
    [ cPanel::SyncUtil::__sort_test( 1, keys %{$type_hr}, $type_hr ) ],
    [
        qw(
          /
          /etc
          /etc/bar
          /etc/foo
          /etc/bar/diddly
          /etc/foo/Cpanel
          /etc/foo/cPanel
          /etc/foo/DDDDDD
          /etc/foo/AAAAAAA
          /etc/file
          /etc/bar/wop
          /etc/kibble/dog
          /etc/l
          /etc/link
          /etc/abcdef
          )
    ],
    'cpanelsync entries sorted properly'
);
is_deeply(
    [ cPanel::SyncUtil::__sort_test( 0, map { $type_hr->{$_} eq 'l' ? "$type_hr->{$_}===$_===/etc/shmetc/foo" : "$type_hr->{$_}===$_" } keys %{$type_hr} ) ],
    [
        qw(
          d===/
          d===/etc
          d===/etc/bar
          d===/etc/foo
          d===/etc/bar/diddly
          d===/etc/foo/Cpanel
          d===/etc/foo/cPanel
          d===/etc/foo/DDDDDD
          d===/etc/foo/AAAAAAA
          f===/etc/file
          f===/etc/bar/wop
          f===/etc/kibble/dog
          l===/etc/l===/etc/shmetc/foo
          l===/etc/link===/etc/shmetc/foo
          l===/etc/abcdef===/etc/shmetc/foo
          )
    ],
    'cpanelsync entries sorted properly'
);

# attempt to do tests in t/ directory
my $upt = File::Spec->catdir( $cwd, 't' );
if ( -d $upt ) {
    chdir $upt;
}
else {
    die "Directory $upt does not exist";
}

my $testdir  = 'cpanelsync_test_files';
my $testdir2 = 'cpanelsync_test_files2';

# clean up if last time had left overs
_t_cleanup();

# need it fresh so it shouldn't exist so we die:
mkdir $testdir or die "Could not mkdir $testdir: $!";

# make a bunch of files and directories in $testdir

#### run some tests ##
# run some functions and test (increment Test::More's tests)
# that the expected new files exist

my $file = File::Spec->catfile( $testdir, 'filea' );

# _write_file
ok( _write_file( $file, 'filea content' ), '_write_file function call' );
ok( -e $file, '_write_file file exists' );

chdir $testdir or die "Can't move into test dir: $!";

mkdir 'archive_only' or die "Can't create 'only' dir: $!";
chdir 'archive_only' or die "Can't go into 'only' dir: $!";
_write_file( $_, "$_ content" ) for qw( filea fileb );
mkdir 'dira' or die "Can't create a test directory in 'only': $!";
_write_file( $_, "$_ content" ) for qw( filec filed );
chdir '..' or die "Can not go back down to run more tests: $!";

mkdir 'archive_plus' or die "Can't create 'plus' dir: $!";
chdir 'archive_plus' or die "Can't go into 'plus' dir: $!";
_write_file( $_, "$_ content" ) for qw( filea fileb );
mkdir 'dira' or die "Can't create a test directory in 'plus': $!";
_write_file( $_, "$_ content" ) for qw( filec filed );
chdir '..' or die "Can not go back down to run more tests: $!";

# _read_dir
ok( my @files = _read_dir('.'), '_read_dir function call' );
ok( @files == 3, '_read_dir results' );

# _sync_touchlock_pwd
note('Running _sync_touchlock_pwd()');
ok( _sync_touchlock_pwd(), '_sync_touchlock_pwd function call' );
for (qw( .cpanelsync .cpanelsync.bz2 .cpanelsync.lock filea.bz2 )) {
    ok( -e $_, "_sync_touchlock_pwd $_" );
}

# _raw_dir
chdir '..' or die "Can not go back down to run more tests: $!";
my @ftodo = qw(filea fileb dira);

ok( _raw_dir( $testdir, 'archive_only', 0 ), '_raw_dir no @files' );
my $tara = File::Spec->catfile( $testdir, 'archive_only.tar' );
ok( !-e $tara,      "$tara removed" );
ok( -e "$tara.bz2", "$tara.bz2 created" );

ok( _raw_dir( $testdir, 'archive_plus', 0, @ftodo ), '_raw_dir w/ @files' );
my $tarb = File::Spec->catfile( $testdir, 'archive_plus.tar' );
ok( !-e $tarb,      "$tarb removed" );
ok( -e "$tarb.bz2", "$tarb.bz2 created" );
for (@ftodo) {
    my $path = File::Spec->catfile( $testdir, 'archive_plus', $_ );
    ok( -e $path, '@files bz2 of: ' . $path );
}

ok( !_raw_dir( $testdir, 'filea', 0 ), '_raw_dir non-dir $archive fails ok' );

##### Begin Tests for compress_files and build_cpanelsync #####
chdir $upt or die "Failed to chdir $upt: $!";

mkdir $testdir2 or die "Could not mkdir $testdir2: $!";

# Setup compress_only directory
chdir $testdir2       or die "Can't move into test dir: $!";
mkdir 'compress_only' or die "Can't create 'only' dir: $!";
chdir 'compress_only' or die "Can't go into 'only' dir: $!";
_write_file( $_, "$_ content" ) for qw( filea fileb );
mkdir 'dira' or die "Can't create a test directory in 'only': $!";
chdir 'dira' or die "Can't chdir into 'dira' dir: $!";
_write_file( $_, "$_ content" ) for qw( filec filed );

# Reset
chdir $upt or die "Failed to chdir $upt: $!";

# Create build_cpanelsync directory
chdir $testdir2          or die "Can't chdir into $testdir2: $!";
mkdir 'build_cpanelsync' or die "Can't create 'build_cpanelsync' dir: $!";
chdir 'build_cpanelsync' or die "Can't chdir into 'build_cpanelsync' dir: $!";
_write_file( $_, "$_ content" ) for qw( filea fileb );
mkdir 'dira' or die "Can't create a test directory in 'plus': $!";
chdir 'dira' or die "Can't chdir into 'dira' dir: $!";
_write_file( $_, "$_ content" ) for qw( filec filed );

# Reset
chdir $upt or die "Failed to chdir $upt: $!";

# _read_dir_recursively
@files = ();
ok( @files = _read_dir_recursively( File::Spec->catfile( $testdir2, 'compress_only' ) ), '_read_dir_recursively function call' );
ok( @files == 6, "_read_dir_recursively results match expected count" );

{
    local $cPanel::SyncUtil::ignore_name{'filea'} = 1;

    # _read_dir_recursively + %ignore_name
    @files = ();
    ok( @files = _read_dir_recursively( File::Spec->catfile( $testdir2, 'compress_only' ) ), '_read_dir_recursively + \%ignore_name function call w/ file name' );
    ok( @files == 5, "_read_dir_recursively + \%ignore_name results match expected count w/ file name" );
}

{
    local $cPanel::SyncUtil::ignore_name{"$testdir2/compress_only/filea"} = 1;

    # _read_dir_recursively + %ignore_name
    @files = ();
    ok( @files = _read_dir_recursively( File::Spec->catfile( $testdir2, 'compress_only' ) ), '_read_dir_recursively + \%ignore_name function call w/ file path' );
    ok( @files == 5, "_read_dir_recursively + \%ignore_name results match expected count w/ file path" );
}

# build_cpanelsync

{
    my $test_mode_called     = 0;
    my $test_get_mode_string = sub {
        my ($file) = @_;
        $test_mode_called++;
        return get_mode_string($file) if $test_mode_called > 1;
        is( $file, './dira', 'get_mode_string() called when expected and given the correct data' );
        return get_mode_string($file);
    };

    note('Running build_cpanelsync()');
    ok( build_cpanelsync( File::Spec->catfile( $testdir2, 'build_cpanelsync' ), { 'get_mode_string' => $test_get_mode_string } ), 'build_cpanelsync function call' );

    if ( !$test_mode_called ) {
        ok( 0, 'get_mode_string() called when expected' );
    }
}

for (qw( .cpanelsync .cpanelsync.lock )) {
    my $file = File::Spec->catfile( $testdir2, 'build_cpanelsync', $_ );
    ok( -e $file, "build_cpanelsync file exists: $file" );
}

# Compress files and create tar ball
note('Running compress_files()');
ok( compress_files( File::Spec->catfile( $testdir2, 'compress_only' ) ), 'compress_files function call' );
for (qw( .cpanelsync.bz2 filea.bz2 fileb.bz2 )) {
    my $file = File::Spec->catfile( $testdir2, 'compress_only', $_ );
    ok( -e $file, "compress_files file exists: $file" );
}

$tara = File::Spec->catfile( $testdir2, 'compress_only.tar.bz2' );
ok( -e $tara, "$tara created" );

#### clean up our mess ##
chdir $upt or die;

_t_cleanup();

chdir $cwd or die;

sub _t_cleanup {

    # if /bin/rm is an executable, execute it
    system( 'rm', '-rf', $testdir );
    system( 'rm', '-rf', $testdir2 );

    # check for a module or two that can clean it up without system

    # if it failed or didn't exist, remind them to clean up
    diag("Its safe to remove $testdir now.")  if -d $testdir;
    diag("Its safe to remove $testdir2 now.") if -d $testdir2;
}
