
=head1 DESCRIPTION

This tests the Zapp::Task::Script class.

=cut

use Mojo::Base -strict, -signatures;
use Test::Zapp;
use Test::More;
use Mojo::JSON qw( decode_json encode_json false true );
use Mojo::Loader qw( data_section );
use Zapp::Task::Script;

my $t = Test::Zapp->new;

subtest 'run' => sub {
    subtest 'with shell' => sub {
        subtest 'success' => sub {
            $t->run_task(
                'Zapp::Task::Script' => {
                    script => qq{echo Hello, World\015\012},
                },
                'Test: Success',
            );
            $t->task_info_is( state => 'finished', 'job finished' );
            $t->task_output_like( pid => qr{\d+}, 'pid is saved' );
            $t->task_output_is( exit => 0, 'exit is correct' );
            $t->task_output_is( output => "Hello, World\n", 'output is correct' );
            $t->task_output_is( info => 'Script exited with value: 0', 'info is correct' );
        };

        subtest 'failure' => sub {
            $t->run_task(
                'Zapp::Task::Script' => {
                    script => qq{echo Oh no!;\015\012exit 1\015\012},
                },
                'Test: Failure',
            );
            $t->task_info_is( state => 'failed', 'job failed' );
            $t->task_output_like( pid => qr{\d+}, 'pid is saved' );
            $t->task_output_is( exit => 1, 'exit is correct' );
            $t->task_output_is( output => "Oh no!\n", 'output is correct' );
            $t->task_output_is( info => 'Script exited with value: 1', 'info is correct' );
        };
    };

    subtest 'with shebang' => sub {
        subtest 'success' => sub {
            $t->run_task(
                'Zapp::Task::Script' => {
                    script => qq{#!$^X\015\012print "Hello, World\015\012";\015\012 exit 0;\015\012},
                },
                'Test: Success',
            );
            $t->task_info_is( state => 'finished', 'job finished' );
            $t->task_output_like( pid => qr{\d+}, 'pid is saved' );
            $t->task_output_is( exit => 0, 'exit is correct' );
            $t->task_output_is( output => "Hello, World\n", 'output is correct' );
            $t->task_output_is( info => 'Script exited with value: 0', 'info is correct' );
        };

        subtest 'failure' => sub {
            $t->run_task(
                'Zapp::Task::Script' => {
                    script => qq{#!$^X\015\012warn "Oh no!\\n";\015\012 exit 1;\015\012},
                },
                'Test: Failure',
            );
            $t->task_info_is( state => 'failed', 'job failed' );
            $t->task_output_like( pid => qr{\d+}, 'pid is saved' );
            $t->task_output_is( exit => 1, 'exit is correct' );
            $t->task_output_is( output => "", 'no output on stdout' );
            $t->task_output_is( error_output => "Oh no!\n", 'error output correct' );
            $t->task_output_is( info => 'Script exited with value: 1', 'info is correct' );
        };
    };

    subtest 'environment variables' => sub {
        $t->run_task(
            'Zapp::Task::Script' => {
                vars => [
                    { name => 'WHO', value => 'World' },
                ],
                script => qq{echo Hello, \$WHO\015\012},
            },
            'Test: environment variables',
        );
        $t->task_info_is( state => 'finished', 'job finished' );
        $t->task_output_is( exit => 0, 'exit is correct' );
        $t->task_output_is( output => "Hello, World\n", 'output is correct' );
    };

};

subtest 'output view' => sub {
    my $tmpl = data_section 'Zapp::Task::Script', 'output.html.ep';

    subtest 'before run' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    script => 'echo "Foo"',
                },
            },
        );
        $t->text_like(
            'pre[data-input] code',
            qr{echo "Foo"}ms,
            "input display is correct",
        );
        $t->element_exists_not( '[data-output]', 'output not showing' );
        $t->element_exists_not( '[data-error]', 'error not showing' );
    };

    subtest 'success' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    script => 'echo "Foo"',
                },
                output => {
                    pid => 1827,
                    output => "Foo\n",
                    exit => 0,
                    info => undef,
                },
            },
        );
        $t->text_like(
            'pre[data-input] code',
            qr{echo "Foo"}ms,
            "input display is correct",
        );
        $t->text_like( '[data-output] output', qr{Foo\n}, 'output is correct' );
        $t->element_exists_not( '[data-error]', 'error not showing' );
    };

    subtest 'exception' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    script => 'DOESNTEXIST 1',
                },
                output => q{Can't call method "res" on an undefined value},
            },
        );
        $t->text_like(
            'pre[data-input] code',
            qr{DOESNTEXIST 1}ms,
            "input display is correct",
        );
        $t->element_exists_not( '[data-output]', 'output not showing' );
        $t->text_like( '[data-error]', qr{Can't call method "res"}, 'error is correct' );
    };

};

done_testing;

