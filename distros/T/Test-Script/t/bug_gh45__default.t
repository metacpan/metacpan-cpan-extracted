use Test2::V0 -no_srand => 1;
use Test::Script;

imported_ok(qw(
            script_compiles
            script_compiles_ok
            script_fails
            script_runs
            script_stdout_is
            script_stdout_isnt
            script_stdout_like
            script_stdout_unlike
            script_stderr_is
            script_stderr_isnt
            script_stderr_like
            script_stderr_unlike
            program_fails
            program_runs
            program_stdout_is
            program_stdout_isnt
            program_stdout_like
            program_stdout_unlike
            program_stderr_is
            program_stderr_isnt
            program_stderr_like
            program_stderr_unlike
        ),
);

done_testing;
