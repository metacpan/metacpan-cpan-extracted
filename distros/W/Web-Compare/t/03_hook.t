use strict;
use warnings;
use Test::More;
use Test::Fake::HTTPD;

use Web::Compare;

{

    my $left = run_http_server {
        my $req = shift;

        is $req->header('X-foo'), 'bar';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Perl!\n</body>\n</html>\n"]
        ];
    };

    my $right = run_http_server {
        my $req = shift;

        is $req->header('X-foo'), 'bar';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Ruby!\n</body>\n</html>\n"]
        ];
    };

    my $wc = Web::Compare->new(
        $left->endpoint, $right->endpoint, {
            hook_before => sub {
                my ($self, $req) = @_;

                $req->header('X-foo' => 'bar');
            },
        },
    );

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

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Perl!\n</body>\n</html>\n"]
        ];
    };

    my $right = run_http_server {
        my $req = shift;

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Ruby!\n</body>\n</html>\n"]
        ];
    };

    my $wc = Web::Compare->new(
        $left->endpoint, $right->endpoint, {
            hook_after => sub {
                my ($self, $res, $req) = @_;

                (my $content = $res->content) =~ s!Hello!Hi!;
                return $content;
            },
        },
    );

    is $wc->report, <<_DIFF_;
@@ -1,5 +1,5 @@
 <html>
 <body>
-Hi, Perl!
+Hi, Ruby!
 </body>
 </html>
_DIFF_

}

{

    my $left = run_http_server {
        my $req = shift;

        is $req->header('X-foo'), 'baz';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Perl!\n</body>\n</html>\n"]
        ];
    };

    my $right = run_http_server {
        my $req = shift;

        is $req->header('X-foo'), 'baz';

        return [
            200,
            ['Content-Type' => 'text/html'],
            ["<html>\n<body>\nHello, Ruby!\n</body>\n</html>\n"]
        ];
    };

    my $wc = Web::Compare->new(
        $left->endpoint, $right->endpoint, {
            hook_before => sub {
                my ($self, $req) = @_;

                $req->header('X-foo' => 'baz');
            },
            hook_after => sub {
                my ($self, $res, $req) = @_;

                (my $content = $res->content) =~ s!Hello!Hi!;
                return $content;
            },
        },
    );

    is $wc->report, <<_DIFF_;
@@ -1,5 +1,5 @@
 <html>
 <body>
-Hi, Perl!
+Hi, Ruby!
 </body>
 </html>
_DIFF_

}

done_testing;
