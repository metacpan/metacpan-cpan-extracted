use strict;
use warnings;
use utf8;
use lib 't/lib';
use JSON;
use Test::More 0.98;
use URI;
use WebService::Mailgun;
use t::Form ();

# This test never reaches a real API server: the HTTP client is replaced with one that records
# each request and answers with the bodies in @main::responses, in turn ('{}' when none is left).
our @responses;
{
    package t::Client;
    sub new { bless { requests => [] }, shift }
    sub _plain {
        my $u = URI->new($_[0]);
        $u->userinfo(undef);
        return "$u";
    }
    sub _record {
        my ($self, $method, $url, $headers, $content) = @_;
        push @{ $self->{requests} }, {
            line => "$method " . _plain($url),
            ($headers && @$headers ? (headers => { @$headers }) : ()),
            (defined $content ? (content => $content) : ()),
        };
        return t::Response->new(shift(@main::responses) // '{}');
    }
    sub get    { $_[0]->_record(GET    => $_[1]) }
    sub post   { $_[0]->_record(POST   => @_[1 .. 3]) }
    sub put    { $_[0]->_record(PUT    => @_[1 .. 3]) }
    sub delete { $_[0]->_record(DELETE => $_[1]) }
    sub request {
        my ($self, $req) = @_;
        push @{ $self->{requests} }, {
            line   => $req->method . ' ' . _plain($req->uri),
            fields => [ t::Form::fields_of($req) ],
        };
        return t::Response->new(shift(@main::responses) // '{}');
    }

    package t::Response;
    sub new         { bless { content => $_[1] }, $_[0] }
    sub is_success  { 1 }
    sub status_line { '200 OK' }
    sub content     { $_[0]{content} }
}

my $mailgun = WebService::Mailgun->new(
    api_key => 'dummy-api-key',
    domain  => 'example.com',
);
my $client = t::Client->new;
$mailgun->{_client} = $client;

sub requests_of {
    my ($code) = @_;
    @{ $client->{requests} } = ();
    $code->();
    return [ @{ $client->{requests} } ];
}

sub lines_of { [ map { $_->{line} } @{ requests_of($_[0]) } ] }

my $base = 'https://api.mailgun.net/v3/example.com/templates';

subtest 'templates() follows every page' => sub {
    local @responses = (
        qq({"items":[{"name":"a"}],"paging":{"next":"$base?page=next&p=a&limit=10"}}),
        qq({"items":null,"paging":{"next":"$base?page=next&p=a&limit=10"}}),
    );
    my ($items, $next);
    my $lines = lines_of(sub { ($items, $next) = $mailgun->templates({ limit => 10 }) });
    is_deeply $lines, [ "GET $base?limit=10", "GET $base?page=next&p=a&limit=10" ];
    is_deeply $items, [ { name => 'a' } ], 'a page of null items is the empty page';
    is "$next", "$base?page=next&p=a&limit=10";
};

subtest 'a page without items is still a failure' => sub {
    local @responses = ('{"paging":{}}');
    my ($items) = $mailgun->templates();
    is_deeply $items, [];
    is $mailgun->error, "the response has no 'items' list";
};

subtest 'null items stay a failure for the other lists' => sub {
    local @responses = ('{"items":null,"paging":{}}');
    my ($items) = $mailgun->lists();
    is_deeply $items, [];
    is $mailgun->error, "the response has no 'items' list";
};

subtest 'template($name, $query)' => sub {
    local @responses = ('{"template":{"name":"a/b"}}');
    my $template;
    my $lines = lines_of(sub { $template = $mailgun->template('a/b', { active => 'yes' }) });
    is_deeply $lines, ["GET $base/a%2Fb?active=yes"];
    is_deeply $template, { name => 'a/b' };

    local @responses = ('{"message":"ok"}');
    is $mailgun->template('a'), undef, 'a response without the template is a failure';
    is $mailgun->error, "the response has no 'template'";
};

subtest 'update_template($name, $args) sends form-data with PUT' => sub {
    my $requests = requests_of(sub { $mailgun->update_template(welcome => { description => 'Ünïcode' }) });
    is $requests->[0]{line}, "PUT $base/welcome";
    is_deeply $requests->[0]{fields}, [ [ description => "\xC3\x9Cn\xC3\xAFcode", undef ] ];
};

subtest 'add_template() sends a decoded string as UTF-8' => sub {
    my $requests = requests_of(sub { $mailgun->add_template({ name => 'w', template => "\x{3053}\x{3093}" }) });
    is $requests->[0]{line}, "POST $base";
    my %fields = map { $_->[0] => $_->[1] } @{ $requests->[0]{fields} };
    is $fields{template}, "\xE3\x81\x93\xE3\x82\x93";
};

subtest 'rename_template($name, $new_name)' => sub {
    is_deeply lines_of(sub { $mailgun->rename_template(welcome => 'new name') }),
        ["PUT $base/welcome/rename/new%20name"];
};

subtest 'copy_template($name, $args) sends JSON with PUT' => sub {
    my $args = { requests => [ { account_id => 'acc', name => 'welcome' } ] };
    my $requests = requests_of(sub { $mailgun->copy_template(welcome => $args) });
    is $requests->[0]{line}, "PUT $base/welcome/copy";
    is $requests->[0]{headers}{'Content-Type'}, 'application/json';
    is_deeply decode_json($requests->[0]{content}), $args;
};

subtest 'template_versions() takes the items under template.versions' => sub {
    local @responses = (
        qq({"template":{"name":"w","versions":[{"tag":"v1"}]},"paging":{"next":"$base/w/versions?page=next&p=v1"}}),
        qq({"template":{"name":"w","versions":[]},"paging":{"next":"$base/w/versions?page=next&p=v1"}}),
    );
    my ($versions, $next);
    my $lines = lines_of(sub { ($versions, $next) = $mailgun->template_versions('w') });
    is_deeply $lines, [ "GET $base/w/versions", "GET $base/w/versions?page=next&p=v1" ];
    is_deeply $versions, [ { tag => 'v1' } ];

    local @responses = ('{"template":{"name":"w"},"paging":{}}');
    ($versions) = $mailgun->template_versions('w');
    is $mailgun->error, "the response has no 'template.versions' list";
};

subtest 'template_version($name, $tag)' => sub {
    local @responses = ('{"template":{"name":"w","version":{"tag":"v1"}}}');
    my $template;
    is_deeply lines_of(sub { $template = $mailgun->template_version(w => 'v1') }),
        ["GET $base/w/versions/v1"];
    is $template->{version}{tag}, 'v1';
};

subtest 'add_template_version() and update_template_version() send form-data' => sub {
    my $requests = requests_of(sub {
        $mailgun->add_template_version(w => [ template => 'Hello', tag => 'v2' ]);
        $mailgun->update_template_version(w => 'v2', { active => 'yes' });
    });
    is $requests->[0]{line}, "POST $base/w/versions";
    is_deeply $requests->[0]{fields}, [ [ template => 'Hello', undef ], [ tag => 'v2', undef ] ];
    is $requests->[1]{line}, "PUT $base/w/versions/v2";
    is_deeply $requests->[1]{fields}, [ [ active => 'yes', undef ] ];
};

subtest 'delete_template_version() and copy_template_version()' => sub {
    is_deeply lines_of(sub { $mailgun->delete_template_version(w => 'v1') }),
        ["DELETE $base/w/versions/v1"];
    is_deeply lines_of(sub { $mailgun->copy_template_version(w => 'v1', 'v2', { comment => 'copy' }) }),
        ["PUT $base/w/versions/v1/copy/v2?comment=copy"];
    is_deeply lines_of(sub { $mailgun->copy_template_version(w => 'v1', 'v2') }),
        ["PUT $base/w/versions/v1/copy/v2"];
};

subtest 'what is not given dies without a request' => sub {
    for my $case (
        [ 'template(undef)'                 => sub { $mailgun->template(undef) } ],
        [ "template('w', [])"               => sub { $mailgun->template('w', []) } ],
        [ "rename_template('w', '')"        => sub { $mailgun->rename_template('w', '') } ],
        [ "copy_template('w', [])"          => sub { $mailgun->copy_template('w', []) } ],
        [ "update_template('w', 'x')"       => sub { $mailgun->update_template('w', 'x') } ],
        [ "template_version('w', undef)"    => sub { $mailgun->template_version('w', undef) } ],
        [ "add_template_version(undef, {})" => sub { $mailgun->add_template_version(undef, {}) } ],
        [ "copy_template_version('w', 'v1')" => sub { $mailgun->copy_template_version('w', 'v1') } ],
        [ 'templates([])'                   => sub { $mailgun->templates([]) } ],
    ) {
        my ($name, $code) = @$case;
        my $requests = requests_of(sub { eval { $code->(); 1 } and fail "$name did not die" });
        is_deeply $requests, [], "$name sends nothing";
    }
};

done_testing;
