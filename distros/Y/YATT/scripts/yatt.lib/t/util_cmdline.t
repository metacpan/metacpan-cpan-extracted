#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/..";

my $CLS = 'YATT::Util::CmdLine';

require_ok($CLS);

#========================================
# parse_opts -- posix style long options.
#

{
  is_deeply scalar $CLS->parse_opts(my $in = [qw(--foo --bar=baz -- bang)])
    , {foo => 1, bar => 'baz'}, "scalar parse_opts => hash";

  is_deeply $in, ['bang'], "parse_opts: terminate by --";
}

{
  is_deeply [$CLS->parse_opts(my $in = [qw(--foo=bar --baz --foo=hoe -- bang)])]
    , [foo => 'bar', baz => 1, foo => 'hoe'], "list parse_opts => array";

  is_deeply $in, ['bang'], "list parse_opts: terminate by --";
}

{
  my $in = [qw(--verbose --db.name=foo cmd --dry-run)];
  my $out = [];
  is scalar $CLS->parse_opts($in, $out)
    , $out, "parse_opts in out => identical out";
  is_deeply $out, [verbose => 1, 'db.name' => 'foo']
    , "list parse_opts out => array";

  is_deeply $in, [qw(cmd --dry-run)], "list parse_opts: terminate by other";

  shift @$in;

  is_deeply scalar $CLS->parse_opts($in, $out)
    , [verbose => 1, 'db.name' => 'foo', 'dry-run' => 1]
      , "list parse_opts out => array";
}

#========================================
# parse_params -- 'Make' style parameter lists.
#

{
  is_deeply scalar $CLS->parse_params(my $in = [qw(foo=bar baz=bang hoe)])
    , {foo => 'bar', baz => 'bang'}
      , 'scalar parse_params => hash';
  is_deeply $in
    , ['hoe']
      , 'parse_params only eats key=value';
  is_deeply [$CLS->parse_params($in)]
    , []
      , "empty list parse_params => empty";
  is_deeply $CLS->parse_params($in, {})
    , {}
      , "empty list parse_params {} => empty hash";
}
