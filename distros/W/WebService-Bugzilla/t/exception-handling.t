#!perl
use strict;
use warnings;
use Test::More import => [qw(done_testing like is isa_ok diag subtest)];
use Test::Exception;
use lib 'lib', 't/lib';

use Test::Bugzilla::PSGI;
use WebService::Bugzilla;
use WebService::Bugzilla::Exception;

subtest '404 returns undef for get' => sub {
    my $mock = Test::Bugzilla::PSGI::mock();
    $mock->set_error('GET', '/bugzilla/rest/bug/999', 404, 'Bug not found');

    my $bz = WebService::Bugzilla->new(
        base_url => 'http://localhost',
        api_key  => 'test',
    );
    my $bug = $bz->bug->get(999);
    is($bug, undef, 'get returns undef for 404');
    Test::Bugzilla::PSGI::unregister_mock();
};

subtest '410 returns undef for get' => sub {
    my $mock = Test::Bugzilla::PSGI::mock();
    $mock->set_error('GET', '/bugzilla/rest/bug/999', 410, 'Bug gone');

    my $bz = WebService::Bugzilla->new(
        base_url => 'http://localhost',
        api_key  => 'test',
    );
    my $bug = $bz->bug->get(999);
    is($bug, undef, 'get returns undef for 410');
    Test::Bugzilla::PSGI::unregister_mock();
};

subtest 'POST throws Exception on error' => sub {
    my $mock = Test::Bugzilla::PSGI::mock();
    $mock->set_error('POST', '/bugzilla/rest/bug', 400, 'Validation failed');

    my $bz = WebService::Bugzilla->new(
        base_url => 'http://localhost',
        api_key  => 'test',
    );
    throws_ok {
        $bz->bug->create(product => 'Test', summary => 'Test');
    } qr/Validation failed/, 'create throws on 400';
    Test::Bugzilla::PSGI::unregister_mock();
};

subtest '5xx throws Exception' => sub {
    my $mock = Test::Bugzilla::PSGI::mock();
    $mock->set_error('GET', '/bugzilla/rest/bug/123', 500, 'Internal Server Error');

    my $bz = WebService::Bugzilla->new(
        base_url => 'http://localhost',
        api_key  => 'test',
    );
    throws_ok {
        $bz->bug->get(123);
    } qr/500/, 'get throws on 5xx';
    Test::Bugzilla::PSGI::unregister_mock();
};

done_testing();
