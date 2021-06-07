
=head1 DESCRIPTION

This tests the Zapp::Type::File class

=cut

use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Zapp;
use Mojo::DOM;
use Mojo::File qw( path tempfile tempdir );
use Zapp::Type::File;

my $t = Test::Zapp->new( 'Zapp' );
my $type = Zapp::Type::File->new( app => $t->app );
$t->app->zapp->add_type( file => $type );
my $temp = tempdir();
$t->app->home( $temp );

subtest 'config_field' => sub {
    my $c = $t->app->build_controller;
    my $html = $type->config_field( $c, 'foo' );
    is $html, '', 'no config for file fields (yet)';
};

subtest 'process_config' => sub {
    my $c = $t->app->build_controller;
    my $config = $type->process_config( $c, undef );
    is_deeply $config, {}, 'no config for file fields (yet)';
};

subtest 'input_field' => sub {
    my $c = $t->app->build_controller;
    my $html = $type->input_field( $c, undef );
    my $dom = Mojo::DOM->new( $html );

    my $field = $dom->children->[0];
    is $field->tag, 'input', 'field is an input tag'
        or diag explain $field;
    ok !$field->attr( 'value' ), 'field value correct (no defaults)'
        or diag explain $field;
};

subtest 'process_input' => sub {
    my $c = $t->app->build_controller;
    my $upload = Mojo::Upload->new(
        filename => 'foo.txt',
        asset => Mojo::Asset::Memory->new->add_chunk( 'Hello, World!' ),
        name => 'input[0].value',
    );
    my $type_value = $type->process_input( $c, undef, $upload );
    is $type_value, 'Cg/qf/KmdylCVXq1NV12r0Qvj2XgE/foo.txt',
        'form_input returns path';
    my $file = $temp->child( 'public', split m{/}, $type_value );
    ok -e $file, 'file exists';
    is $file->slurp, 'Hello, World!', 'file content is correct';

    subtest 'no default' => sub {
        my $upload = Mojo::Upload->new(
            filename => '',
            asset => Mojo::Asset::Memory->new->add_chunk( '' ),
            name => 'input[0].value',
        );
        my $type_value = $type->process_input( $c, undef, $upload );
        is $type_value, undef, 'blank value is undef';
    };
};

subtest 'task_input' => sub {
    my $type_value = 'task_input';
    my $input_file = $temp->child( 'public', $type_value )->spurt( 'Goodbye, World!' );
    my $task_value = $type->task_input( undef, $type_value );
    isa_ok $task_value, 'Mojo::File';
    is $task_value, $t->app->home->child( 'public', $type_value ),
        'task_value path is correct';
};

subtest 'task_output' => sub {
    my $tmp = tempfile()->spurt( 'Goodbye, World!' );
    my $task_value = "$tmp";
    my $type_value = $type->task_output( undef, $task_value );
    is $type_value, 'qj/OR/3yrB7CZSKh0leolWSXSF-nY/' . $tmp->basename,
        'type_value is correct';
    my $file = $t->app->home->child( 'public', split m{/}, $type_value );
    ok -e $file, 'file exists';
    is $file->slurp, 'Goodbye, World!', 'file content is correct';
};

done_testing;
