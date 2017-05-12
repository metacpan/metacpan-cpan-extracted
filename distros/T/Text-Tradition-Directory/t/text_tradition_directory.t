#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
use TryCatch;
use File::Temp;
use Safe::Isa;
use Text::Tradition;
use_ok 'Text::Tradition::Directory';

my $fh = File::Temp->new();
my $file = $fh->filename;
$fh->close;
my $dsn = "dbi:SQLite:dbname=$file";
my $uuid;
my $user = 'user@example.org';
my $t = Text::Tradition->new( 
	'name'  => 'inline', 
	'input' => 'Tabular',
	'file'  => 't/data/simple.txt',
	);
my $stemma_enabled = $t->can( 'add_stemma' );

{
	my $d = Text::Tradition::Directory->new( 'dsn' => $dsn,
		'extra_args' => { 'create' => 1 } );
	ok( $d->$_isa('Text::Tradition::Directory'), "Got directory object" );
	
	my $scope = $d->new_scope;
	$uuid = $d->save( $t );
	ok( $uuid, "Saved test tradition" );
	
	# Add a test user
	my $user = $d->add_user({ username => $user, password => 'UserPass' }); 
	$user->add_tradition( $t );
	$d->store( $user );
	is( $t->user, $user, "Assigned tradition to test user" );
	
	SKIP: {
		skip "Analysis package not installed", 5 unless $stemma_enabled;
		my $s = $t->add_stemma( dotfile => 't/data/simple.dot' );
		ok( $d->save( $t ), "Updated tradition with stemma" );
		is( $d->tradition( $uuid ), $t, "Correct tradition returned for id" );
		is( $d->tradition( $uuid )->stemma(0), $s, "...and it has the correct stemma" );
		try {
			$d->save( $s );
		} catch( Text::Tradition::Error $e ) {
			is( $e->ident, 'database error', "Got exception trying to save stemma directly" );
			like( $e->message, qr/Cannot directly save non-Tradition object/, 
				"Exception has correct message" );
		}
	}
}
my $nt = Text::Tradition->new(
	'name' => 'CX',
	'input' => 'CollateX',
	'file' => 't/data/Collatex-16.xml',
	);
ok( $nt->$_isa('Text::Tradition'), "Made new tradition" );

{
	my $f = Text::Tradition::Directory->new( 'dsn' => $dsn );
	my $scope = $f->new_scope;
	is( scalar $f->traditionlist, 1, "Directory index has our tradition" );
	my $nuuid = $f->save( $nt );
	ok( $nuuid, "Stored second tradition" );
	my @tlist = $f->traditionlist;
	is( scalar @tlist, 2, "Directory index has both traditions" );
	my $tf = $f->tradition( $uuid );
	my( $tlobj ) = grep { $_->{'id'} eq $uuid } @tlist;
	is( $tlobj->{'name'}, $tf->name, "Directory index has correct tradition name" );
	is( $tf->name, $t->name, "Retrieved the tradition from a new directory" );
	my $sid;
	SKIP: {
		skip "Analysis package not installed", 4 unless $stemma_enabled;
		$sid = $f->object_to_id( $tf->stemma(0) );
		try {
			$f->tradition( $sid );
		} catch( Text::Tradition::Error $e ) {
			is( $e->ident, 'database error', "Got exception trying to fetch stemma directly" );
			like( $e->message, qr/not a Text::Tradition/, "Exception has correct message" );
		}
		if( $ENV{TEST_DELETION} ) {
			try {
				$f->delete( $sid );
			} catch( Text::Tradition::Error $e ) {
				is( $e->ident, 'database error', "Got exception trying to delete stemma directly" );
				like( $e->message, qr/Cannot directly delete non-Tradition object/, 
					"Exception has correct message" );
			}
		}
	}
	
	SKIP: {
		skip "Set TEST_DELETION in env to test DB deletion functionality", 3
			unless $ENV{TEST_DELETION};
		$f->delete( $uuid );
		ok( !$f->exists( $uuid ), "Object is deleted from DB" );
		ok( !$f->exists( $sid ), "Object stemma also deleted from DB" ) if $stemma_enabled;
		is( scalar $f->traditionlist, 1, "Object is deleted from index" );
	}
}

{
	my $g = Text::Tradition::Directory->new( 'dsn' => $dsn );
	my $scope = $g->new_scope;
	SKIP: {
		skip "Set TEST_DELETION in env to test DB deletion functionality", 1
			unless $ENV{TEST_DELETION};
		is( scalar $g->traditionlist, 1, "Now one object in new directory index" );
	}
	my $ntobj = $g->tradition( 'CX' );
	my @w1 = sort { $a->sigil cmp $b->sigil } $ntobj->witnesses;
	my @w2 = sort{ $a->sigil cmp $b->sigil } $nt->witnesses;
	is_deeply( \@w1, \@w2, "Looked up remaining tradition by name" );
}
}




1;
