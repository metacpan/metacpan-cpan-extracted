use strict;
use warnings;
use Test::More;

use_ok('VideoLAN::LibVLC') || BAIL_OUT;

my $vlc= new_ok( 'VideoLAN::LibVLC', [], 'new instance, no args' );

ok( length( $vlc->libvlc_version ), 'get version' );
ok( length( $vlc->libvlc_changeset ), 'get changeset' );
ok( length( $vlc->libvlc_compiler ), 'get compiler' );
note sprintf("version=%s changeset=%s compiler=%s", $vlc->libvlc_version, $vlc->libvlc_changeset, $vlc->libvlc_compiler);

is( $vlc->app_id('com.foo.bar'), 'com.foo.bar', 'set app id' );
is( $vlc->app_version('0'),      '0',           'set version' );
is( $vlc->app_icon('foobar'),    'foobar',      'set icon' );

is( $vlc->user_agent_name('Test'), 'Test',      'set ua name' );
is( $vlc->user_agent_http('Test/1.1'), 'Test/1.1', 'set ua http' );

isa_ok( $vlc->audio_filters, 'ARRAY', 'audio filters' );
note explain $vlc->audio_filters;
isa_ok( $vlc->video_filters, 'ARRAY', 'video_filters' );
note explain $vlc->video_filters;

# Test setting attributes from constructor

$vlc= new_ok( 'VideoLAN::LibVLC', [
	app_id => 'xyz.tuv',
	app_version => '1.1.1',
	user_agent_name => 'Test2',
	user_agent_http => 'Test/2.1',
], 'new instance with args' );

is( $vlc->app_id, 'xyz.tuv', 'app id' );
is( $vlc->app_version, '1.1.1',  'version' );
is( $vlc->app_icon, '',  'default icon' );
is( $vlc->user_agent_name, 'Test2', 'ua name' );
is( $vlc->user_agent_http, 'Test/2.1', 'ua http' );

done_testing;
