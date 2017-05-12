use strict;
use Test::More;
use URI;
use URI::QueryParam;

BEGIN
{
    plan( tests => 7 );
    use_ok("WebService::Simple::Google::Chart");
}

{
    my $chart = WebService::Simple::Google::Chart->new;
    ok( $chart, "object created ok" );
    isa_ok(
        $chart,
        "WebService::Simple::Google::Chart",
        "object isa WebService::Simple::Google::Chart"
    );
    my $data = { foo => 200, bar => 130, hoge => 70 };
    my $url = $chart->get_url(
        {
            chs  => "250x100",
            cht => "p3",
        },
        $data
    );
    my $uri = URI->new($url);
    ok( $uri->query_param("chs") eq "250x100",      "chs parameter ok" );
    ok( $uri->query_param("cht") eq "p3",           "cht parameter ok" );
    ok( $uri->query_param("chl") eq "bar|foo|hoge", "chl parameter ok" );
    ok( $uri->query_param("chd") eq "t:33,50,18",   "chd parameter ok" );
}
