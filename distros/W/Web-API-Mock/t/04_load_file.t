use strict;
use Test::More;
use Plack::Test;

use_ok $_ for qw(
    Web::API::Mock::Parser
    Web::API::Mock
);

my $mock = Web::API::Mock->new();

subtest load_file => sub {
    $mock->setup(['t/md/api.md', 't/md/hello.md'], 't/not-implemented-urls.txt');

    note explain $mock->map->url_list;

    is 1,1;
};

my $app = $mock->psgi();

test_psgi $app, sub {
     my $cb  = shift;
     subtest hello => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/hello");
         my $res = $cb->($req);
         like $res->content, qr/Hello World/;
     };

     subtest post_hello => sub {
         my $req = HTTP::Request->new(POST => "http://localhost/hello");
         my $res = $cb->($req);
         like $res->content, qr/POST Hello World/;
     };

     subtest get_sample => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/api/sample");
         my $res = $cb->($req);
         like $res->status_line, qr/405/;
     };

     subtest get_sample_id => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/api/sample/12345");
         my $res = $cb->($req);
         like $res->status_line, qr/200/;
         note $res->content;
     };

     subtest get_sample => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/api/hoge");
         my $res = $cb->($req);
         like $res->status_line, qr/404/;
     };

     subtest root => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/");
         my $res = $cb->($req);
         like $res->status_line, qr/404/;
         note $res->content;
     };

     subtest not_implemented_url => sub {
         my $req = HTTP::Request->new(GET => "http://localhost/api/xyz");
         my $res = $cb->($req);
         like $res->status_line, qr/501/;
         $req = HTTP::Request->new(GET => "http://localhost/api/abc/1234");
         $res = $cb->($req);
         like $res->status_line, qr/501/;

         note $res->content;
     };





};

done_testing;
