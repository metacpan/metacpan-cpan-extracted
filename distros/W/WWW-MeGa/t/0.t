use strict;
use Test::More tests => 6;

use_ok('WWW::MeGa');

my $cgi;

ok($cgi = WWW::MeGa->new( PARAMS => { config => '/tmp/gallery.conf' }), 'instanced');
ok($cgi->run, 'run');
ok($cgi->view_path, 'view path w/o path');


ok(sub
{
	$cgi->query->param(-name=>'path', value =>'/bine.jpg');
	$cgi->view_path;
	$cgi->run;
}, 'view path "/bine.jpg"');

ok(sub
{
	$cgi->query->param(-name=>'path', value =>'/moeve.jpg');
	$cgi->query->param(-name=>'rm', value =>'image');
	$cgi->query->param(-name=>'size', value =>1);
	$cgi->view_path;
	$cgi->run;
}, 'view image "/moeve.jpg" (involves thumb generating)');

unlink '/tmp/gallery.conf';
