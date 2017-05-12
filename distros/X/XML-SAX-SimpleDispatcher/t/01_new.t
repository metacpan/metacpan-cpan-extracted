use strict;
use Test::More tests => 2;

BEGIN { use_ok 'XML::SAX::SimpleDispatcher' }

my $x = XML::SAX::SimpleDispatcher->new;
ok $x, 'created an new instance';

