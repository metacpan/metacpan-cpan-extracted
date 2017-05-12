#!perl
use strict;
use warnings;
use Test::More tests => 8;

BEGIN { use_ok('Test::InDomain'); }

my $dom = Int(-min => 3);

in_domain     5, $dom, "foo";
not_in_domain 2, $dom, "small";

$dom = List(Int, List, String);
in_domain [1, [], 123], $dom, "list";

$dom = List(-all => Int(-min => 0), -size => [5, 10]);
in_domain [ 1 .. 8 ], $dom, "5 to 10 positive integers";


my $expr_domain;
$expr_domain = One_of(Num, Struct(operator => String(qr(^[-+*/]$)),
                                  left     => sub {$expr_domain},
                                  right    => sub {$expr_domain}));
in_domain 123, $expr_domain, "binary expression tree/num";

in_domain {operator => '+',
           left => 123,
           right => {operator => '*',
                     left     => 456,
                     right    => 789 },
           }, $expr_domain, "binary expression tree/tree";

use IO::Handle;
in_domain {data => {}, printer => IO::Handle->new},
          Struct(data => Defined, printer => Obj(-can => 'print')),
          "struct with data hash and printer object";
