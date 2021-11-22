#!/usr/bin/env perl
## no critic (RequireLocalizedPunctuationVars)

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use File::chdir;

use Test::Expander -tempdir => {}, -srand => time;

$METHOD     //= '_setEnv';
$METHOD_REF //= $CLASS->can($METHOD);
can_ok($CLASS, $METHOD);

ok(-d $TEMP_DIR, "temporary directory '$TEMP_DIR' created");

my $classPath = $CLASS =~ s{::}{/}gr;
my $testPath  = path($TEMP_DIR)->child('t');
$testPath->child($classPath)->mkpath;

{
  local $CWD   = $testPath->parent->stringify;              ## no critic (ProhibitLocalVars)

  my $testFile = path('t')->child($classPath)->child($METHOD . '.t')->stringify;
  my $envFile  = path('t')->child($classPath)->child($METHOD . '.env');

  is(Test2::Plugin::SRand->from, 'import arg', "random seed is supplied as 'time'");

  subtest 'env variable filled from a variable' => sub {
    our $var  = 'abc';
    my $name  = 'ABC';
    my $value = '$' . __PACKAGE__ . '::var';
    $envFile->spew("$name = $value\nJust a comment line");
    %ENV = (xxx => 'yyy');

    ok(lives { $METHOD_REF->($METHOD, $CLASS, $testFile) }, 'successfully executed');
    is(\%ENV, { $name => lc($name) },                       "'%ENV' has the expected content");
  };

  subtest 'env variable filled by a self-implemented sub' => sub {
    my $name  = 'ABC';
    my $value = __PACKAGE__ . "::testEnv(lc('$name'))";
    $envFile->spew("$name = $value");
    %ENV = (xxx => 'yyy');

    ok(lives { $METHOD_REF->($METHOD, $CLASS, $testFile) }, 'successfully executed');
    is(\%ENV, { $name => lc($name) },                       "'%ENV' has the expected content");
  };

  subtest "env variable filled by a 'File::Temp::tempdir'" => sub {
    my $name  = 'ABC';
    my $value = 'File::Temp::tempdir';
    $envFile->spew("$name = $value");
    %ENV = (xxx => 'yyy');

    ok(lives { $METHOD_REF->($METHOD, $CLASS, $testFile) }, 'successfully executed');
    is([ keys(%ENV) ], [ $name ],                           "'%ENV' has the expected keys");
    ok(-d $ENV{$name},                                      'temporary directory exists');
  };

  subtest 'env file does not exist' => sub {
    $envFile->remove;
    %ENV = (xxx => 'yyy');

    ok(lives { $METHOD_REF->($METHOD, $CLASS, $testFile) }, 'successfully executed');
    is(\%ENV, { xxx => 'yyy' },                             "'%ENV' remained unchanged");
  };

  subtest 'directory structure does not correspond to class hierarchy' => sub {
    $envFile->remove;
    %ENV = (xxx => 'yyy');

    ok(lives { $METHOD_REF->($METHOD, 'ABC::' . $CLASS, $testFile) }, 'successfully executed');
    is(\%ENV, { xxx => 'yyy' },                                       "'%ENV' remained unchanged");
  };

  subtest 'env files exist on multiple levels' => sub {
    path($envFile->parent         . '.env')->spew("A = '1'\nB = '2'");
    path($envFile->parent->parent . '.env')->spew("C = '0'");
    $envFile->spew("C = '3'");
    %ENV = (xxx => 'yyy');

    local $CWD = $TEMP_DIR;                                 ## no critic (ProhibitLocalVars)
    ok(lives { $METHOD_REF->($METHOD, $CLASS, $testFile) }, 'successfully executed');
    is(\%ENV, { A => '1', B => '2', C => '3' },             "'%ENV' has the expected content");
  };

  subtest 'env file invalid' => sub {
    my $name  = 'ABC';
    my $value = 'abc->';
    $envFile->spew("$name = $value");

    like(dies { $METHOD_REF->($METHOD, $CLASS, $testFile) }, qr/syntax error/, 'expected exception raised');
  };
}

done_testing();

sub testEnv { return $_[0] }                                ## no critic (RequireArgUnpacking)
