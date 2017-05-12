#!perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'lib/Thread/App/Shutdown.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 41 lib/Thread/App/Shutdown.pm
use_ok('Thread::App::Shutdown');

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 74 lib/Thread/App/Shutdown.pm

use threads::shared;

use Test::Exception;

my $class = 'Thread::App::Shutdown';

# make sure we can get an instance
my $shutdown;
lives_ok { $shutdown = $class->instance }
    "can get an instance of $class";
isa_ok( $shutdown, $class );
is( $shutdown->get, 0, 'flag is not set' );

# create a new condition variable
my $cond : shared = 0;

# run the test subroutine in a new thread
threads->create( sub {
    
    # wait for the condition to be set
    lock $cond;
    cond_wait $cond;
    
    # check the flag status
    is( $shutdown->get, 0, 'flag is not set in thread' );
    
    # set the condition
    cond_signal $cond;
    
} )->detach;

# set the condition
lock $cond;
cond_signal $cond;

# wait for the condition to be set
lock $cond;
cond_wait $cond;


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 140 lib/Thread/App/Shutdown.pm

my $shutdown = Thread::App::Shutdown->instance;
lives_ok { $shutdown->clear } 'clear flag';
is( $shutdown->get, 0, 'flag is not set' );

# create a new condition variable
my $cond : shared = 0;

threads->create( sub {
    
    lock $cond;
    cond_wait $cond;
    
    is( $shutdown->get, 0, 'flag is not set in thread');
    lives_ok { $shutdown->set(1) } 'set flag to 1 in thread';
    is( $shutdown->get, 1, 'flag is set in thread');
    
    cond_signal $cond;
    lock $cond;
    cond_wait $cond;
    
    is( $shutdown->get, 0, 'flag is not set in thread');
    lives_ok { $shutdown->set('foo') } 'set flag to foo in thread';
    is( $shutdown->get, 1, 'flag is set in thread');
    
    cond_signal $cond;
    lock $cond;
    cond_wait $cond;
    
    is( $shutdown->get, 0, 'flag is not set in thread');
    
} )->detach;

lock $cond;
cond_signal $cond;
lock $cond;
cond_wait $cond;

is( $shutdown->get, 1, 'flag is set');
lives_ok { $shutdown->set(undef) } 'set flag to undef';
is( $shutdown->get, 0, 'flag is not set');

cond_signal $cond;
lock $cond;
cond_wait $cond;

is( $shutdown->get, 1, 'flag is set');
lives_ok { $shutdown->clear } 'clear flag';
is( $shutdown->get, 0, 'flag is not set');

cond_signal $cond;


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 244 lib/Thread/App/Shutdown.pm
my $shutdown = Thread::App::Shutdown->instance;
lives_ok { $shutdown->set( 1 ) } 'set flag to 1';
is( $shutdown->get, 1, 'flag is set');
lives_ok { $shutdown->clear } 'clear flag';
is( $shutdown->get, 0, 'flag is not set');

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

