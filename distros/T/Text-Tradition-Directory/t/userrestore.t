#!/usr/bin/env perl;

use strict;
use warnings;
use File::Temp;
use Safe::Isa;
use Test::More;
use Test::Warn;
use Text::Tradition;
use Text::Tradition::Directory;

my $newt = Text::Tradition->new( 'input' => 'Self', 
	'file' => 't/data/florilegium_graphml.xml' );
	
my $graphml = $newt->collation->as_graphml;
unlike( $graphml, qr/testuser/, "Test user name does not exist in GraphML yet" );

my $fh = File::Temp->new();
my $file = $fh->filename;
$fh->close;
my $dsn = "dbi:SQLite:dbname=$file";
my $userstore = Text::Tradition::Directory->new( { dsn => $dsn,
	extra_args => { create => 1 } } );
my $scope = $userstore->new_scope();
my $testuser = $userstore->create_user( { url => 'http://example.com' } );
ok( $testuser->$_isa('Text::Tradition::User'), "Created test user via userstore" );
$testuser->add_tradition( $newt );
is( $newt->user->id, $testuser->id, "Assigned tradition to test user" );
my $graphml_str = $newt->collation->as_graphml;
my $usert;
warning_is {
	$usert = Text::Tradition->new( 'input' => 'Self', 'string' => $graphml_str );
} 'DROPPING user assignment without a specified userstore',
	"Got expected user drop warning on parse";
$usert = Text::Tradition->new( 'input' => 'Self', 'string' => $graphml_str,
	'userstore' => $userstore );
is( $usert->user->id, $testuser->id, "Parsed tradition with userstore points to correct user" );

done_testing();
