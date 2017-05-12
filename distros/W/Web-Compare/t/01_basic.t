use strict;
use warnings;
use Test::More;
use Test::Fake::HTTPD;
use LWP::UserAgent;

use Web::Compare;

{

    my $left = run_http_server {
        my $req = shift;

        is $req->method, 'GET';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Perl!\n</body>\n</html>\n"]
        ];
    };

    my $right = run_http_server {
        my $req = shift;

        is $req->method, 'GET';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Ruby!\n</body>\n</html>\n"]
        ];
    };

    my $wc = Web::Compare->new($left->endpoint, $right->endpoint);

    is $wc->report, <<_DIFF_;
@@ -1,5 +1,5 @@
 <html>
 <body>
-Hello, Perl!
+Hello, Ruby!
 </body>
 </html>
_DIFF_

}

{

    my $left = run_http_server {
        my $req = shift;

        is $req->method, 'POST';
        is $req->content, 'foo=1';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Java!\n</body>\n</html>\n"]
        ];
    };

    my $right = run_http_server {
        my $req = shift;

        is $req->method, 'POST';
        is $req->content, 'bar=2';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, C#!\n</body>\n</html>\n"]
        ];
    };

    my $req_left = HTTP::Request->new(POST => $left->endpoint);
    $req_left->content('foo=1');

    my $req_right = HTTP::Request->new(POST => $right->endpoint);
    $req_right->content('bar=2');

    my $wc = Web::Compare->new($req_left, $req_right);

    is $wc->report, <<_DIFF_;
@@ -1,5 +1,5 @@
 <html>
 <body>
-Hello, Java!
+Hello, C#!
 </body>
 </html>
_DIFF_

}

{

    my $left = run_http_server {
        my $req = shift;

        is $req->method, 'GET';
        is $req->user_agent, 'Web::Compare';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Golang!\n</body>\n</html>\n"]
        ];
    };

    my $right = run_http_server {
        my $req = shift;

        is $req->method, 'GET';
        is $req->user_agent, 'Web::Compare';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, PHP!\n</body>\n</html>\n"]
        ];
    };

    my $wc = Web::Compare->new(
        $left->endpoint, $right->endpoint, +{
            ua => LWP::UserAgent->new(timeout => 3, agent => 'Web::Compare'),
        }
    );

    is $wc->report, <<_DIFF_;
@@ -1,5 +1,5 @@
 <html>
 <body>
-Hello, Golang!
+Hello, PHP!
 </body>
 </html>
_DIFF_

}

done_testing;
