use Test::More;
use Modern::Perl;
use Util::Medley::Cache;
use Data::Printer alias => 'pdump';

$SIG{__WARN__} = sub { die @_ };

#####################################
# coNstructor
#####################################

my $Ns   = 'unittest';
my @Keys = qw(item1 item2 item3 item4);
my @Data = ( 'foobar', { biz => 'baz' }, [ x => 'y' ], [ 1, 2 ] );

my $c = Util::Medley::Cache->new;
ok($c);

$c = Util::Medley::Cache->new( ns => $Ns );
ok($c);

#####################################
# set
#####################################

test_set( Util::Medley::Cache->new );
test_set( Util::Medley::Cache->new( ns => $Ns ) );

#####################################
# get
#####################################

test_get( Util::Medley::Cache->new );
test_get( Util::Medley::Cache->new( ns => $Ns ) );

#####################################
# getKeys
#####################################

test_getKeys( Util::Medley::Cache->new );
test_getKeys( Util::Medley::Cache->new( ns => $Ns ) );

#####################################
# delete
#####################################

test_delete( Util::Medley::Cache->new );
test_delete( Util::Medley::Cache->new( ns => $Ns ) );

#####################################
# clear
#####################################

test_clear( Util::Medley::Cache->new );
test_clear( Util::Medley::Cache->new( ns => $Ns ) );

#
# tests without any attributes passed in
#
$c = Util::Medley::Cache->new;

# add and verify seed data
ok( $c->destroy( ns => $Ns ) );
$c->set( ns => $Ns, key => 'item1', data => { foo => 'bar' } );
$c->set( ns => $Ns, key => 'item2', data => { biz => 'baz' } );
ok( my @keys = $c->getKeys( ns => $Ns ) );
ok( @keys == 2 );

# happy path
ok( $c->clear( ns => $Ns ) );

# verify clear worked
@keys = $c->getKeys( ns => $Ns );
ok( @keys == 0 );

#
# tests with ns attribute set
#
$c = Util::Medley::Cache->new( ns => $Ns );

# add and verify seed data
ok( $c->destroy( ns => $Ns ) );
$c->set( ns => $Ns, key => 'item1', data => { foo => 'bar' } );
$c->set( ns => $Ns, key => 'item2', data => { biz => 'baz' } );
ok( @keys = $c->getKeys );
ok( @keys == 2 );

# happy path
ok( $c->clear );

# verify clear worked
@keys = $c->getKeys;
ok( @keys == 0 );

# Note: is does deep checking, unlike the 'is' from Test::More.
#is(...);

done_testing;

######################################################################

sub test_clear {

	my $c = shift;

	destroy_data();
	seed_data();

	if ( !$c->ns ) {

		ok( my @curr = $c->getKeys( ns => $Ns ) );
	}
	else {

	}
}

sub destroy_data {

	state $count = 1;

	my $c = Util::Medley::Cache->new;

	if ( $count / 2 ) {
		ok( $c->destroy( ns => $Ns ) );
	}
	else {
		ok( $c->destroy($Ns) );
	}

	$count++;
}

sub seed_data {

	my $c = Util::Medley::Cache->new;
	$c->set( ns => $Ns, key => $Keys[0], data => $Data[0] );
	$c->set( ns => $Ns, key => $Keys[1], data => $Data[1] );
	$c->set( ns => $Ns, key => $Keys[2], data => $Data[2] );
	$c->set( ns => $Ns, key => $Keys[3], data => $Data[3] );
}

sub test_set {

	my $c = shift;

	destroy_data();

	if ( !$c->ns ) {

		# should succeed
		ok( $c->set( ns => $Ns, key => $Keys[0], data => $Data[0] ) );

		# should fail
		eval { $c->set( key => $Keys[1], $Data[1] ) };
		ok($@);
	}
	else {

		# should succeed
		ok( $c->set( key => $Keys[1], data => $Data[1] ) );
	}
}

sub test_getKeys {

	my $c = shift;

	destroy_data();
	seed_data();

	if ( !$c->ns ) {

		# should succeed
		ok( my @keys = $c->getKeys( ns => $Ns ) );
		is( @keys, @Keys );

		# should fail
		eval { $c->getKeys };
		ok($@);
	}
	else {

		# should succeed
		ok( my @keys = $c->getKeys );
		is( @keys, @Keys );
	}
}

sub test_delete {

	my $c = shift;

	destroy_data();
	seed_data();

	if ( !$c->ns ) {

		# should succeed
		ok( $c->delete( ns => $Ns, key => $Keys[0] ) );
		ok( !$c->get( ns => $Ns, key => $Keys[0] ) );

		# should succeed
		ok( $c->delete( ns => $Ns, key => 'doesnotexist' ) );

		# should fail
		eval { $c->delete( key => $Keys[1] ) };
		ok($@);
	}
	else {

		# should succeed
		ok( $c->delete( key => $Keys[2] ) );
		ok( !$c->get( key => $Keys[2] ) );

		# should succeed
		ok( $c->delete( key => 'doesnotexist' ) );
	}
}

sub test_get {

	my $c = shift;

	destroy_data();
	seed_data();

	if ( !$c->ns ) {

		# should succeed
		ok( my $data = $c->get( ns => $Ns, key => $Keys[2] ) );
		is_deeply( $data, $Data[2] );

		# should fail
		eval { $c->get( key => $Keys[3] ) };
		ok($@);
	}
	else {

		# should succeed
		ok( my $data = $c->get( key => $Keys[2] ) );
		is_deeply( $data, $Data[2] );

		# should succeed
		eval { $c->get( key => $Keys[3] ) };
		ok( !$@ );
	}
}
