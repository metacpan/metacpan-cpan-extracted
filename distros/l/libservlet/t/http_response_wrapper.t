# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use lib "./t";
use strict;
use warnings;

use Test;

BEGIN { plan tests => 23 }

use Servlet::Http::HttpServletResponseWrapper ();
use Servlet::Test::HttpResponse ();

my $tres = Servlet::Test::HttpResponse->new();
ok(my $wres = Servlet::Http::HttpServletResponseWrapper->new($tres));

# verify that the wrapper object delegates each method call to
# $tres. the test response object will simply echo back the name of
# the method.

my @methods;
push @methods, qw(addCookie addDateHeader addHeader containsHeader);
push @methods, qw(encodeRedirectURL encodeURL sendError sendRedirect);
push @methods, qw(setDateHeader setHeader setStatus);

for my $method (@methods) {
    my $rv = eval { $wres->$method() };
    ok(!$@);
    ok($rv, $method);
}

exit;
