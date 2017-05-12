package Love;

sub new {
  return bless {}, Love;
}

sub marry 
{
    my $self = shift;
    my $user1 = shift;
    my $user2 = shift;

    my $db_object = $self->{'db_object'};

    if( $db_object->is_married( $user1 ) == 0 && 
        $db_object->is_married( $user2 ) == 0 )
    {
        $db_object->marry( $user1, $user2 );
        $db_object->marry( $user2, $user1 );
        return 1;
    }
    return 0;
}

package MyDbClass;

sub is_married { 
# do some complicated stuff
}

sub marry {
# do some other complicated stuff
}

#Our test can be
use Test::Pockito;
use Test::Simple tests => 2;

my $pocket  = Test::Pockito->new("MyNamespace");
my $db_mock = $pocket->mock("MyDbClass");

$pocket->when( $db_mock->is_married( "bob" ) )->then( 0 );
$pocket->when( $db_mock->is_married( "alice" ) )->then( 0 );
$pocket->when( $db_mock->marry( "alice", "bob" ) )->then( );
$pocket->when( $db_mock->marry( "bob",   "alice" ) )->then( );

$pocket->{warn} = 1;

my $target = Love->new();
$target->{'db_object'} = $db_mock;

ok( $target->marry("bob","alice") == 1,
    "single to married == success!" );

ok( scalar keys %{ $pocket->expected_calls } == 0, 
    "No extra cruft calls, huzzah!" );
