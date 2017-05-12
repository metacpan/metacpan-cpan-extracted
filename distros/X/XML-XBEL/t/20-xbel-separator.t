use strict;
use Test::More;

plan tests => 2;

use_ok("XML::XBEL::Separator");

my $separator = XML::XBEL::Separator->new();

isa_ok($separator,"XML::XBEL::Separator");

# $Id: 20-xbel-separator.t,v 1.2 2004/06/23 06:30:21 asc Exp $

