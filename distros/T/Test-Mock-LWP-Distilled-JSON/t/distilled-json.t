#!/usr/bin/env perl
# Tests for Test::Mock::LWP::Distilled::JSON

use strict;
use warnings;
use lib::abs 'lib';

use Test::More import => [qw(!like)];
use Test2::Tools::Compare qw(like T);

use HTTP::Status qw(:constants);
use JSON::MaybeXS;
use LWP::JSON::Tiny;

my $test_class = 'Simple::JSON::Mock::Class';
use Simple::JSON::Mock::Class;

subtest 'Distill response from JSON or HTML' => \&test_distill_response;
subtest 'Generate response from a mock'      => \&test_generate_response;

done_testing();

# If we get JSON back from a server, we turn that into a mock. If we get
# HTML because e.g. the server's broken and we get their standard
# 500 page, we can cope with that and don't crash.

sub test_distill_response {
    my $mock_object = $test_class->new(mode => 'record');

    # Valid JSON gets turned into a Perl data structure.
    no warnings 'redefine';
    local *LWP::UserAgent::simple_request = sub {
        my ($self, $request, $arg, $size) = @_;
        
        return HTTP::Response->new(
            HTTP_NO_CONTENT, undef, ['Content-Type' => 'application/json'],
            <<'JSON_BODY'
{
    "stuff": [
        "elk",
        "some lard"
    ],
    "source": {
        "url": "http://www.monkeydyne.com/rmcs/dbcomic.phtml?rowid=3026",
        "bitrot": true,
        "still_on_archive_dot_org": "hooray!"
    },
    "was_the_code_a_lie": "yes"
}
JSON_BODY
        );
    };
    use warnings 'redefine';

    my $response = $mock_object->get('https://any-url-doesnt-matter.lol');
    ok $response->isa('HTTP::Response::JSON'), 'Our response was a JSON response';
    like $mock_object->mocks->[0]{distilled_response},
        {
            code         => HTTP_NO_CONTENT,
            json_content => {
                source => {
                    url    => qr{^ \Qhttp://www.monkeydyne.com\E }x,
                    bitrot => T(),
                    still_on_archive_dot_org => 'hooray!',
                },
                stuff              => ['elk', 'some lard'],
                was_the_code_a_lie => 'yes',
            },
        },
        'JSON was turned into a Perl data structure';

    # HTML is returned verbatim.
    no warnings 'redefine';
    local *LWP::UserAgent::simple_request = sub {
        my ($self, $request, $arg, $size) = @_;
        
        return HTTP::Response::JSON->new(
            HTTP_INTERNAL_SERVER_ERROR, undef,
            ['Content-Type' => 'text/html'],
            <<'HTML_BODY'
<html>
<head>
<title>Whoops</title>
</head>
<body>
<p>Well, that didn't work. Huh.</p>
</body>
</html>
HTML_BODY
        );
    };
    use warnings 'redefine';

    $mock_object->get('https://halt-and-catch-fire.lol');
    like $mock_object->mocks->[1]{distilled_response},
        {
            code            => HTTP_INTERNAL_SERVER_ERROR,
            content_type    => 'text/html',
            decoded_content => qr/^<html> .+ Whoops .+ didn't \s work /xsm,
        },
        'Non-JSON is recorded as-is';
    
    # Clean out the mocks to avoid them being dumped to a file.
    @{ $mock_object->mocks } = ();
}

# We can turn that distilled response into a proper response again.

sub test_generate_response {
    # Set up mocks: one HTML, one JSON.
    my $mock_object = $test_class->new(mode => 'play');
    @{ $mock_object->{mocks} } = (
        {
            distilled_request  => 'Ignored',
            distilled_response => {
                code            => HTTP_PAYMENT_REQUIRED,
                content_type    => 'text/html',
                decoded_content => '<html><title>Pay up!</title></head>'
            }
        },
        {
            distilled_request  => 'Ignored',
            distilled_response => {
                code         => HTTP_OK,
                json_content => {
                    logged_in => JSON->true,
                    content   => {
                        link       => 'Some article',
                        other_link => 'Some other article',
                    },
                    underwhelming => 'pretty',
                }
            },
        }
    );

    # The HTML response looks the part.
    my $response_html = $mock_object->get('https://log-in-now.law');
    like $response_html->as_string, qr{
        ^
        402 \s Payment \s Required \n
        Content-Type: \s text/html \n
        \n
        <html><title>Pay \s up!</title></head>
    }x, 'An HTML mock is turned into HTML';

    # The Perl data structure is turned into JSON.
    # Formatted for legibility here, but it'll be returned without any
    # formatting.
    my $response_json = $mock_object->get('https://are-you-happy-now.sucks');
    ok $response_json->isa('HTTP::Response::JSON'), 'We got a JSON response object back';
    like $response_json->as_string, qr{
        ^
        200 \s OK \n
        Content-Type: \s application/json \n
    }x, 'A JSON mock is returned as JSON...';
    my $expected_json = <<'JSON';
{
    "content":{
        "link":"Some article",
        "other_link":"Some other article"
    },
    "logged_in":true,
    "underwhelming":"pretty"
}
JSON
    $expected_json =~ s/^\s+//mg;
    $expected_json =~ s/\n//g;
    is $response_json->decoded_content, $expected_json, '...the proper JSON';
}
