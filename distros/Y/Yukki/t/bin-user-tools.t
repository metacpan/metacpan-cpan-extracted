#!/usr/bin/env perl
use 5.12.1;

use lib 't/lib';
use Yukki::Test;

use File::Temp qw( tempdir );
use Test::More tests => 14;
use Test::Script;
use Try::Tiny;
use YAML qw( LoadFile );

$File::Temp::KEEP_ALL = 1 if $ENV{YUKKI_TEST_KEEP_FILES};

script_compiles('bin/yukki-setup', 'yukki-setup compiles');
script_compiles('bin/yukki-add-user', 'yukki-add-user compiles');
script_compiles('bin/yukki-passwd', 'yukki-passwd compiles');

my $tempdir = tempdir;
diag("TEMPDIR = $tempdir") if $ENV{YUKKI_TEST_KEEP_FILES};

script_runs([ 'bin/yukki-setup', "$tempdir/yukki-test" ], 
    'yukki-setup runs');

ok(-d "$tempdir/yukki-test", 'created the test directory');
ok(!-f "$tempdir/yukki-test/var/db/users/foo", 
    'the user we are about to create does not exist yet');

$ENV{YUKKI_CONFIG} = "$tempdir/yukki-test/etc/yukki.conf";

try {
    yukki('add-user', qq[foo
secret
Foo Bar
foo\@bar.com
some_group
another_group
]);
    pass('ran yukki-add-user');
}
catch {
    fail("ran yukki-add-user: $_");
};

ok(-f "$tempdir/yukki-test/var/db/users/foo",
    'the user file has been created');

my $user = LoadFile("$tempdir/yukki-test/var/db/users/foo");
my $password = delete $user->{password};
is_deeply($user, {
    login_name => 'foo',
    name       => 'Foo Bar',
    email      => 'foo@bar.com',
    groups     => [ 'some_group', 'another_group' ],
}, 'the user was created correctly');

use_ok('Yukki');
my $app = Yukki->new;
my $digest = $app->hasher;

ok(scalar $digest->validate($password, 'secret'), 'password is valid');

try {
    yukki('passwd', "foo\nMy Other Secret\n");
    pass("ran yukki-passwd");
}
catch {
    fail("ran yukki-passwd: $_");
};

my $user_again = LoadFile("$tempdir/yukki-test/var/db/users/foo");
my $new_password = delete $user_again->{password};
is_deeply($user_again, {
    login_name => 'foo',
    name       => 'Foo Bar',
    email      => 'foo@bar.com',
    groups     => [ 'some_group', 'another_group' ],
}, 'the user is unchanged');

ok(scalar $digest->validate($new_password, 'My Other Secret'), 'password is valid, but different');
