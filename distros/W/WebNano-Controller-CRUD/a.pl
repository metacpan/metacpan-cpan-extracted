use strict;
use warnings;

use lib 'lib';
use lib 't/lib';
use MyApp::DBSchema;

{
    package MyApp::Controller::Form;
    use HTML::FormHandler::Moose;
    extends 'HTML::FormHandler::Model::DBIC';
    with 'HTML::FormHandler::Render::Simple';


    has '+item_class' => ( default => 'Dvd' );

    has_field 'tags' => ( type => 'Select', multiple => 1 );
    has_field 'name' => ( type => 'TextArea', );
    has_field 'submit' => ( widget => 'submit' );
}

my $schema = MyApp::DBSchema->connect( 'dbi:SQLite:dbname=:memory:' );
$schema->deploy;
$schema->resultset( 'Tag' )->create( { name => 'aaa' } );
$schema->resultset( 'Tag' )->create( { name => 'bbb' } );
my $item = $schema->resultset( 'Dvd' )->new_result( {} );
my $form = MyApp::Controller::Form->new(
    schema => $schema,
    item   => $item,
);

warn $form->render;

