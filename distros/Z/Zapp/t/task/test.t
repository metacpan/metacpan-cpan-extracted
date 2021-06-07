
=head1 DESCRIPTION

This tests the Zapp::Task::Test class.

=cut

use Mojo::Base -strict, -signatures;
use Test::Zapp;
use Test::More;
use Mojo::JSON qw( decode_json encode_json false true );
use Mojo::Loader qw( data_section );
use Zapp::Task::Test;

my $t = Test::Zapp->new;

subtest 'run' => sub {
    subtest 'success' => sub {
        $t->run_task(
            'Zapp::Task::Test' => {
                tests => [
                    {
                        expr => 'given',
                        op => '==',
                        value => 1,
                    },
                ],
            },
            [
                {
                    name => 'given',
                    type => 'string',
                    value => 1,
                },
            ],
            'Test: Success',
        );
        $t->task_info_is( state => 'finished', 'job finished' );
        $t->task_output_is( 'tests' => [
            {
                expr => 'given',
                op => '==',
                value => 1,
                expr_value => 1,
                pass => 1,
            },
        ] );
    };
    subtest 'failure' => sub {
        $t->run_task(
            'Zapp::Task::Test' => {
                tests => [
                    {
                        expr => 'given',
                        op => '==',
                        value => 1,
                    },
                ],
            },
            [
                {
                    name => 'given',
                    type => 'string',
                    value => 0,
                },
            ],
            'Test: Failure',
        );
        $t->task_info_is( state => 'failed', 'job failed' );
        $t->task_output_is( 'tests' => [
            {
                expr => 'given',
                op => '==',
                value => 1,
                expr_value => 0,
                pass => '',
            },
        ] );
    };
};

subtest 'output' => sub {
    my $tmpl = data_section 'Zapp::Task::Test', 'output.html.ep';

    subtest 'before run' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    tests => [
                        {
                            expr => 'given',
                            op => '==',
                            value => 1,
                        },
                    ],
                },
            },
        );
    };

    subtest 'success' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    tests => [
                        {
                            expr => 'given',
                            op => '==',
                            value => 1,
                        },
                    ],
                },
                output => {
                    tests => [
                        {
                            expr => 'given',
                            op => '==',
                            value => 1,
                            expr_value => 1,
                            pass => 1,
                        },
                    ],
                },
            },
        );
    };

    subtest 'exception' => sub {
        $t->render_ok(
            inline => $tmpl,
            task => {
                input => {
                    tests => [
                        {
                            expr => 'given',
                            op => '==',
                            value => 1,
                        },
                    ],
                },
                output => q{Can't use an undefined value as a HASH reference},
            },
        );
    };

};

done_testing;

