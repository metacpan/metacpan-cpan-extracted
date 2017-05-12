# -*- Mode: Perl; indent-tabs-mode: nil; -*-

use strict;
use warnings;

use Test;

BEGIN { plan tests => 8 }

use Servlet::Http::HttpSessionEvent ();
use Servlet::Http::HttpSessionBindingEvent ();

ok(my $e1 = Servlet::Http::HttpSessionEvent->new('e1'));
ok($e1->getSource(), 'e1');
ok($e1->getSession(), 'e1');

ok(my $e2 = Servlet::Http::HttpSessionBindingEvent->new('e2', 'name2',
                                                        'val2'));
ok($e2->getSource(), 'e2');
ok($e2->getSession(), 'e2');
ok($e2->getName(), 'name2');
ok($e2->getValue(), 'val2');

exit;
