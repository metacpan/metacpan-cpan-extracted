# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 05-expr.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/05-expr.t $
#
use strict;
use warnings;
use Test::More;

our @CONVS = (
	      [1, "cm", 10,   "mm"],
	      [1, 'in', 2.54, 'cm'],
	      [1, 'in', 25.4, 'mm'],
	     );
our @EXPRS = (
	      ["10cm - 1cm", "9cm"],
	      ["10cm - 1mm", "9.9cm"],
	      ["1in / 10cm", "0.254in"],
	      ["#3bbfce - #111111", "#2aaebd"],
	     );

plan tests => 7 + scalar @EXPRS;

my $pkg = 'Text::Sass::Expr';
use_ok($pkg);

{
  is_deeply($pkg->units('10px'), [10, 'px'], '10px units');
}

{
  is_deeply($pkg->units('2'), [2, ''], '2 units');
}

{
  is_deeply($pkg->units('#efefff'), [[239,239,255], '#'], '#efefff units');
}

for my $set (@CONVS) {
  is($pkg->convert($set->[0], $set->[1], $set->[3]), $set->[2], "$set->[0]$set->[1] = $set->[2]$set->[3]");
}

for my $set (@EXPRS) {
  my @bits = split /\s/smx, $set->[0];
  is($pkg->expr(@bits), $set->[1], "$set->[0] = $set->[1]");
}
