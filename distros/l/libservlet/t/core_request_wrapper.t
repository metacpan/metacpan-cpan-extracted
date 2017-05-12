# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use lib "./t";
use strict;
use warnings;

use Test;

BEGIN { plan tests => 44 }

use Servlet::ServletRequestWrapper ();
use Servlet::Test::Request;

my $treq = Servlet::Test::Request->new();
ok(my $wreq = Servlet::ServletRequestWrapper->new($treq));

# verify that the wrapper object delegates each method call to
# $treq. the test request object will simply echo back the name of
# the method.

my @methods;
push @methods, qw(getAttributeNames removeAttribute);
push @methods, qw(setAttribute getCharacterEncoding setCharacterEncoding);
push @methods, qw(getContentLength getContentType getLocale);
push @methods, qw(getLocales getParameterMap getParameterNames getParameter);
push @methods, qw(getParameterValues getProtocol getReader getRemoteAddr);
push @methods, qw(getRemoteHost getRequestDispatcher getServerName);
push @methods, qw(getServerPort isSecure);

for my $method (@methods) {
    my ($rv) = eval { $wreq->$method() };
    ok(!$@);
    ok($rv, $method);
}

# returns an input handle object
my $input = eval { $wreq->getInputHandle() };
ok(!$@);

exit;
