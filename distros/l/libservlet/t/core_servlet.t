# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use lib "./t";
use strict;
use warnings;

use Test;

BEGIN { plan tests => 10 }

use Servlet::GenericServlet ();
use Servlet::Test::Context ();
use Servlet::Test::Request ();
use Servlet::Test::Response ();
use Servlet::Test::ServletConfig ();
use Servlet::Util::Exception ();

# server startup

my $context = Servlet::Test::Context->new();
my $config = Servlet::Test::ServletConfig->new($context);

ok(my $servlet = Servlet::GenericServlet->new());

eval { $servlet->init($config) };
ok(!$@);

ok(ref $servlet->getServletConfig(), ref $config);
ok(ref $servlet->getServletContext(), ref $context);
ok($servlet->getServletInfo(), '');
ok($servlet->getServletName(), 'getServletName');

# per request

my $request = Servlet::Test::Request->new();
my $response = Servlet::Test::Response->new();

eval { $servlet->service($request, $response) };
ok(!$@);

ok($servlet->log('no problems'), 'log');

my $e = Servlet::Util::Exception->new(error => 'fake exception');
ok($servlet->log('had a problem', $e), 'log');

# server shutdown

eval { $servlet->destroy() };
ok(!$@);

exit;
