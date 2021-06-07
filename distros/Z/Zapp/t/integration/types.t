
=head1 DESCRIPTION

This tests all types can be used in creating plans, running plans, and
viewing runs. This tests all base types as created in Zapp by default.

=cut

use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Zapp;
use Zapp::Type::SelectBox;
use Mojo::File qw( tempdir tempfile );
use Mojo::JSON qw( encode_json decode_json );
use Zapp::Util qw( get_path_from_data get_path_from_schema );

my $t = Test::Zapp->new( 'Zapp' );

# Dir to store files for Zapp::Type::File
my $temp = tempdir();
my $uploads_dir = $temp->child( 'public' )->make_path;
$t->app->home( $temp );
my $file_value = $uploads_dir->child( 'file.txt' )->spurt( 'File content' )->to_rel( $uploads_dir );

# Create a plan with input of every type
my %plan_data = (
    label => 'Test Plan',
    inputs => [
        {
            name => 'boolean',
            type => 'boolean',
            config => encode_json( 1 ),
        },
        {
            name => 'selectbox',
            type => 'selectbox',
            config => encode_json(
                {
                    options => [
                        { label => 'Scruffy', value => 'Scruffy' },
                        { label => 'Katrina', value => 'Katrina' },
                        { label => 'Xanthor', value => 'Xanthor' },
                    ],
                    selected_index => 0,
                },
            ),
        },
        {
            name => 'file',
            type => 'file',
            config => undef,
        },
        {
            name => 'integer',
            type => 'integer',
            config => encode_json( 56 ),
        },
        {
            name => 'number',
            type => 'number',
            config => encode_json( 1.234 ),
        },
        {
            name => 'string',
            type => 'string',
            config => encode_json( 'string' ),
        },
    ],
);

subtest 'plan input' => sub {
    subtest 'plan edit form' => sub {
        my $plan = $t->app->create_plan({%plan_data});
        $t->get_ok( '/plan/' . $plan->{plan_id} . '/edit' )->status_is( 200 );

        subtest 'input 0 - boolean' => sub {
            $t->element_exists( 'form [name="input[0].config"]' )
              ->attr_is( 'form [name="input[0].config"]', type => 'text' )
              ->attr_is( 'form [name="input[0].config"]', value => 1 )
              ->attr_is( 'form [name="input[0].type"]', value => 'boolean' )
              ->attr_is( 'form [name="input[0].name"]', value => 'boolean' )
        };

        subtest 'input 1 - selectbox' => sub {
            $t->element_exists( 'form [name="input[1].config.options[0].label"]' )
              ->attr_is( 'form [name="input[1].type"]', value => 'selectbox' )
              ->attr_is( 'form [name="input[1].name"]', value => 'selectbox' )
        };

        subtest 'input 2 - file' => sub {
            $t->element_exists( 'form [name="input[2].type"]' )
              ->attr_is( 'form [name="input[2].type"]', value => 'file' )
              ->attr_is( 'form [name="input[2].name"]', value => 'file' )
        };

        subtest 'input 3 - number' => sub {
            $t->element_exists( 'form [name="input[3].config"]' )
              ->attr_is( 'form [name="input[3].config"]', type => 'text' )
              ->attr_is( 'form [name="input[3].config"]', value => '56' )
              ->attr_is( 'form [name="input[3].type"]', value => 'integer' )
              ->attr_is( 'form [name="input[3].name"]', value => 'integer' )
        };

        subtest 'input 4 - number' => sub {
            $t->element_exists( 'form [name="input[4].config"]' )
              ->attr_is( 'form [name="input[4].config"]', type => 'text' )
              ->attr_is( 'form [name="input[4].config"]', value => '1.234' )
              ->attr_is( 'form [name="input[4].type"]', value => 'number' )
              ->attr_is( 'form [name="input[4].name"]', value => 'number' )
        };

        subtest 'input 5 - string' => sub {
            $t->element_exists( 'form [name="input[5].config"]' )
              ->attr_is( 'form [name="input[5].config"]', type => 'text' )
              ->attr_is( 'form [name="input[5].config"]', value => 'string' )
              ->attr_is( 'form [name="input[5].type"]', value => 'string' )
              ->attr_is( 'form [name="input[5].name"]', value => 'string' )
        };
    };

    subtest 'save plan' => sub {
        my $plan = $t->app->create_plan({%plan_data});
        $t->post_ok( '/plan/' . $plan->{plan_id} . '/edit', form => {
            %plan_data{qw( label )},

            'input[0].name' => 'boolean',
            'input[0].type' => 'boolean',
            'input[0].config' => 0,

            'input[1].name' => 'selectbox',
            'input[1].type' => 'selectbox',
            'input[1].config.options[0].label' => 'Scruffy',
            'input[1].config.options[0].value' => 'Scruffy',
            'input[1].config.options[1].label' => 'Katrina',
            'input[1].config.options[1].value' => 'Katrina',
            'input[1].config.options[2].label' => 'Xanthor',
            'input[1].config.options[2].value' => 'Xanthor',
            'input[1].config.selected_index' => 1,

            'input[2].name' => 'file',
            'input[2].type' => 'file',

            'input[3].name' => 'integer',
            'input[3].type' => 'integer',
            'input[3].config' => 67,

            'input[4].name' => 'number',
            'input[4].type' => 'number',
            'input[4].config' => 2.345,

            'input[5].name' => 'string',
            'input[5].type' => 'string',
            'input[5].config' => 'new string',

        } )->status_is( 302 );

        my @inputs = $t->app->yancy->list( zapp_plan_inputs => { plan_id => $plan->{plan_id} }, { order_by => 'rank' } );

        subtest 'input 0 - boolean' => sub {
            is decode_json( $inputs[0]{config} ), 0;
        };

        subtest 'input 1 - selectbox' => sub {
            is_deeply decode_json( $inputs[1]{config} ),
                {
                    options => [
                        { label => 'Scruffy', value => 'Scruffy' },
                        { label => 'Katrina', value => 'Katrina' },
                        { label => 'Xanthor', value => 'Xanthor' },
                    ],
                    selected_index => 1,
                },
                'config is correct';
        };

        subtest 'input 2 - file' => sub {
            is_deeply decode_json( $inputs[2]{config} ), {}, 'no config';
        };

        subtest 'input 3 - integer' => sub {
            is decode_json( $inputs[3]{config} ), 67;
        };

        subtest 'input 4 - number' => sub {
            is decode_json( $inputs[4]{config} ), 2.345;
        };

        subtest 'input 5 - string' => sub {
            is decode_json( $inputs[5]{config} ), 'new string';
        };
    };

    subtest 'run form' => sub {
        my $plan = $t->app->create_plan({%plan_data});
        $t->get_ok( '/plan/' . $plan->{plan_id} . '/run' )->status_is( 200 );

        subtest 'input 0 - boolean' => sub {
            $t->element_exists( 'form [name="input[0].value"]' )
              ->attr_is( 'form [name="input[0].value"]', type => 'text' )
              ->attr_is( 'form [name="input[0].value"]', value => 1 )
              ->attr_is( 'form [name="input[0].type"]', value => 'boolean' )
              ->attr_is( 'form [name="input[0].name"]', value => 'boolean' )
        };

        subtest 'input 1 - selectbox' => sub {
            $t->element_exists( 'form [name="input[1].value"]' )
              ->element_exists( 'form select[name="input[1].value"]', 'tag is <select>' )
              ->attr_is( 'form [name="input[1].value"] [selected]', value => 'Scruffy' )
              ->attr_is( 'form [name="input[1].type"]', value => 'selectbox' )
              ->attr_is( 'form [name="input[1].name"]', value => 'selectbox' )
        };

        subtest 'input 2 - file' => sub {
            $t->element_exists( 'form [name="input[2].value"]' )
              ->attr_is( 'form [name="input[2].value"]', type => 'file' )
              ->attr_is( 'form [name="input[2].type"]', value => 'file' )
              ->attr_is( 'form [name="input[2].name"]', value => 'file' )
        };

        subtest 'input 3 - number' => sub {
            $t->element_exists( 'form [name="input[3].value"]' )
              ->attr_is( 'form [name="input[3].value"]', type => 'text' )
              ->attr_is( 'form [name="input[3].value"]', value => '56' )
              ->attr_is( 'form [name="input[3].type"]', value => 'integer' )
              ->attr_is( 'form [name="input[3].name"]', value => 'integer' )
        };

        subtest 'input 4 - number' => sub {
            $t->element_exists( 'form [name="input[4].value"]' )
              ->attr_is( 'form [name="input[4].value"]', type => 'text' )
              ->attr_is( 'form [name="input[4].value"]', value => '1.234' )
              ->attr_is( 'form [name="input[4].type"]', value => 'number' )
              ->attr_is( 'form [name="input[4].name"]', value => 'number' )
        };

        subtest 'input 5 - string' => sub {
            $t->element_exists( 'form [name="input[5].value"]' )
              ->attr_is( 'form [name="input[5].value"]', type => 'text' )
              ->attr_is( 'form [name="input[5].value"]', value => 'string' )
              ->attr_is( 'form [name="input[5].type"]', value => 'string' )
              ->attr_is( 'form [name="input[5].name"]', value => 'string' )
        };
    };

    subtest 'save run' => sub {
        my $plan = $t->app->create_plan({%plan_data});
        $t->post_ok( '/run', form => {
            plan_id => $plan->{plan_id},
            'input[0].name' => 'boolean',
            'input[0].type' => 'boolean',
            'input[0].value' => 1,

            'input[1].name' => 'selectbox',
            'input[1].type' => 'selectbox',
            'input[1].config' => encode_json({
                options => [
                    {
                        label => 'Scruffy',
                        value => 'Scruffy',
                    },
                    {
                        label => 'Katrina',
                        value => 'Katrina',
                    },
                    {
                        label => 'Xanthor',
                        value => 'Xanthor',
                    },
                ],
                selected_index => 0,
            }),
            'input[1].value' => 'Xanthor',

            'input[2].name' => 'file',
            'input[2].type' => 'file',
            'input[2].value' => {
                content => 'Run File',
                filename => 'file.txt',
            },

            'input[3].name' => 'integer',
            'input[3].type' => 'integer',
            'input[3].value' => 89,

            'input[4].name' => 'number',
            'input[4].type' => 'number',
            'input[4].value' => 3.456,

            'input[5].name' => 'string',
            'input[5].type' => 'string',
            'input[5].value' => 'run string',
        } )->status_is( 302 );

        my ( $run_id ) = $t->tx->res->headers->location =~ m{/run/(\d+)};

        my $run = $t->app->yancy->get( zapp_runs => $run_id );
        my $input = decode_json( $run->{input} );

        subtest 'input 0 - boolean' => sub {
            is $input->[0]{value}, 1;
        };

        subtest 'input 1 - selectbox' => sub {
            is $input->[1]{value}, 'Xanthor';
        };

        subtest 'input 2 - file' => sub {
            like $input->[2]{value}, qr{Pw/Qd/XOBNWd9H5Zc5lIXvadI_0pk/file\.txt};
            my $file = $t->app->home->child( 'public', $input->[2]{value} );
            ok -e $file, 'file exists';
            is $file->slurp, 'Run File', 'file content correct';
        };

        subtest 'input 3 - integer' => sub {
            is $input->[3]{value}, 89;
        };

        subtest 'input 4 - number' => sub {
            is $input->[4]{value}, 3.456;
        };

        subtest 'input 5 - string' => sub {
            is $input->[5]{value}, 'run string';
        };
    };
};

subtest 'task input' => sub {
    my $file = $uploads_dir->child( 'zapp' )->spurt( 'File content' );

    # XXX: Test tasks that output certain types
    my $plan = $t->app->create_plan({
        label => 'Task Input Plan',
        tasks => [
            {
                label => 'string: input',
                name => 'string_input',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'string', value => '=string' },
                    ],
                    script => 'echo -n $string',
                }),
            },
            {
                label => 'integer: input',
                name => 'integer_input',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'int', value => '=integer' },
                    ],
                    script => 'echo -n $int',
                }),
            },
            {
                label => 'number: input',
                name => 'number_input',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'num', value => '=number' },
                    ],
                    script => 'echo -n $num',
                }),
            },
            {
                label => 'boolean: input',
                name => 'boolean_input',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'bool', value => '=boolean' },
                    ],
                    script => 'echo -n $bool',
                }),
            },
            {
                label => 'file: input',
                name => 'file_input',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'file', value => '=file' },
                    ],
                    script => 'cat $file',
                }),
            },
            {
                label => 'selectbox: input',
                name => 'selectbox_input',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'val', value => '=selectbox' },
                    ],
                    script => 'echo -n $val',
                }),
            },
        ],
        inputs => [
            {
                name => 'string',
                type => 'string',
                value => 'String input',
            },
            {
                name => 'integer',
                type => 'integer',
                value => 1234,
            },
            {
                name => 'number',
                type => 'number',
                value => 5.678,
            },
            {
                name => 'boolean',
                type => 'boolean',
                value => 1,
            },
            {
                name => 'file',
                type => 'file',
                value => $file->to_rel( $uploads_dir )."",
            },
            {
                name => 'selectbox',
                type => 'selectbox',
                value => 'Scruffy',
                config => encode_json({
                    options => [
                        { label => 'Scruffy', value => 'Scruffy' },
                        { label => 'Katrina', value => 'Katrina' },
                        { label => 'Xanthor', value => 'Xanthor' },
                    ],
                    selected_index => 0,
                }),
            },
        ],
    });

    # Run each task in the plan and validate result input/output
    my $input = {
        string => 'String input',
        integer => 1234,
        number => 5.678,
        boolean => 1,
        file => $file->to_rel( $uploads_dir ),
        selectbox => 'Scruffy',
    };
    my $run = $t->app->enqueue_plan( $plan->{plan_id}, $input );
    $t->run_queue;

    subtest 'string: input' => sub {
        my $job = $t->app->minion->job( $run->{tasks}[0]{job_id} );
        my $result = $job->info->{result};
        is $result->{output}, $input->{string}, 'string input correct';
    };
    subtest 'integer: input' => sub {
        my $job = $t->app->minion->job( $run->{tasks}[1]{job_id} );
        my $result = $job->info->{result};
        is $result->{output}, $input->{integer}, 'integer input correct';
    };
    subtest 'number: input' => sub {
        my $job = $t->app->minion->job( $run->{tasks}[2]{job_id} );
        my $result = $job->info->{result};
        is $result->{output}, $input->{number}, 'number input correct';
    };
    subtest 'boolean: input' => sub {
        my $job = $t->app->minion->job( $run->{tasks}[3]{job_id} );
        my $result = $job->info->{result};
        is $result->{output}, $input->{boolean}, 'boolean input correct';
    };
    subtest 'file: input' => sub {
        my $job = $t->app->minion->job( $run->{tasks}[4]{job_id} );
        my $result = $job->info->{result};
        my $path = $t->app->home->child( 'public', $input->{file} );
        is $result->{output}, $path->slurp, 'file input correct';
    };
    subtest 'selectbox: input' => sub {
        my $job = $t->app->minion->job( $run->{tasks}[5]{job_id} );
        my $result = $job->info->{result};
        is $result->{output}, $input->{selectbox}, 'selectbox input correct';
    };
};

done_testing;
