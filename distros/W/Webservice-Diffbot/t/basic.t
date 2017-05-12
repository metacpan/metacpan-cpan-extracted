use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;
use Capture::Tiny 'capture';
use Test::Fatal;
use URI;
use version;

use WebService::Diffbot;

run();
done_testing;
exit;

sub run {
    my $token   = $ENV{DIFFBOT_TOKEN};
    my $url     = 'http://www.diffbot.com';

    ok my $diffbot = WebService::Diffbot->new(
        token   => $token,
        url     => $url,
    ), "can instantiate diffbot object";

    SKIP:
    {
        skip "no API token", 4 if not defined $token;

        my $response = $diffbot->article;
        ok $response, "request returned a response";
        is $response->{url}, $url, "received correct url";

        my $another_url = 'http://www.youtube.com';
        $response = $diffbot->article( url => $another_url );
        ok $response, "request returned a response";
        is $response->{url}, $another_url, "received correct url";
    }

    return;
}
