#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok like ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla;
use WebService::Bugzilla::Attachment;
use WebService::Bugzilla::Bug;
use WebService::Bugzilla::BugUserLastVisit;
use WebService::Bugzilla::Classification;
use WebService::Bugzilla::Comment;
use WebService::Bugzilla::Component;
use WebService::Bugzilla::Exception;
use WebService::Bugzilla::Field;
use WebService::Bugzilla::FlagActivity;
use WebService::Bugzilla::GitHub;
use WebService::Bugzilla::Group;
use WebService::Bugzilla::Information;
use WebService::Bugzilla::Product;
use WebService::Bugzilla::Reminder;
use WebService::Bugzilla::User;

subtest 'Client instantiation' => sub {
    my $bz = Test::Bugzilla->new(
        base_url => 'http://bugzilla.example.com',
        api_key  => 'abc',
    );
    ok($bz, 'created client instance');
};

subtest 'Service objects have correct types' => sub {
    my $bz = Test::Bugzilla->new(
        base_url => 'http://bugzilla.example.com',
        api_key  => 'abc',
    );
    isa_ok($bz->attachment,           'WebService::Bugzilla::Attachment', 'attachment service class');
    isa_ok($bz->bug,                  'WebService::Bugzilla::Bug', 'bug service class');
    isa_ok($bz->bug_user_last_visit,  'WebService::Bugzilla::BugUserLastVisit', 'bug_user_last_visit service class');
    isa_ok($bz->classification,       'WebService::Bugzilla::Classification', 'classification service class');
    isa_ok($bz->comment,              'WebService::Bugzilla::Comment', 'comment service class');
    isa_ok($bz->component,            'WebService::Bugzilla::Component', 'component service class');
    isa_ok($bz->field,                'WebService::Bugzilla::Field', 'field service class');
    isa_ok($bz->flag_activity,        'WebService::Bugzilla::FlagActivity', 'flag_activity service class');
    isa_ok($bz->github,               'WebService::Bugzilla::GitHub', 'github service class');
    isa_ok($bz->group,                'WebService::Bugzilla::Group', 'group service class');
    isa_ok($bz->information,          'WebService::Bugzilla::Information', 'information service class');
    isa_ok($bz->product,              'WebService::Bugzilla::Product', 'product service class');
    isa_ok($bz->reminder,             'WebService::Bugzilla::Reminder', 'reminder service class');
    isa_ok($bz->user,                 'WebService::Bugzilla::User', 'user service class');
};

subtest 'Service objects are singletons' => sub {
    my $bz = Test::Bugzilla->new(
        base_url => 'http://bugzilla.example.com',
        api_key  => 'abc',
    );
    ok($bz->bug      == $bz->bug,      'bug returns same instance');
    ok($bz->reminder == $bz->reminder, 'reminder returns same instance');
};

subtest 'Client requires base_url' => sub {
    eval { WebService::Bugzilla->new() };
    ok($@, 'new without base_url dies');
    like($@, qr/base_url/, 'error mentions base_url');
};

subtest 'Query parameter encoding' => sub {
    package Test::EncodingCheck;
    use Moo;
    extends 'WebService::Bugzilla';
    has captured_url => (is => 'rw');
    has '+allow_http' => (default => 1);
    around req => sub {
        my ($orig, $self, $req, %args) = @_;
        $self->captured_url($req->uri->as_string);
        return { bugs => [] };
    };

    package main;
    my $enc = Test::EncodingCheck->new(
        base_url => 'http://example.com',
    );

    $enc->bug->search(quicksearch => 'hello world & foo=bar', limit => 5);
    like($enc->captured_url, qr/quicksearch=hello%20world%20%26%20foo%3Dbar/,
        'quicksearch param is URL-encoded in request URL');

    $enc->bug->search(quicksearch => 'test', tags => [ 'a&b', 'c d' ]);
    like($enc->captured_url, qr/tags%5B%5D=a%26b/,
        'arrayref param values are URL-encoded in request URL');
    like($enc->captured_url, qr/tags%5B%5D=c%20d/,
        'arrayref param values with spaces are URL-encoded');
};

done_testing();
