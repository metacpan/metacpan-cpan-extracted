# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use lib "./t";
use strict;
use warnings;

use Test;

BEGIN { plan tests => 26 }

use Servlet::ServletResponseWrapper ();
use Servlet::Test::Response;

my $tres = Servlet::Test::Response->new();
ok(my $wres = Servlet::ServletResponseWrapper->new($tres));

# verify that the wrapper object delegates each method call to
# $tres. the test response object will simply echo back the name of
# the method.

my @methods;
push @methods, qw(flushBuffer getBufferSize getCharacterEncoding getLocale);
push @methods, qw(getWriter isCommitted reset resetBuffer);
push @methods, qw(setBufferSize setContentLength setContentType setLocale);

for my $method (@methods) {
    my ($rv) = eval { $wres->$method() };
    ok(!$@);
    ok($rv, $method);
}

# returns an output handle object
my $output = eval { $wres->getOutputHandle() };
ok(!$@);

exit;

