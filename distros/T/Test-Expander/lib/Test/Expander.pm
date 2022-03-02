## no critic (ProhibitStringyEval ProhibitSubroutinePrototypes RequireLocalizedPunctuationVars)
package Test::Expander;

# The versioning is conform with https://semver.org
our $VERSION = '1.0.6';                                     ## no critic (RequireUseStrict, RequireUseWarnings)

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline portable recursion);
no if ($] >= 5.018), warnings => 'experimental';

use B                qw(svref_2object);
use Const::Fast;
use File::chdir;
use File::Temp       qw(tempdir tempfile);
use Importer;
use Path::Tiny       qw(cwd path);
use Scalar::Readonly qw(readonly_on);
use Test::Files;
use Test::Output;
use Test::Warn;
use Test2::Tools::Basic;
use Test2::Tools::Explain;
use Test2::V0        ();

use Test::Expander::Constants qw(
  $ANY_EXTENSION
  $CLASS_HIERARCHY_LEVEL
  $ERROR_WAS
  $FALSE
  $EXCEPTION_PREFIX
  $INVALID_ENV_ENTRY
  $INVALID_VALUE
  $NEW_FAILED $NEW_SUCCEEDED
  $REPLACEMENT
  $REQUIRE_DESCRIPTION $REQUIRE_IMPLEMENTATION
  $SEARCH_PATTERN
  $TOP_DIR_IN_PATH
  $TRUE
  $UNKNOWN_OPTION
  $USE_DESCRIPTION $USE_IMPLEMENTATION
  $VERSION_NUMBER
);

readonly_on($VERSION);

our ($CLASS, $METHOD, $METHOD_REF, $TEMP_DIR, $TEMP_FILE);
our @EXPORT = (
  @{Const::Fast::EXPORT},
  @{Test::Files::EXPORT},
  @{Test::Output::EXPORT},
  @{Test::Warn::EXPORT},
  @{Test2::Tools::Explain::EXPORT},
  @{Test2::V0::EXPORT},
  qw(tempdir tempfile),
  qw(cwd path),
  qw($CLASS $METHOD $METHOD_REF $TEMP_DIR $TEMP_FILE),
  qw(BAIL_OUT dies_ok is_deeply lives_ok new_ok require_ok throws_ok use_ok),
);

*BAIL_OUT = \&bail_out;                                     # Explicit "sub BAIL_OUT" would be untestable

sub dies_ok (&;$) {
  my ($coderef, $description) = @_;

  eval { $coderef->() };

  return ok($@, $description);
}

sub import {
  my ($class, @exports) = @_;

  my %options;
  while (my $optionName = shift(@exports)) {
    given ($optionName) {
      when ('-tempdir') {
        my $optionValue = shift(@exports);
        die(sprintf($INVALID_VALUE, $optionName, $optionValue)) if ref($optionValue) ne 'HASH';
        $TEMP_DIR = tempdir(CLEANUP => 1, %$optionValue);
      }
      when ('-tempfile') {
        my $optionValue = shift(@exports);
        die(sprintf($INVALID_VALUE, $optionName, $optionValue)) if ref($optionValue) ne 'HASH';
        my $fileHandle;
        ($fileHandle, $TEMP_FILE) = tempfile(UNLINK => 1, %$optionValue);
      }
      when (/^-\w/) {
        $options{$optionName} = shift(@exports);
      }
      default {
        die(sprintf($UNKNOWN_OPTION, $optionName, shift(@exports) // ''));
      }
    }
  }

  my  $testFile  = path((caller(2))[1]) =~ s{^/}{}r;        ## no critic (ProhibitMagicNumbers)
  my ($testRoot) = $testFile =~ $TOP_DIR_IN_PATH;
  unless (exists($options{-target})) {
    my $testee = path($testFile)->relative($testRoot)->parent;
    $options{-target} = join('::', split(qr{/}, $testee))
      if grep { path($_)->child($testee . '.pm')->is_file } @INC;
  }

  $METHOD = path($testFile)->basename($ANY_EXTENSION);
  my $startDir = cwd();
  _setEnv($METHOD, $options{-target}, $testFile);

  Test2::V0->import(%options);

  if ($CLASS) {
    readonly_on($CLASS);
    note(q(Set $CLASS to '),      $CLASS,                                                                   q('));

    $METHOD_REF = $CLASS->can($METHOD);
    $METHOD     = undef unless($METHOD_REF);
  }
  if ($METHOD) {
    readonly_on($METHOD);
    note(q(Set $METHOD to '),     $METHOD,                                                                  q('));
  }
  if ($METHOD_REF) {
    readonly_on($METHOD_REF);
    note(q(Set $METHOD_REF to '), $METHOD_REF, ' -> &', $CLASS, '::', svref_2object($METHOD_REF)->GV->NAME, q('));
  }
  if ($TEMP_DIR) {
    readonly_on($TEMP_DIR);
    note(q(Set $TEMP_DIR to '),   $TEMP_DIR,                                                                q('));
  }
  if ($TEMP_FILE) {
    readonly_on($TEMP_FILE);
    note(q(Set $TEMP_FILE to '),  $TEMP_FILE,                                                               q('));
  }

  Importer->import_into($class, scalar(caller), ());

  return;
}

sub is_deeply ($$;$@) {
  my ($got, $expected, $title) = @_;

  return is($got, $expected, $title);
}

sub lives_ok (&;$) {
  my ($coderef, $description) = @_;

  eval { $coderef->() };

  return ok(!$@, $description);
}

sub new_ok {
  my ($class, $args) = @_;

  $args ||= [];
  my $obj = eval { $class->new(@$args) };
  ok(!$@, _newTestMessage($class));

  return $obj;
}

sub require_ok {
  my ($module) = @_;

  my $package       = caller;
  my $requireResult = eval(sprintf($REQUIRE_IMPLEMENTATION, $package, $module));
  ok($requireResult, sprintf($REQUIRE_DESCRIPTION, $module, _error()));

  return $requireResult;
}

sub throws_ok (&$;$) {
  my ($coderef, $expecting, $description) = @_;

  eval { $coderef->() };
  my $exception    = $@;
  my $expectedType = ref($expecting);

  return $expectedType eq 'Regexp' ? like  ($exception,   $expecting,   $description)
                                   : isa_ok($exception, [ $expecting ], $description);
}

sub use_ok ($;@) {
  my ($module, @imports) = @_;

  my ($package, $filename, $line) = caller(0);
  $filename =~ y/\n\r/_/;                                   # taken over from Test::More

  my $requireResult = eval(sprintf($USE_IMPLEMENTATION, $package, $module, _useImports(\@imports)));
  ok(
    $requireResult,
    sprintf($USE_DESCRIPTION, $module, _error($SEARCH_PATTERN, sprintf($REPLACEMENT, $filename, $line)))
  );

  return $requireResult;
}

sub _error {
  my ($searchString, $replacementString) = @_;

  return '' if $@ eq '';

  my $error = $ERROR_WAS . $@ =~ s/\n$//mr;
  $error =~ s/$searchString/$replacementString/m if defined($searchString);
  return $error;
}

sub _newTestMessage {
  my ($class) = @_;

  return $@ ? sprintf($NEW_FAILED, $class, _error()) : sprintf($NEW_SUCCEEDED, $class, $class);
}

sub _readEnvFile {
  my ($envFile) = @_;

  my @lines = path($envFile)->lines({ chomp => 1 });
  my %env;
  while (my ($index, $line) = each(@lines)) {
    next unless $line =~ /^ (?<name> \w+) \s* = \s* (?<value> \S .*)/x;
    $env{$+{name}} = eval($+{value});
    die(sprintf($INVALID_ENV_ENTRY, $index, $envFile, $line, $@)) if $@;
    note(q(Set environment variable '), $+{name}, q(' to '), $env{$+{name}}, q(' from file '), $envFile, q('));
  }

  return \%env;
}

sub _setEnv {
  my ($method, $class, $testFile) = @_;

  my $envFound = $FALSE;
  my $newEnv   = {};
  {
    local $CWD = $testFile =~ s{/.*}{}r;                    ## no critic (ProhibitLocalVars)
    ($envFound, $newEnv) = _setEnvHierarchically($class, $envFound, $newEnv);
  }

  my $envFile = $testFile =~ s/$ANY_EXTENSION/.env/r;

  if (path($envFile)->is_file) {
    $envFound                   = $TRUE unless $envFound;
    my $methodEnv               = _readEnvFile($envFile);
    @$newEnv{keys(%$methodEnv)} = values(%$methodEnv);
  }

  %ENV = %$newEnv if $envFound;

  return;
}

sub _setEnvHierarchically {
  my ($class, $envFound, $newEnv) = @_;

  return ($envFound, $newEnv) unless $class;

  my $classTopLevel;
  ($classTopLevel, $class) = $class =~ $CLASS_HIERARCHY_LEVEL;

  return ($FALSE, {}) unless path($classTopLevel)->is_dir;

  my $envFile = $classTopLevel . '.env';
  if (path($envFile)->is_file) {
    $envFound = $TRUE unless $envFound;
    $newEnv   = { %$newEnv, %{ _readEnvFile($envFile) } };
  }

  local $CWD = $classTopLevel;                              ## no critic (ProhibitLocalVars)
  return _setEnvHierarchically($class, $envFound, $newEnv);
}

sub _useImports {
  my ($imports) = @_;

  return @$imports == 1 && $imports->[0] =~ $VERSION_NUMBER ? ' ' . $imports->[0] : '';
}

1;
