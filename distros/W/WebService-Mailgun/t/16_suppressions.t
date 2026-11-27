use strict;
use warnings;
use utf8;
use File::Temp qw(tempfile);
use JSON;
use Test::More 0.98;
use URI;
use WebService::Mailgun;

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
    sub delete { $_[0]->_record(DELETE => $_[1]) }
    sub request {
        my ($self, $req) = @_;
        push @{ $self->{requests} }, {
            line         => $req->method . ' ' . _plain($req->uri),
            content_type => scalar $req->content_type,
            body         => $req->content,
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

my $v3 = 'https://api.mailgun.net/v3/example.com';

my @kinds = (
    {
        path => 'bounces', list => 'bounces', one => 'bounce', add => 'add_bounce',
        add_many => 'add_bounces', import => 'import_bounces',
        delete => 'delete_bounce', delete_all => 'delete_bounces',
    },
    {
        path => 'unsubscribes', list => 'unsubscribes', one => 'unsubscribe',
        add => 'add_unsubscribe', add_many => 'add_unsubscribes',
        import => 'import_unsubscribes',
        delete => 'delete_unsubscribe', delete_all => 'delete_unsubscribes',
    },
    {
        path => 'complaints', list => 'complaints', one => 'complaint',
        add => 'add_complaint', add_many => 'add_complaints', import => 'import_complaints',
        delete => 'delete_complaint', delete_all => 'delete_complaints',
    },
    {
        path => 'whitelists', list => 'allowlist_entries', one => 'allowlist_entry',
        add => 'add_allowlist_entry', import => 'import_allowlist',
        delete => 'delete_allowlist_entry', delete_all => 'delete_allowlist',
    },
);

my ($fh, $csv) = tempfile(SUFFIX => '.csv', UNLINK => 1);
print {$fh} "address\nuser\@example.com\n";
close $fh;

for my $kind (@kinds) {
    my $base = "$v3/$kind->{path}";
    my ($list, $one, $add, $add_many, $import, $delete, $delete_all)
        = @$kind{qw(list one add add_many import delete delete_all)};

    subtest "$list() follows every page" => sub {
        local @responses = (
            qq({"items":[{"address":"a\@example.com"}],"paging":{"next":"$base?page=next&address=a%40example.com"}}),
            qq({"items":[],"paging":{"next":"$base?page=next&address=a%40example.com&limit=10"}}),
        );
        my ($items, $next);
        my $requests = requests_of(sub { ($items, $next) = $mailgun->$list({ limit => 10 }) });
        is_deeply [ map { $_->{line} } @$requests ], [
            "GET $base?limit=10",
            "GET $base?page=next&address=a%40example.com&limit=10",
        ];
        is_deeply $items, [ { address => 'a@example.com' } ];
        is "$next", "$base?page=next&address=a%40example.com&limit=10";
    };

    subtest "$one(\$address)" => sub {
        local @responses = ('{"address":"a/b@example.com"}');
        my $entry;
        my $requests = requests_of(sub { $entry = $mailgun->$one('a/b@example.com') });
        is $requests->[0]{line}, "GET $base/a%2Fb\@example.com";
        is_deeply $entry, { address => 'a/b@example.com' };
    };

    subtest "$add(\$args) sends a form" => sub {
        my $requests = requests_of(sub { $mailgun->$add({ address => 'ü@example.com' }) });
        is $requests->[0]{line}, "POST $base";
        is_deeply $requests->[0]{content}, [ address => "\xC3\xBC\@example.com" ];
    };

    if ($add_many) {
        subtest "$add_many(\\\@records) sends JSON" => sub {
            my @records = ({ address => 'a@example.com' }, { address => 'ü@example.com' });
            my $requests = requests_of(sub { $mailgun->$add_many(\@records) });
            is $requests->[0]{line}, "POST $base";
            is $requests->[0]{headers}{'Content-Type'}, 'application/json';
            is_deeply decode_json($requests->[0]{content}), \@records;
        };
    }
    else {
        ok !$mailgun->can("add_${list}"), "no method to add many to $kind->{path}";
    }

    subtest "$import(\$path) sends the file" => sub {
        my $requests = requests_of(sub { $mailgun->$import($csv) });
        is $requests->[0]{line}, "POST $base/import";
        like $requests->[0]{content_type}, qr{^multipart/form-data};
        like $requests->[0]{body}, qr{name="file"; filename="[^"]+\.csv"};
        like $requests->[0]{body}, qr{user\@example\.com};
    };

    subtest "$delete(\$address) and $delete_all()" => sub {
        is_deeply [ map { $_->{line} } @{ requests_of(sub { $mailgun->$delete('a@example.com') }) } ],
            ["DELETE $base/a\@example.com"];
        is_deeply [ map { $_->{line} } @{ requests_of(sub { $mailgun->$delete_all() }) } ],
            ["DELETE $base"];
    };

    subtest "$kind->{path}: what is not given dies without a request" => sub {
        for my $case (
            [ "$one(undef)"          => sub { $mailgun->$one(undef) } ],
            [ "$delete('')"          => sub { $mailgun->$delete('') } ],
            [ "$list([])"            => sub { $mailgun->$list([]) } ],
            [ "$add('a\@example.com')" => sub { $mailgun->$add('a@example.com') } ],
            [ "$import(missing)"     => sub { $mailgun->$import('t/no-such-file.csv') } ],
            [ "$import(undef)"       => sub { $mailgun->$import(undef) } ],
            ($add_many ? (
                [ "$add_many([])"     => sub { $mailgun->$add_many([]) } ],
                [ "$add_many({})"     => sub { $mailgun->$add_many({}) } ],
                [ "$add_many(['a'])"  => sub { $mailgun->$add_many(['a@example.com']) } ],
            ) : ()),
        ) {
            my ($name, $code) = @$case;
            my $requests = requests_of(sub { eval { $code->(); 1 } and fail "$name did not die" });
            is_deeply $requests, [], "$name sends nothing";
        }
    };
}

subtest 'an array reference in add_unsubscribe() sends the key once for each' => sub {
    my $requests = requests_of(sub {
        $mailgun->add_unsubscribe({ address => 'u@example.com', tag => ['a', 'b'] });
    });
    my @pairs = @{ $requests->[0]{content} };
    my @tags = map { $pairs[$_ + 1] } grep { $_ % 2 == 0 && $pairs[$_] eq 'tag' } 0 .. $#pairs;
    is_deeply \@tags, ['a', 'b'];
};

subtest 'add_bounces() sends code as a JSON string, without changing the records' => sub {
    # Mailgun answers `400 Invalid JSON` to the code as a number.
    my @records = (
        { address => 'a@example.com', code => 550, error => 'No such user' },
        { address => 'b@example.com', code => '551' },
        { address => 'c@example.com' },
    );
    my $requests = requests_of(sub { $mailgun->add_bounces(\@records) });
    my $sent = $requests->[0]{content};
    like $sent, qr/"code":"550"/;
    like $sent, qr/"code":"551"/;
    unlike $sent, qr/"code":\d/;
    ok !exists decode_json($sent)->[2]{code}, 'a missing code stays missing';
    is_deeply decode_json($sent), [
        { address => 'a@example.com', code => '550', error => 'No such user' },
        { address => 'b@example.com', code => '551' },
        { address => 'c@example.com' },
    ];
    like encode_json($records[0]), qr/"code":550/, 'the record given still has its number';
};

subtest 'delete_unsubscribe($address, $tag) removes only that tag' => sub {
    my $base = "$v3/unsubscribes";
    is_deeply [ map { $_->{line} } @{ requests_of(sub { $mailgun->delete_unsubscribe('a@example.com', 'news & more') }) } ],
        ["DELETE $base/a\@example.com?tag=news+%26+more"];
    is_deeply [ map { $_->{line} } @{ requests_of(sub { $mailgun->delete_unsubscribe('a@example.com', "\x{65E5}") }) } ],
        ["DELETE $base/a\@example.com?tag=%E6%97%A5"], 'a decoded tag goes out as UTF-8';
    is_deeply [ map { $_->{line} } @{ requests_of(sub { $mailgun->delete_unsubscribe('a@example.com', URI->new('news')) }) } ],
        ["DELETE $base/a\@example.com?tag=news"], 'an object that is a string';
    for my $case ([ "''" => '' ], [ '[]' => [] ], [ 'undef' => undef ]) {
        my $requests = requests_of(sub {
            eval { $mailgun->delete_unsubscribe('a@example.com', $case->[1]); 1 } and fail "$case->[0] did not die";
        });
        is_deeply $requests, [], "a tag of $case->[0] dies without a request";
    }
    for my $delete (qw(delete_bounce delete_complaint delete_allowlist_entry)) {
        my $requests = requests_of(sub {
            eval { $mailgun->$delete('a@example.com', 'news'); 1 } and fail "$delete with a tag did not die";
        });
        is_deeply $requests, [], "$delete() with a second argument dies without a request";
    }
};

subtest 'a decoded file name goes out as UTF-8' => sub {
    my $dir = File::Temp->newdir;
    my $name = "$dir/\x{65E5}\x{672C}.csv";
    my $bytes = $name;
    utf8::encode($bytes);
    open my $out, '>', $bytes or die $!;
    print {$out} "address\n";
    close $out;
    my $requests = requests_of(sub { $mailgun->import_bounces($name) });
    like $requests->[0]{body}, qr{filename="\xE6\x97\xA5\xE6\x9C\xAC\.csv"};
};

subtest 'a domain is required' => sub {
    my $no_domain = WebService::Mailgun->new(api_key => 'dummy-api-key');
    $no_domain->{_client} = $client;
    my $requests = requests_of(sub { eval { $no_domain->delete_bounces(); 1 } and fail 'did not die' });
    is_deeply $requests, [];
};

done_testing;
