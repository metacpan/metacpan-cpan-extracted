use Test::More tests => 20;

BEGIN {
    use_ok('Win32::FileSystem::Watcher::Change');
    use_ok('Scalar::Util');
    use_ok('Test::Exception');
    use_ok('WIN32::API');
    use_ok('WIN32');
    use_ok('Win32::MMF::Shareable');
}

use Scalar::Util qw(blessed);

my $change = Win32::FileSystem::Watcher::Change->new( 1, 'aa' );
ok( blessed($change) eq 'Win32::FileSystem::Watcher::Change', "blessed" );
is($change->action_id(), 1, "action_id");
is($change->action_name(), "FILE_ACTION_ADDED", "action_name");
is($change->file_name(), 'aa', "fname");

throws_ok sub { Win32::FileSystem::Watcher::Change->new( undef, undef ); }, qr/need an action and a file name/, 'undef/undef caught';
throws_ok sub { Win32::FileSystem::Watcher::Change->new( 1, undef ); }, qr/need an action and a file name/, 'undef/def caught';
throws_ok sub { Win32::FileSystem::Watcher::Change->new( undef, "aa" ); }, qr/need an action and a file name/, 'def/undef caught';
throws_ok sub { Win32::FileSystem::Watcher::Change->new( 1, "" ); }, qr/need an action and a file name/, 'empty file name caught';
throws_ok sub { Win32::FileSystem::Watcher::Change->new( 0, "x" ); }, qr/invalid action/i, 'invalid action id caught';
throws_ok sub { Win32::FileSystem::Watcher::Change->new( 6, "x" ); }, qr/invalid action/i, 'invalid action id caught';


$change = Win32::FileSystem::Watcher::Change->new( 1, '1' );
ok( blessed($change) eq 'Win32::FileSystem::Watcher::Change', "blessed" );
is($change->action_id(), 1, "action_id");
is($change->action_name(), "FILE_ACTION_ADDED", "action_name");
is($change->file_name(), '1', "fname");
