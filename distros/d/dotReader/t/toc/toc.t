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

BEGIN { use_ok('dtRdr::TOC') };

my $book = bless({}, 'dtRdr::Book');

{
  my ($noise, $err) = error_catch(sub {
      eval {
        dtRdr::TOC->new();
      };
      return($@ || '');
    });

  like($@, qr/not enough/, 'not enough') or complain($@);
}
{
  my ($noise, $err) = error_catch(sub {
      eval {
        dtRdr::TOC->new({});
      };
      return($@ || '');
    });

  like($@, qr/not a dtRdr::Book/, 'not a dtRdr::Book') or complain($@);
}

my $toc = dtRdr::TOC->new($book, 'foo');
ok($toc);
isa_ok($toc, 'dtRdr::TOC');

my $range = bless([], 'dtRdr::Range');
my $c1 = $toc->create_child(1, $range,
  {title => 'something', info => {foo => 1}}
  );
ok($c1);
isa_ok($c1, 'dtRdr::TOC');

my $c2 = $toc->create_child(2, $range,
  {title => 'something else', visible => 0, info => {foo => 2}}
  );
ok($c2);
isa_ok($c2, 'dtRdr::TOC');

{
my @children = $toc->children;
ok(@children == 2, 'children');
is_deeply(\@children, [$c1,$c2], 'children check');
}
{
my @children = $toc->children;
ok(@children == 2, 'children');
is_deeply(\@children, [$c1,$c2], 'children check');
}
{
  ok($c1->visible, 'visible defaults to true');
  ok((not $c2->visible), 'visible set');
}
{
  is($c1->get_title, 'something');
  is($c2->get_title, 'something else');
  is($c1->title, 'something');
  is($c2->title, 'something else');
}
{
  is($c1->get_info('foo'), 1);
  is($c2->get_info('foo'), 2);
}
{
  $c1->set_info('foo', 'bar');
  $c2->set_info('foo', 'baz');
  is($c1->get_info('foo'), 'bar');
  is($c2->get_info('foo'), 'baz');
}
{ # check parents
  is($c1->get_parent, $toc);
  is($c2->get_parent, $toc);
  is($toc->get_parent, undef());
}
{ # check parents
  is( $c1->parent, $toc);
  is( $c2->parent, $toc);
  is($toc->parent, undef());
}

{ # check books
  is( $c1->get_book, $book);
  is( $c2->get_book, $book);
  is($toc->get_book,$book);
}
########################################################################
sub complain {
  0 and warn @_, "-- at " , join(" line ", (caller(0))[1,2]);
} # end subroutine complain definition
########################################################################
