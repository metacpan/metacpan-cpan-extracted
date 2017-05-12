#! /usr/bin/perl -wT

use strict; use warnings;
use Test::More tests => 15;
use Text::Glob::DWIW qw':all';

is scalar(@Text::Glob::DWIW::EXPORT_OK),30,"sub count";
can_ok('Text::Glob::DWIW',@Text::Glob::DWIW::EXPORT_OK);

my $o1=tg_expand '';
isa_ok($o1,'Text::Glob::DWIW::Result');
is(ref $o1,'Text::Glob::DWIW::Result');
can_ok($o1,qw'opts elems elem tree chunks expand grep format capture as_re');
my $o2=$o1->_new_expand(scalar($o1->can('opts')?$o1->opts:{}),'');
  # $o2//=$o1->_new_expand({},'');
isa_ok($o2,'Text::Glob::DWIW::Result');
can_ok($o2,qw'opts elems elem tree chunks expand grep format capture as_re');
my $op1=$o1->opts; $o1->opts(star => !$op1->{star});
is !!$o1->opts->{star}, !$o2->opts->{star}, "opts (set+)get";
# but actually the setter makes no sense # needs rewrite (but ->format is fine)
# for v0.01

is prototype(\&tglob),'_;@','proto: tglob()';
is prototype('tglob'),'_;@','proto: "tglob"';
is prototype(\&tg),'_;@','proto: tg()';
is prototype('tg'),'_;@','proto: "tg"';
is prototype(\&tg_match),'$@','proto: tg_match()';
is prototype(\&tg_grep),'$@','proto: tg_grep()';
is prototype(\&tg_glob),'$@','proto: tg_glob()';

done_testing;