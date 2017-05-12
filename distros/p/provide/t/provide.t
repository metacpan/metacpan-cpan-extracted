#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 14;

use lib grep { -d } qw(../lib ./lib ./t/lib);
use Test::Easy qw(deep_ok);

# Here's a basic test of the 'ge' condition. A little extra attention is paid to @EXPORT and the behaviors that
# exporty1:: is able to provide.
{
  use strict;
  use warnings;
  package exporty1;

  use provide (
    if => ge => '1.000000' => 'exporty1::pass',
    else                   => 'exporty1::fail',
  );
}

ok( exporty1->isa('Exporter'), 'exporty1 isa Exporter' );
deep_ok( \@exporty1::pass::EXPORT, [qw(moonset craving)], 'we know what exporty1::pass exports' );
deep_ok( \@exporty1::EXPORT, \@exporty1::pass::EXPORT, 'exporty1 exports the same thing as exporty1::pass' );
is( exporty1::pass->moonset, 'exporty1::pass::moonset', 'we know what moonset looks like' );
is( exporty1->moonset, exporty1::pass->moonset, 'moonset is moonset' );


# lt
{
  use strict;
  use warnings;
  package exporty2;

  use provide (
    if => lt => '7.000000' => 'exporty2::pass',  # this test is not Perl 7 compliant.
    else                   => 'exporty2::fail',
  );
}

deep_ok( \@exporty2::EXPORT, \@exporty2::pass::EXPORT, 'exporty2 exports the same thing as exporty2::pass' );
like( exporty2::pass->cheese, qr/blue cheese.*trash/, "blue cheese smells like trash (but that's not so bad)" );
is( exporty2->cheese, exporty2::pass->cheese, 'cheese is cheese' );

# le
{
  use strict;
  use warnings;
  package exporty::le;
  use provide (
    if => le => $] => 'exporty2::pass',
    else           => 'exporty2::fail',
  );
}
deep_ok( \@exporty::le::EXPORT, \@exporty2::pass::EXPORT, 'le works' );

# eq
{
  use strict;
  use warnings;
  package exporty::eq;
  use provide (
    if => eq => $] => 'exporty2::pass',
    else           => 'exporty2::fail',
  );
}
deep_ok( \@exporty::eq::EXPORT, \@exporty2::pass::EXPORT, 'eq works' );

# ne
{
  use strict;
  use warnings;
  package exporty::ne;
  use provide (
    if => ne => $] => 'exporty2::fail',
    else           => 'exporty2::pass',
  );
}
deep_ok( \@exporty::ne::EXPORT, \@exporty2::pass::EXPORT, 'ne works' );

# ge
{
  use strict;
  use warnings;
  package exporty::ge;
  use provide (
    if => ge => $] => 'exporty2::pass',
    else           => 'exporty2::fail',
  );
}
deep_ok( \@exporty::ge::EXPORT, \@exporty2::pass::EXPORT, 'ge works' );

# gt
{
  use strict;
  use warnings;
  package exporty::gt;
  use provide (
    if => gt => $] => 'exporty2::fail',
    else           => 'exporty2::pass',
  );
}
deep_ok( \@exporty::gt::EXPORT, \@exporty2::pass::EXPORT, 'gt works' );


# elsif
{
  use strict;
  use warnings;
  package exporty::elsif;
  use provide (
    if    => gt => $] => 'exporty2::fail',  # clearly $] is not > $]
    elsif => eq => 0  => 'exporty2::fail',  # and clearly $] is not == 0
    elsif => ne => $] => 'exporty2::fail',  # and clearly $] is not != $]
    elsif => ge => $] => 'exporty2::pass',  # clearly $] is >= $]
    else              => 'exporty2::fail',  # so we never hit here
  );
}
deep_ok( \@exporty::elsif::EXPORT, \@exporty2::pass::EXPORT, 'elsif works' );
