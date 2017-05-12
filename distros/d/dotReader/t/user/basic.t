use Test::More (0 ? 'no_plan' : tests => 9);

BEGIN {use_ok('dtRdr::User')};

my $user = dtRdr::User->new();
isa_ok($user, 'dtRdr::User');

# no more auto-loading config
ok(!$user->config, 'not config');

# TODO localize config here
$user->init_config('drconfig.yml'); # BAH!
ok($user->config, 'got config');
isa_ok($user->config, 'dtRdr::Config');

ok($user->username, 'got a username');
is($user->name, 'me');

is(dtRdr::User->new(username => 'jim')->username, 'jim');
is(dtRdr::User->new(name => 'Jim')->name, 'Jim');

#warn YAML::Syck::Dump($user);

# vim:ts=2:sw=2:et:sta
