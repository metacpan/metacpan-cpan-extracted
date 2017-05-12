# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use lib "./t";
use strict;
use warnings;

use Test;

BEGIN { plan tests => 45}

use Servlet::Http::HttpServletRequestWrapper ();
use Servlet::Test::HttpRequest ();

my $treq = Servlet::Test::HttpRequest->new();
ok(my $wreq = Servlet::Http::HttpServletRequestWrapper->new($treq));

# verify that the wrapper object delegates each method call to
# $treq. the test request object will simply echo back the name of
# the method.

my @methods;
push @methods, qw(getAuthType getContextPath getCookies getDateHeader);
push @methods, qw(getHeaderNames getHeader getHeaders getMethod getPathInfo);
push @methods, qw(getPathTranslated getQueryString getRemoteUser);
push @methods, qw(getRequestedSessionId getRequestURI getRequestURL);
push @methods, qw(getServletPath getSession getUserPrincipal);
push @methods, qw(isRequestedSessionIdFromCookie isRequestedSessionIdFromURL);
push @methods, qw(isRequestedSessionIdValid isUserInRole);

for my $method (@methods) {
    my $rv = eval { $wreq->$method() };
    ok(!$@);
    ok($rv, $method);
}

exit;
