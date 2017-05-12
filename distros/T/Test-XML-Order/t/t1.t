# @(#) $Id$
use strict;
use warnings;

use Test::More tests => 1;
use Test::XML::Order;

my $data = <<DATA;
<div>
 <span><b><i>one</i></b><b>.</b></span>
 <span><b><i>two</i></b><b>.</b></span>
</div>
DATA

my $cmp = <<DATA;
<div>
 <span><b><i>one</i></b><b>.</b></span>
 <span><b><i>two</i></b><b>.</b></span>
</div>
DATA

is_xml_in_order($data, $cmp, 't1');

