#!/usr/bin/env perl

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

my (@functions, @variables);
BEGIN {
  use Const::Fast;
  use File::Temp qw(tempdir tempfile);
  use Path::Tiny qw(cwd path);
  use Test::Output;
  use Test::Warn;
  use Test2::Tools::Explain;
  use Test2::V0;
  @functions = (
    @{Const::Fast::EXPORT},
    @{Test::Files::EXPORT},
    @{Test::Output::EXPORT},
    @{Test::Warn::EXPORT},
    @{Test2::Tools::Explain::EXPORT},
    @{Test2::V0::EXPORT},
    qw(tempdir tempfile),
    qw(cwd path),
    qw(BAIL_OUT dies_ok is_deeply lives_ok new_ok require_ok use_ok),
  );
  @variables = qw($CLASS $METHOD $METHOD_REF $TEMP_DIR $TEMP_FILE);
}

use Scalar::Readonly          qw(readonly_off);
use Test::Builder::Tester     tests => @functions + @variables + 4;

use Test::Expander            -target   => 'Test::Expander',
                              -tempdir  => { CLEANUP => 1 },
                              -tempfile => { UNLINK => 1 };
use Test::Expander::Constants qw($INVALID_VALUE $UNKNOWN_OPTION);

$METHOD     //= 'import';
$METHOD_REF //= sub {};

foreach my $function (sort @functions) {
  my $title = "$CLASS->can('$function')";
  test_out("ok 1 - $title");
  can_ok($CLASS, $function);
  test_test($title);
}

foreach my $variable (sort @variables) {
  my $title = "$CLASS exports '$variable'";
  test_out("ok 1 - $title");
  ok(eval("defined($variable)"), $title);                   ## no critic (ProhibitStringyEval)
  test_test($title);
}

my $title;
my $expected;

$title    = "invalid option value of '-tempdir'";
$expected = $INVALID_VALUE =~ s/%s/.+/gr;
readonly_off($CLASS);
readonly_off($METHOD);
readonly_off($METHOD_REF);
readonly_off($TEMP_DIR);
readonly_off($TEMP_FILE);
test_out("ok 1 - $title");
like(dies { $CLASS->$METHOD(-tempdir => 1) }, qr/$expected/, $title);
test_test($title);

$title    = "invalid option value of '-tempfile'";
$expected = $INVALID_VALUE =~ s/%s/.+/gr;
readonly_off($CLASS);
readonly_off($METHOD);
readonly_off($METHOD_REF);
readonly_off($TEMP_DIR);
readonly_off($TEMP_FILE);
test_out("ok 1 - $title");
like(dies { $CLASS->$METHOD(-tempfile => 1) }, qr/$expected/, $title);
test_test($title);

$title    = 'unknown option with some value';
$expected = $UNKNOWN_OPTION =~ s/%s/.+/gr;
readonly_off($CLASS);
readonly_off($METHOD);
readonly_off($METHOD_REF);
readonly_off($TEMP_DIR);
readonly_off($TEMP_FILE);
test_out("ok 1 - $title");
like(dies { $CLASS->$METHOD(unknown => 1) }, qr/$expected/, $title);
test_test($title);

$title    = 'unknown option without value';
$expected = $UNKNOWN_OPTION =~ s/%s/.+/r =~ s/%s//r;
readonly_off($CLASS);
readonly_off($METHOD);
readonly_off($METHOD_REF);
readonly_off($TEMP_DIR);
readonly_off($TEMP_FILE);
test_out("ok 1 - $title");
like(dies { $CLASS->$METHOD('unknown') }, qr/$expected/, $title);
test_test($title);
