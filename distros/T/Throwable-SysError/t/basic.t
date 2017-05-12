#!perl

use Errno;
use Throwable::SysError;
use Test::More;


my $constant = (keys %!)[0];
my $errno    = Errno->$constant();
my $errstr   = do { local $! = $errno; ''. $! };


# re-throw pass-through
{
  eval {
    Throwable::SysError->new(
      message => 'Test', op => 'test', _errno => $errno )->throw;
  };

  my $e = $@;
  ok( UNIVERSAL::isa( $e, 'Throwable::SysError' ), 're-throw pass-through' );
  ok(   $e->is( $constant ), 'is()' );
  ok( ! $e->is( 'X'. $constant ), '! is()' );
}

# single arg handling
{
  local $! = 0;

  # invalid
  eval { Throwable::SysError->throw( 'fail' ) };

  my $e = $@;
  ok( ! UNIVERSAL::isa( $e, 'Throwable::SysError' ), 'throw( SCALAR )' );
}

{
  local $! = 0;

  # errno captured
  local $! = $errno;
  eval { Throwable::SysError->throw({ message => 'Fail', op => 'fail' }) };

  my $e = $@;
  ok( $e->errno  == $errno,  'throw( HASH ) without _errno: errno' );
  ok( $e->errstr eq $errstr, 'throw( HASH ) without _errno: errstr' );
}

{
  local $! = 0;

  # errno provided
  eval { Throwable::SysError->throw({ message => 'Fail', op => 'fail', _errno => $errno }) };

  my $e = $@;
  ok( $e->errno  == $errno,  'throw( HASH ) with _errno: errno' );
  ok( $e->errstr eq $errstr, 'throw( HASH ) with _errno: errstr' );
}

# multiple arg handling
{
  local $! = 0;

  # errno captured
  local $! = $errno;
  eval { Throwable::SysError->throw( message => 'Fail', op => 'fail' ) };

  my $e = $@;
  ok( $e->errno  == $errno,  'throw( LIST ) without _errno: errno' );
  ok( $e->errstr eq $errstr, 'throw( LIST ) without _errno: errstr' );
}

{
  local $! = 0;

  # errno provided
  eval { Throwable::SysError->throw( message => 'Fail', op => 'fail', _errno => $errno ) };

  my $e = $@;
  ok( $e->errno  == $errno,  'throw( LIST ) with _errno: errno' );
  ok( $e->errstr eq $errstr, 'throw( LIST ) with _errno: errstr' );
}


done_testing;
