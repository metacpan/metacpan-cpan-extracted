#!/usr/bin/perl -w
use strict;

use Test::More;
use WebService::FogBugz;

my $email    = '';
my $password = '';
my $base_url = '';

unless ($email and $password and $base_url) {
    Test::More->import(skip_all => "requires email, password and base_url, skipped.");
    exit;
}

plan tests => 7;

my $fogbugz;
eval {
    $fogbugz = WebService::FogBugz->new;
};
ok $@, 'logon error';

$fogbugz = WebService::FogBugz->new(
    email    => $email,
    password => $password,
    base_url => $base_url,
);
is ref($fogbugz), 'WebService::FogBugz', 'reference';
is $fogbugz->{UA}->agent, 'WebService::FogBugz/' . $WebService::FogBugz::VERSION, 'check agent';

my $token = $fogbugz->logon;
ok $token, "your token is $token";

my $res =  $fogbugz->request_method('new', {
    sTitle      => 'WebService::FogBugz Create Case Test',
    sEvent      => 'This is just a test',
    sProject    => 'WebService::FogBugz',
    sArea       => 'make test',
    sTags       => 'WebService,Test',
    ixPriority  => 4,
});
chomp $res;
ok $res, "got response.";
diag($res);

$res =  $fogbugz->request_method('search', {
    q => 'WebService',
});
chomp $res;
ok $res, "got response.";
diag($res);

$fogbugz->logoff;
ok !$fogbugz->{token}, "token is null";
