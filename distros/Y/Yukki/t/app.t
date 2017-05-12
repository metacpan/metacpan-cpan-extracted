#!/usr/bin/env perl
use 5.12.1;

use Test::More tests => 58;
use Test::Exception;
use Test::Moose;

use Path::Class;

use_ok('Yukki');

my $app = Yukki->new;
isa_ok($app, 'Yukki');
does_ok($app, 'Yukki::Role::App');

throws_ok { $app->config_file } qr/make YUKKI_CONFIG point/, 'missing config location complains';

$ENV{YUKKI_CONFIG} = 't/test-site/etc/bad-yukki.conf';

throws_ok { $app->config_file} qr/no configuration found/i, 'missing config file complains';

delete $ENV{YUKKI_CONFIG};
chdir 't/test-site';

is($app->config_file, file(dir(), 'etc', 'yukki.conf'), 'config set by CWD works');

delete $app->{config_file};
chdir '../..';
$ENV{YUKKI_CONFIG} = 't/test-site/etc/yukki.conf';

is($app->config_file, file(dir(), 't', 'test-site', 'etc', 'yukki.conf'), 'config set by env works');

throws_ok { $app->view } qr/unimplemented/i, 'view is not implemented';
throws_ok { $app->controller } qr/unimplemented/i, 'controller is not implemented';

my $model = $app->model('User');
isa_ok($model, 'Yukki::Model::User');

my $dir = $app->locate_dir('repository_path', 'main.git');
isa_ok($dir, 'Path::Class::Dir');
is("$dir", "/tmp/repositories/main.git", 'locate_dir makes the right dir');

my $file = $app->locate('user_path', 'demo');
isa_ok($file, 'Path::Class::File');
is("$file", "/tmp/var/db/users/demo", 'locate makes the right file');

is($app->check_access( user => undef, repository => 'noaccess', needs => 'none' ), 1);
is($app->check_access( user => undef, repository => 'noaccess', needs => 'read' ), '');
is($app->check_access( user => undef, repository => 'noaccess', needs => 'write' ), '');
is($app->check_access( user => { groups => ['group1'] }, repository => 'noaccess', needs => 'none' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'noaccess', needs => 'read' ), '');
is($app->check_access( user => { groups => ['group1'] }, repository => 'noaccess', needs => 'write' ), '');

is($app->check_access( user => undef, repository => 'anonymousread', needs => 'none' ), 1);
is($app->check_access( user => undef, repository => 'anonymousread', needs => 'read' ), 1);
is($app->check_access( user => undef, repository => 'anonymousread', needs => 'write' ), '');
is($app->check_access( user => { groups => ['group1'] }, repository => 'anonymousread', needs => 'none' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'anonymousread', needs => 'read' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'anonymousread', needs => 'write' ), '');

is($app->check_access( user => undef, repository => 'anonymouswrite', needs => 'none' ), 1);
is($app->check_access( user => undef, repository => 'anonymouswrite', needs => 'read' ), 1);
is($app->check_access( user => undef, repository => 'anonymouswrite', needs => 'write' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'anonymouswrite', needs => 'none' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'anonymouswrite', needs => 'read' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'anonymouswrite', needs => 'write' ), 1);

is($app->check_access( user => undef, repository => 'loggedread', needs => 'none' ), 1);
is($app->check_access( user => undef, repository => 'loggedread', needs => 'read' ), '');
is($app->check_access( user => undef, repository => 'loggedread', needs => 'write' ), '');
is($app->check_access( user => { groups => ['group1'] }, repository => 'loggedread', needs => 'none' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'loggedread', needs => 'read' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'loggedread', needs => 'write' ), '');

is($app->check_access( user => undef, repository => 'loggedwrite', needs => 'none' ), 1);
is($app->check_access( user => undef, repository => 'loggedwrite', needs => 'read' ), '');
is($app->check_access( user => undef, repository => 'loggedwrite', needs => 'write' ), '');
is($app->check_access( user => { groups => ['group1'] }, repository => 'loggedwrite', needs => 'none' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'loggedwrite', needs => 'read' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'loggedwrite', needs => 'write' ), 1);

is($app->check_access( user => undef, repository => 'groupaccess', needs => 'none' ), 1);
is($app->check_access( user => undef, repository => 'groupaccess', needs => 'read' ), '');
is($app->check_access( user => undef, repository => 'groupaccess', needs => 'write' ), '');
is($app->check_access( user => { groups => ['group1'] }, repository => 'groupaccess', needs => 'none' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'groupaccess', needs => 'read' ), 1);
is($app->check_access( user => { groups => ['group1'] }, repository => 'groupaccess', needs => 'write' ), '');

is($app->check_access( user => undef, repository => 'groupaccess', needs => 'none' ), 1);
is($app->check_access( user => undef, repository => 'groupaccess', needs => 'read' ), '');
is($app->check_access( user => undef, repository => 'groupaccess', needs => 'write' ), '');
is($app->check_access( user => { groups => ['group4'] }, repository => 'groupaccess', needs => 'none' ), 1);
is($app->check_access( user => { groups => ['group4'] }, repository => 'groupaccess', needs => 'read' ), 1);
is($app->check_access( user => { groups => ['group4'] }, repository => 'groupaccess', needs => 'write' ), 1);

isa_ok($app->hasher, 'Crypt::SaltedHash', 'hasher is what it is supposed to be');
is($app->hasher->{algorithm}, $app->settings->digest, 'hasher is using the proper algorithm');
