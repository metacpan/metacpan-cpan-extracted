
=head1 DESCRIPTION

This tests the Zapp::Type::SelectBox class

=cut

use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Zapp;
use Mojo::DOM;
use Zapp::Type::SelectBox;

my $t = Test::Zapp->new( 'Zapp' );
my $type = Zapp::Type::SelectBox->new(
    default_options => [
        {
            label => 'foo',
            value => 'foo',
        },
        {
            label => 'bar',
            value => 'bar',
        },
        {
            label => 'baz',
            value => 'baz',
        },
    ]
);
$t->app->zapp->add_type( selectbox => $type );

subtest 'config_field' => sub {
    subtest 'blank' => sub {
        my $type = Zapp::Type::SelectBox->new;
        my $config_value = undef;
        my $c = $t->app->build_controller;
        my $html = $type->config_field( $c, $config_value );
        my $dom = Mojo::DOM->new( $html );
        ok $dom->at( '[name="config.options[0].label"]' ), 'blank label field exists';
        ok $dom->at( '[name="config.options[0].value"]' ), 'blank value field exists';
        ok $dom->at( '[type=radio][name="config.selected_index"]' ), 'selected index radio exists';
    };

    subtest 'with default options' => sub {
        my $config_value = undef;
        my $c = $t->app->build_controller;
        my $html = $type->config_field( $c, $config_value );
        my $dom = Mojo::DOM->new( $html );
        my @rows = $dom->find( ':not(template) > [data-zapp-array-row]' )->each;
        ok $rows[0]->at( '[name="config.options[0].label"]' ), 'first label field exists';
        is $rows[0]->at( '[name="config.options[0].label"]' )->attr( 'value' ),
            'foo',
            'first label field value is correct';
        ok $rows[0]->at( '[name="config.options[0].value"]' ), 'first value field exists';
        is $rows[0]->at( '[name="config.options[0].value"]' )->attr( 'value' ),
            'foo',
            'first value field value is correct';
        ok $rows[0]->at( '[type=radio][name="config.selected_index"]' ), 'selected index radio exists';
        is $rows[0]->at( '[type=radio][name="config.selected_index"]' )->attr( 'value' ),
            '0',
            'first selected index radio value is correct';
        ok $rows[0]->at( '[type=radio][name="config.selected_index"]' )->attr( 'checked' ),
            'first selected index radio is checked';
        ok $rows[1]->at( '[name="config.options[1].label"]' ), 'second label field exists';
        is $rows[1]->at( '[name="config.options[1].label"]' )->attr( 'value' ),
            'bar',
            'second label field value is correct';
        ok $rows[1]->at( '[name="config.options[1].value"]' ), 'second value field exists';
        is $rows[1]->at( '[name="config.options[1].value"]' )->attr( 'value' ),
            'bar',
            'second value field value is correct';
        ok $rows[1]->at( '[type=radio][name="config.selected_index"]' ), 'selected index radio exists';
        is $rows[1]->at( '[type=radio][name="config.selected_index"]' )->attr( 'value' ),
            '1',
            'second selected index radio value is correct';
        ok !$rows[1]->at( '[type=radio][name="config.selected_index"]' )->attr( 'checked' ),
            'second selected index radio is not checked';
        ok $rows[2]->at( '[name="config.options[2].label"]' ), 'third label field exists';
        is $rows[2]->at( '[name="config.options[2].label"]' )->attr( 'value' ),
            'baz',
            'third label field value is correct';
        ok $rows[2]->at( '[name="config.options[2].value"]' ), 'third value field exists';
        is $rows[2]->at( '[name="config.options[2].value"]' )->attr( 'value' ),
            'baz',
            'third value field value is correct';
        ok $rows[2]->at( '[type=radio][name="config.selected_index"]' ), 'selected index radio exists';
        is $rows[2]->at( '[type=radio][name="config.selected_index"]' )->attr( 'value' ),
            '2',
            'third selected index radio value is correct';
        ok !$rows[2]->at( '[type=radio][name="config.selected_index"]' )->attr( 'checked' ),
            'third selected index radio is not checked';
    };

    subtest 'with config options' => sub {
        my $config_value = {
            options => [
                { label => 'foo', value => 'foo' },
                { label => 'BAR', value => 'BAR' },
                { label => 'Baz', value => 'baz' },
            ],
            selected_index => 2,
        };
        my $c = $t->app->build_controller;
        my $html = $type->config_field( $c, $config_value );
        my $dom = Mojo::DOM->new( $html );
        my @rows = $dom->find( ':not(template) > [data-zapp-array-row]' )->each;
        ok $rows[0]->at( '[name="config.options[0].label"]' ), 'first label field exists';
        is $rows[0]->at( '[name="config.options[0].label"]' )->attr( 'value' ),
            'foo',
            'first label field value is correct';
        ok $rows[0]->at( '[name="config.options[0].value"]' ), 'first value field exists';
        is $rows[0]->at( '[name="config.options[0].value"]' )->attr( 'value' ),
            'foo',
            'first value field value is correct';
        ok $rows[0]->at( '[type=radio][name="config.selected_index"]' ), 'selected index radio exists';
        is $rows[0]->at( '[type=radio][name="config.selected_index"]' )->attr( 'value' ),
            '0',
            'first selected index radio value is correct';
        ok !$rows[0]->at( '[type=radio][name="config.selected_index"]' )->attr( 'checked' ),
            'first selected index radio is not selected';
        ok $rows[1]->at( '[name="config.options[1].label"]' ), 'second label field exists';
        is $rows[1]->at( '[name="config.options[1].label"]' )->attr( 'value' ),
            'BAR',
            'second label field value is correct';
        ok $rows[1]->at( '[name="config.options[1].value"]' ), 'second value field exists';
        is $rows[1]->at( '[name="config.options[1].value"]' )->attr( 'value' ),
            'BAR',
            'second value field value is correct';
        ok $rows[1]->at( '[type=radio][name="config.selected_index"]' ), 'selected index radio exists';
        is $rows[1]->at( '[type=radio][name="config.selected_index"]' )->attr( 'value' ),
            '1',
            'second selected index radio value is correct';
        ok !$rows[1]->at( '[type=radio][name="config.selected_index"]' )->attr( 'checked' ),
            'second selected index radio is not selected';
        ok $rows[2]->at( '[name="config.options[2].label"]' ), 'third label field exists';
        is $rows[2]->at( '[name="config.options[2].label"]' )->attr( 'value' ),
            'Baz',
            'third label field value is correct';
        ok $rows[2]->at( '[name="config.options[2].value"]' ), 'third value field exists';
        is $rows[2]->at( '[name="config.options[2].value"]' )->attr( 'value' ),
            'baz',
            'third value field value is correct';
        ok $rows[2]->at( '[type=radio][name="config.selected_index"]' ), 'selected index radio exists';
        is $rows[2]->at( '[type=radio][name="config.selected_index"]' )->attr( 'value' ),
            '2',
            'third selected index radio value is correct';
        ok $rows[2]->at( '[type=radio][name="config.selected_index"]' )->attr( 'checked' ),
            'third selected index radio is selected';
    };
};

subtest 'process_config' => sub {
    my $c = $t->app->build_controller;
    my $form_value = {
        options => [
            { label => 'FOO', value => 'foo' },
            { label => 'bar', value => 'bar' },
            { label => 'BAZ', value => 'BAZ' },
        ],
        selected_index => 1,
    };
    my $config_value = $type->process_config( $c, $form_value );
    is_deeply $config_value, $form_value, 'process_config value is correct';
};

subtest 'input_field' => sub {
    my $config_value = {
        options => [
            { label => 'FOO', value => 'foo' },
            { label => 'bar', value => 'bar' },
            { label => 'BAZ', value => 'BAZ' },
        ],
        selected_index => 1,
    };

    subtest 'options' => sub {
        my $c = $t->app->build_controller;
        my $html = $type->input_field( $c, $config_value, 'foo' );
        my $dom = Mojo::DOM->new( $html );

        is $dom->children->[0]->tag, 'select', 'field is a select tag'
            or diag explain $dom->children->[0];
        ok $dom->at( 'option[value=foo]' ), 'value foo exists';
        is $dom->at( 'option[value=foo]' )->content, 'FOO', 'value foo label is correct';
        ok $dom->at( 'option[value=bar]' ), 'value bar exists';
        is $dom->at( 'option[value=bar]' )->content, 'bar', 'value bar label is correct';
        ok $dom->at( 'option[value=BAZ]' ), 'value BAZ exists';
        is $dom->at( 'option[value=BAZ]' )->content, 'BAZ', 'value BAZ label is correct';
    };

    subtest 'default from config' => sub {
        my $c = $t->app->build_controller;
        my $html = $type->input_field( $c, $config_value, undef );
        my $dom = Mojo::DOM->new( $html );
        ok $dom->at( 'option[selected]' ), 'selected option exists';
        is $dom->at( 'option[selected]' )->attr( 'value' ), 'bar', 'selected value is correct';
    };

    subtest 'default from input' => sub {
        my $c = $t->app->build_controller;
        my $html = $type->input_field( $c, $config_value, 'foo' );
        my $dom = Mojo::DOM->new( $html );
        ok $dom->at( 'option[selected]' ), 'selected option exists';
        is $dom->at( 'option[selected]' )->attr( 'value' ), 'foo', 'selected value is correct';
    };
};

subtest 'process_input' => sub {
    my $config_value = {
        options => [
            { label => 'foo', value => 'foo' },
        ],
    };
    my $c = $t->app->build_controller;
    my $input_value = $type->process_input( $c, $config_value, 'foo' );
    is $input_value, 'foo', 'process_input returns value';

    subtest 'invalid input' => sub {
        eval { $type->process_input( $c, $config_value, 'INVALID' ) };
        ok $@, 'invalid value dies';
    };
};

subtest 'task_input' => sub {
    my $config_value = {
        options => [
            { label => 'foo', value => 'foo' },
        ],
    };
    my $task_value = $type->task_input( $config_value, 'foo' );
    is $task_value, 'foo', 'task_input returns value';

    subtest 'invalid value' => sub {
        eval { $type->task_output( $config_value, 'INVALID' ) };
        ok $@, 'invalid value dies';
    };
};

subtest 'task_output' => sub {
    my $config_value = {
        options => [
            { label => 'foo', value => 'foo' },
        ],
    };
    my $type_value = $type->task_output( $config_value, 'foo' );
    is $type_value, 'foo', 'task_output returns value';

    subtest 'invalid value' => sub {
        eval { $type->task_output( $config_value, 'INVALID' ) };
        ok $@, 'invalid value dies';
    };
};

done_testing;
