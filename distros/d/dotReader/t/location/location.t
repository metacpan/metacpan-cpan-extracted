#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta

use lib 'inc';
use dtRdrTestUtil qw(
  error_catch
  );

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Location') };

{
  my ($noise, $err) = error_catch(sub {
      eval {
        dtRdr::Location->new();
      };
      return($@ || '');
    });

  like($@, qr/not enough/, 'not enough') or complain($@);
}
{
  my ($noise, $err) = error_catch(sub {
      eval {
        dtRdr::Location->new({}, 7);
      };
      return($@ || '');
    });

  like($@, qr/not a dtRdr::TOC/, 'not a dtRdr::TOC') or complain($@);
}

{
  my $loc = dtRdr::Location->new(bless({}, 'dtRdr::Book'), 7);
  ok($loc);
  isa_ok($loc, 'dtRdr::Location');
  ok($loc->offset == 7, 'offset');
  isa_ok($loc->node, 'dtRdr::Book');
}

sub complain {
  0 and warn @_, "-- at " , join(" line ", (caller(0))[1,2]);
} # end subroutine complain definition
########################################################################
