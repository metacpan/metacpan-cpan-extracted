#!/usr/bin/perl

use XML::LibXML;
use XML::XForms::Generator;

{
	## Generate a model element.
	#my $model = xforms_model( id => 'myForm' );
	my $model = xforms_model( { id => 'myForm',
								"ev:test" => 'Bob' } );

	$model->appendSubmission( { id     => 'myID',
								action => '/asdf/safd/',
								method => 'Post' }, qq|instance| );


	$model->appendInstance( {}, XML::LibXML::Element->new( "data" ) );

	my $input = xforms_input( { id => 'Bob',
								inputmode => 'test',
								'ref'	=> '/inputdata' },
							  [ qq|label|,
								{ model => 'bob' },
								qq|This is my label!| ] );

	$input->appendHelp( { model => 'bob' }, qq|This is my HELP!| );
	#$input->appendFilename( { model => 'bob' }, qq|This is my label| );

	$model->setInstanceData( "/bobbity//boo/dude", "DragonBallZ" );

	my $select = xforms_select( {}, [ "label", {}, "Test" ] );

	$select->appendItem( {}, [ "label", {}, "ONE" ], [ "value", {}, 1 ] );
	$select->appendItem( {}, [ "label", {}, "TWO" ], [ "value", {}, 2 ] );

	my $bind = XML::LibXML::Element->new( "bind" );
	$bind->setAttribute( "nodeset", "input/bob" );
	$bind->setAttribute( "id", "myBind" );
	my $value = XML::LibXML::Text->new( "Test DATA" );
	$model->bindControl( $input, undef, $value );

	my $group = xforms_group( {}, $input, $select );

	$group->appendLabel( {}, "Bob" );

	## These elements inherit all the love of XML::LibXML ... so you can
	## do stuff like:
	print $model->toString( 2 ) . "\n\n";
	print $group->toString( 2 ) . "\n\n";	

	exit( 0 );
}
