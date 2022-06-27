use strict;
use warnings FATAL => 'all';

use File::Slurp;
use FindBin qw($Bin);
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Test::More;

my $pkg;
BEGIN {
    $pkg = "Plack::Middleware::Signposting::JSON";
    use_ok $pkg;
}
require_ok $pkg;

subtest "basic app without fix file" => sub {
    my $app = builder {
        enable "Plack::Middleware::Signposting::JSON";

        sub {[
            '200',
            ['Content-Type' => 'application/json'],
            ['{"signs": [["https://orcid.org/12345-im-an-orcid", "author"]]}']
        ]};
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        like $res->header('Link'), qr/\<https*:\/\/orcid.org\/12345-im-an-orcid\>; rel="author"/, 'ORCID in Link header';
        unlike $res->header('Link'), qr{rel="type"}, "no relation in Link header";
    };
};

subtest "app with fix file" => sub {
    my $json = read_file("$Bin/../example/publication.json");;

    my $app = builder {
        enable "Plack::Middleware::Signposting::JSON", fix => "$Bin/../example/signposting.fix";

        sub { [ '200', ['Content-Type' => 'application/json'], [$json] ] };
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        like $res->header('Link'), qr/\<https*:\/\/orcid.org\/0000-0002-7635-3473\>; rel="author"/, 'ORCID in Link header';
        like $res->header('Link'), qr/\<https*:\/\/schema.org\/ScholarlyArticle\>; rel="type"/, 'schema.org in Link header';
    };
};

done_testing;
