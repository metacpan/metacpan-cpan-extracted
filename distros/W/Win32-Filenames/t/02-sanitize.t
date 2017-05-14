use Test::More tests => 6;

use Win32::Filenames qw( sanitize );

ok( sanitize('this:that') eq 'this-that' );
ok( sanitize('  44?0<s>') eq '  44-0-s-' );
ok( sanitize('jo:dirt<S>','~~') eq 'jo~~dirt~~S~~');
ok( sanitize('ok.txt') eq 'ok.txt');
ok( sanitize('ok.txt', '_') eq 'ok.txt');
ok( sanitize('last|one', '_') eq 'last_one');
