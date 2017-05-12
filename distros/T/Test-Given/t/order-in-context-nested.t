use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($lines);

describe 'Order of execution within nested contexts' => sub {
  Given lines => sub { run_spec('t/t/order-in-context-nested.t') };
  Invariant sub { contains($lines, qr/All tests successful/) };
  Then sub { contains($lines, qr/ORDER:GA,ga,WA,wa,TA,ta,IA,ia,GA,ga,GB,gb,WA,wa,WB,wb,TB,tb,IA,ia,IB,ib,GA,ga,GB,gb,GC,gc,WA,wa,WB,wb,WC,wc,TC,tc,IA,ia,IB,ib,IC,ic,DC,dc,DB,db,GA,ga,GD,gd,WA,wa,WD,wd,TD,td,IA,ia,ID,id,DD,dd,DA,da\b/) };
};
