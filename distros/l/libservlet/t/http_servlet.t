# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use lib "./t";
use strict;
use warnings;

use Test;

BEGIN { plan tests => 25 }

use Servlet::Http::HttpServlet ();
use Servlet::Test::HttpRequest ();
use Servlet::Test::HttpResponse ();

my $Methods = {
               delete => Servlet::Http::HttpServlet::METHOD_DELETE,
               get => Servlet::Http::HttpServlet::METHOD_GET,
               head => Servlet::Http::HttpServlet::METHOD_HEAD,
               options => Servlet::Http::HttpServlet::METHOD_OPTIONS,
               post => Servlet::Http::HttpServlet::METHOD_POST,
               put => Servlet::Http::HttpServlet::METHOD_PUT,
               trace => Servlet::Http::HttpServlet::METHOD_TRACE,
              };

ok(my $servlet = Servlet::Http::HttpServlet->new());

my $request = Servlet::Test::HttpRequest->new();
my $response = Servlet::Test::HttpResponse->new();

ok($servlet->getLastModified($request), -1);

eval { $servlet->service($request, $response) };
ok(!$@);

# type checking exception
eval { $servlet->service($request, $request->getInputHandle()) };
ok($@);

for my $m (sort keys %$Methods) {
    # execute doXXX directly
    my $method = sprintf "do%s", ucfirst $m;
    eval { $servlet->$method($request, $response) };
    ok(!$@);

    # delegate to doXXX via service
    $request->{method} = $Methods->{$m};
    eval { $servlet->service($request, $response) };
    ok(!$@);

    if ($m eq 'options') {
        ok($response->{headers}->{Allow}->[0],
           join(', ', map { uc $_} sort keys %$Methods ));
    } elsif ($m eq 'trace') {
        ok($response->{contentType}, 'message/http');
    } else {
        ok($response->{message},
           'HTTP method ' . uc($m) . ' is not supported');
    }
}

exit;
