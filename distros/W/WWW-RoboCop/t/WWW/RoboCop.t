use Test::Fatal;
use Test::Most;

use WWW::Mechanize;
use WWW::RoboCop;
use Plack::Handler::HTTP::Server::Simple 0.016;
use Plack::Test::Agent;

use DDP;

my $html = <<EOF;
<a href="/foo">foo</a>
<a href="/bar">bar</a>
<a href="#">
<a href="">
EOF

my $app = sub { return [ 200, [ 'Content-Type' => 'text/html' ], [$html] ] };

my $server_agent = Plack::Test::Agent->new(
    app    => $app,
    server => 'HTTP::Server::Simple',
);

ok( $server_agent->get('/')->is_success, 'get HTML' );

my $robocop = WWW::RoboCop->new(
    is_url_allowed => sub {
        my $link = shift;
        return $link->URI->path ne '/bar';
    },
    report_for_url => sub {
        my $res = shift;
        return { status => $res->code, path => $res->base->path };
    },
);

$robocop->crawl( $server_agent->normalize_uri('/') );
my %report = $robocop->get_report;
ok( %report, 'get_report' );

my @results = sort { $a->{path} cmp $b->{path} } values %report;
is_deeply(
    \@results,
    [
        {
            path   => "/",
            status => 200,
        },
        {
            path   => "/foo",
            status => 200,
        },
    ],
    'custom report'
);

done_testing();
