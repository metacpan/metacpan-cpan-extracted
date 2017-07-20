use Test2::V0 -no_srand => 1;
use Test::Script;

# replaces t/01_compile.t

imported_ok $_ for qw(
  script_compiles
  script_compiles_ok
  script_runs
  script_stdout_is
  script_stdout_isnt
  script_stdout_like
  script_stdout_unlike
  script_stderr_is
  script_stderr_isnt
  script_stderr_like
  script_stderr_unlike
);

done_testing;
