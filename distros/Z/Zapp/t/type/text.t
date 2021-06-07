
=head1 DESCRIPTION

This tests the Zapp::Type::Text class

=cut

use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Zapp;
use Mojo::DOM;
use Zapp::Type::Text;

my $t = Test::Zapp->new( 'Zapp' );
my $type = Zapp::Type::Text->new;
$t->app->zapp->add_type( text => $type );

subtest 'config_field' => sub {
    my $c = $t->app->build_controller;
    my $html = $type->config_field( $c, 'foo' );
    my $dom = Mojo::DOM->new( $html );

    is $dom->at( 'input' )->attr( 'type' ), 'text', 'config input tag type "text"';
    is $dom->at( 'input' )->attr( 'value' ), 'foo', 'config input tag value correct';
};

subtest 'process_config' => sub {
    my $c = $t->app->build_controller;
    my $config = $type->process_config( $c, 'foo' );
    is $config, 'foo', 'process_config returns value';
};

subtest 'input_field' => sub {
    my $c = $t->app->build_controller;
    my $html = $type->input_field( $c, 'foo' );
    my $dom = Mojo::DOM->new( $html );

    is $dom->at( 'input' )->attr( 'type' ), 'text', 'input tag type "text"';
    is $dom->at( 'input' )->attr( 'value' ), 'foo', 'input tag value correct';
};

subtest 'process_input' => sub {
    my $c = $t->app->build_controller;
    my $input_value = $type->process_input( $c, 'default', 'foo' );
    is $input_value, 'foo', 'process_input returns value';
};

subtest 'task_input' => sub {
    my $task_value = $type->task_input( 'default', 'foo' );
    is $task_value, 'foo', 'task_input returns value';
};

subtest 'task_output' => sub {
    my $type_value = $type->task_output( 'default', 'foo' );
    is $type_value, 'foo', 'task_output returns value';
};

done_testing;
