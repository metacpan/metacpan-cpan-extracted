
=head1 DESCRIPTION

This tests the Zapp::Type::Textarea class

=cut

use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Zapp;
use Mojo::DOM;
use Zapp::Type::Textarea;

my $t = Test::Zapp->new( 'Zapp' );
my $type = Zapp::Type::Textarea->new;
$t->app->zapp->add_type( text_area => $type );

subtest 'config_field' => sub {
    my $c = $t->app->build_controller;
    my $html = $type->config_field( $c, 'foo' );
    my $dom = Mojo::DOM->new( $html );

    ok $dom->at( 'textarea' ), 'config input tag textarea';
    is $dom->at( 'textarea' )->text, 'foo', 'config input tag value correct';
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

    ok $dom->at( 'textarea' ), 'input tag textarea';
    is $dom->at( 'textarea' )->text, 'foo', 'input tag value correct';
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
