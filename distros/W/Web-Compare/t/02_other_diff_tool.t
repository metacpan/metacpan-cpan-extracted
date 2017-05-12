use strict;
use warnings;
use Test::More;
use Test::Fake::HTTPD;

use Web::Compare;
use String::Diff qw//;

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
            diff => sub {
                my ($left, $right) = @_;

                String::Diff::diff_merge($left, $right);
            },
        },
    );

    is $wc->report, <<_DIFF_;
<html>
<body>
Hello, [Perl]{Ruby}!
</body>
</html>
_DIFF_

}

done_testing;