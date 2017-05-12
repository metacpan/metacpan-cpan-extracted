use strict;
use warnings;

use Test::More tests => 11;

require 't/FakeOhloh.pm';

my $ohloh = Fake::Ohloh->new;

$ohloh->stash( 'http://www.ohloh.net/projects/1234.xml', 'size_facts.xml' );

my @facts = $ohloh->get_size_facts(1234);

is scalar(@facts) => 73;

my $f = shift @facts;

like $f->month,       qr/^2002-04/;
is $f->code,          14599;
is $f->comments,      3500;
is $f->blanks,        3226;
is $f->comment_ratio, 0.193380849770706;
is $f->commits,       94;
is $f->man_months,    7;

is_deeply [ $f->stats ], [
    qw/ 2002-04-01T00:00:00Z
      94
      14599
      3226
      3500
      0.193380849770706
      7
      /
];

is_deeply [@$f], [
    qw/ 2002-04-01T00:00:00Z
      94
      14599
      3226
      3500
      0.193380849770706
      7
      /
];

like $f->as_xml, qr#<size_fact>.*</size_fact>$#, 'as_xml()';
