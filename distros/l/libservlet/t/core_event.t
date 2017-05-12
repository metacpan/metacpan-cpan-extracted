# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use strict;
use warnings;

use Test;

BEGIN { plan tests => 10 }

use Servlet::ServletContextAttributeEvent ();
use Servlet::ServletContextEvent ();
use Servlet::Util::Event ();

ok(my $e1 = Servlet::Util::Event->new('e1'));
ok($e1->getSource(), 'e1');

ok(my $e2 = Servlet::ServletContextEvent->new('e2'));
ok($e2->getSource(), 'e2');
ok($e2->getServletContext(), 'e2');

ok(my $e3 = Servlet::ServletContextAttributeEvent->new('e3', 'name3', 'val3'));
ok($e3->getSource(), 'e3');
ok($e3->getServletContext(), 'e3');
ok($e3->getName(), 'name3');
ok($e3->getValue(), 'val3');

exit;
