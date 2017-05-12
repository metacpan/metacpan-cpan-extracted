#!/usr/bin/perl

use Test::More ( $^O =~ /mswin/i
        ? ('skip_all' => 'checked_system tests do not work under Windows')
        : eval "use Test::Exception; 1;"
        ? (tests => 10)
        : ('skip_all' => 'Test::Exception needed for this test.')
    );

use strict;
use warnings;

{
    package MockLogger;
    my $message;
    sub new   { return bless {}; }
    sub throw { shift; die @_; }
    sub warn  { shift; $message = join( '', 'WARN:', @_ ); }

    sub get_message { return $message; }
    sub clear { $message = ''; return; }
}

use cPanel::TaskQueue::Processor;

my $proc = cPanel::TaskQueue::Processor->new();

throws_ok { $proc->checked_system() } qr/must be a hashref/, 'No arg case recognized';
throws_ok { $proc->checked_system({}) } qr/required 'logger'/, 'Recognized missing logger';

my $logger = MockLogger->new();
throws_ok { $proc->checked_system( { logger => $logger, name => 'test' } ); }
    qr/required 'cmd'/,
    'Recognized missing cmd';

throws_ok { $proc->checked_system( { logger => $logger, cmd => 'test' } ); }
    qr/required 'name'/,
    'Recognized missing name';

$logger->clear();
{
    # Stop output on std error.
    open my $olderr, ">&STDERR" or die "Unable to dup STDERR: $!";
    open STDERR, '>', '/dev/null' or die "Unable to redirect STDERR: $!";
    is( $proc->checked_system( { logger => $logger, name => 'foobarxyzzy', cmd => 'foobarxyzzy' } ), -1, 'Program cannot run' );
    is( $logger->get_message, 'WARN:Failed to run foobarxyzzy', 'Warning detected.' );
    open STDERR, '>', $olderr;
}

$logger->clear();
is( $proc->checked_system( { logger => $logger, name => 'true run', cmd => 'true' } ), 0, 'Successful run.' );
is( $logger->get_message, '', 'No warnings or messages' );

$logger->clear();
isnt( $proc->checked_system( { logger => $logger, name => 'false run', cmd => 'false' } ), 0, 'Program failed' );
like( $logger->get_message, qr/^WARN:false run exited with value [1-9]\d*$/, 'Warning detected (non-zero return).' );
