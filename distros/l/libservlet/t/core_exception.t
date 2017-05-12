# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use strict;
use warnings;

use Test;

BEGIN { plan tests => 25 }

use Servlet::ServletException ();
use Servlet::UnavailableException ();
use Servlet::Util::Exception ();

ok(my $e1 = Servlet::ServletException->new("exception 1"));
ok($e1->getMessage(), "exception 1");

ok(my $e2 = Servlet::ServletException->new("exception 2", $e1));
ok($e2->getRootCause());
ok($e2->getRootCause()->getMessage(), "exception 1");

ok(my $e3 = Servlet::UnavailableException->new("unavailable 1"));
ok($e3->isPermanent(), 1);
ok($e3->getUnavailableSeconds(), -1);

ok(my $e4 = Servlet::UnavailableException->new("unavailable 2", 30));
ok($e4->isPermanent(), 0);
ok($e4->getUnavailableSeconds(), 30);

ok(my $e5 = Servlet::Util::Exception->new("exception 5"));
ok($e5->getMessage(), "exception 5");

ok(my $e6 = Servlet::Util::IOException->new("exception 6"));
ok($e6->getMessage(), "exception 6");

ok(my $e7 = Servlet::Util::IllegalArgumentException->new("exception 7"));
ok($e7->getMessage(), "exception 7");

ok(my $e8 = Servlet::Util::IllegalStateException->new("exception 8"));
ok($e8->getMessage(), "exception 8");

ok(my $e9 = Servlet::Util::IndexOutOfBoundsException->new("exception 8"));
ok($e9->getMessage(), "exception 8");

ok(my $e10 = Servlet::Util::UndefReferenceException->new("exception 8"));
ok($e10->getMessage(), "exception 8");

ok(my $e11 = Servlet::Util::UnsupportedEncodingException->new("exception 9"));
ok($e11->getMessage(), "exception 9");

exit;
