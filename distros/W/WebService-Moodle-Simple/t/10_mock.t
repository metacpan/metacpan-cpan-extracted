use strict;
use warnings;
use Test::More;
use HTTP::Response;
use LWP::UserAgent;
use URI;
use WebService::Moodle::Simple;

note 'Testing without a Moodle server';

my $domain = 'moodle.example.com';
my $moodle = WebService::Moodle::Simple->new(
    domain   => $domain,
    username => 'apiuser',
    target   => 'local_wssetup',
    token    => '0123456789abcdef',
);

is(ref($moodle), 'WebService::Moodle::Simple');
is($moodle->dns_uri, "https://${domain}:443", 'uri derived from parameters');

# Replace the HTTP layer: record each request and answer with the next
# canned body.
my (@requests, @bodies);
{
    no warnings 'redefine';
    *LWP::UserAgent::request = sub {
        my ($ua, $req) = @_;
        push @requests, $req;
        my $res = HTTP::Response->new(200, 'OK', [], shift @bodies);
        $res->request($req);
        return $res;
    };
}

sub form_of {
    my $req = shift;
    my $uri = URI->new('http:');
    $uri->query($req->content);
    return { $uri->query_form };
}

my $user_json = '[{"id":7,"username":"fred","customfields":[]}]';

subtest 'check_password POSTs credentials' => sub {
    @requests = ();
    @bodies = ('{"token":"abc","privatetoken":null}');
    my $resp = $moodle->check_password(username => 'fred', password => 's3cret');
    is $resp->{ok}, 1, 'token means ok';

    my $req = $requests[0];
    is $req->method, 'POST', 'sent as POST';
    is $req->uri->path, '/login/token.php', 'token endpoint';
    is $req->uri->query, undef, 'nothing in the query string';
    is_deeply form_of($req),
        { username => 'fred', password => 's3cret', service => 'moodle_mobile_app' },
        'credentials in the form body';

    @bodies = ('{"error":"Invalid login","errorcode":"invalidlogin"}');
    is $moodle->check_password(username => 'fred', password => 'x')->{ok}, 0,
        'no token means not ok';
};

subtest 'REST calls are POSTed' => sub {
    @requests = ();
    @bodies = ($user_json);
    $moodle->get_user(username => 'Fred');
    my $req = $requests[0];
    is $req->method, 'POST', 'sent as POST';
    is $req->uri->path, '/webservice/rest/server.php', 'REST endpoint';
    is $req->uri->query, undef, 'nothing in the query string';
    is form_of($req)->{wsfunction}, 'core_user_get_users_by_field', 'function in the body';
    is form_of($req)->{'values[0]'}, 'fred', 'username lower-cased';
};

my %update_cases = (
    'null (Moodle 3.2)'          => ['null', 1],
    'empty warnings (Moodle 5.3)' => ['{"warnings":[]}', 1],
    'warnings'                   => ['{"warnings":[{"item":"user","itemid":7,"warningcode":"updateusererror","message":"x"}]}', 0],
    'exception'                  => ['{"exception":"invalid_parameter_exception","errorcode":"invalidparameter","message":"x"}', 0],
);

for my $method (qw/set_password suspend_user/) {
    subtest "$method reports update failures" => sub {
        for my $case (sort keys %update_cases) {
            my ($body, $ok) = @{ $update_cases{$case} };
            @bodies = ($user_json, $body);
            my $resp = $moodle->$method(username => 'fred', password => 'p');
            is $resp->{ok}, $ok, "$case => ok $ok";
        }
    };
}

subtest 'get_course_id tolerates extra fields' => sub {
    @bodies = ('[{"id":1,"shortname":"site","customfields":[],"showactivitydates":true},'
             . '{"id":3,"shortname":"perl","customfields":[{"name":"x"}],"pdfexportfont":"x"}]');
    is $moodle->get_course_id(short_cname => 'perl'), 3, 'course found';
};

done_testing();
