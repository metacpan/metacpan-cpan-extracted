#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

my $CLS = 'YATT::Lite::Util::CmdLine';

require_ok($CLS);


{
  my $in;

  $in = q/--debug --file=baz --debug=qux/;
  is_deeply [$CLS->parse_opts([split " ", $in])]
    , [debug => 1, file => 'baz', debug => 'qux']
      , "parse_opts($in)";

  is_deeply $CLS->parse_opts([split " ", $in], {})
    , {file => 'baz', debug => 'qux'}
      , "parse_opts($in, {})";

  $in = q/-d --debug=foo/;
  is_deeply [$CLS->parse_opts([split " ", $in], undef, {d => 'debug'})]
    , [debug => 1, debug => 'foo']
      , "parse_opts($in, undef, {d=>debug})";

  $in = [qw/--foo --bar=baz -- --bang/];
  is_deeply [$CLS->parse_opts($in)]
    , [foo => 1, bar => 'baz']
      , "parse_opts(@$in)";

  is_deeply $in, ['--bang'], "option stopper(--)";

  # XXX: option の [:\.\-] はどうするか。公式にするか...
}

{
  my $in;
  $in = q/foo=1 bar=2 foo=3/;
  is_deeply $CLS->parse_params([split " ", $in])
    , {bar => 2, foo => 3}
      , "parse_params($in)";

  is_deeply [$CLS->parse_params([])]
    , []
      , "parse_params()";

  $in = [qw/foo=4 bar=5  other args/];
  is_deeply $CLS->parse_params($in)
    , {bar => 5, foo => 4}
      , "parse_params(@$in)";
  is_deeply $in, [qw/other args/], "Non k=v args remained";
}

sub rootname {
  my ($fn) = @_;
  $fn =~ s/\.[^\.]+$//;
  $fn;
}

SKIP: {
  skip 'pipe open is not supported on windows' if $^O =~ /^MSWin\d+/;
  my $exe = rootname(__FILE__) . ".d/t_cmd1.pl";
  my $run = sub {
    my ($cmdline) = @_;
    my @opts;
    if (my $switch = $ENV{HARNESS_PERL_SWITCHES}) {
      push @opts, split " ", $switch;
    }

    my $kidpid = open my $pipe, "-|", $^X, @opts, $exe, split " ", $cmdline
      or die "Can't fork: $!";
    chomp(my $out = <$pipe>);
    $out;
  };

  my $in = q/test FOO/;
  is_deeply $run->($in)
    , "TEST(FOO)"
      , "run($in)";
}

done_testing();
