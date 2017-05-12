#!/usr/bin/perl

# Test the cPanel::TaskQueue::Task module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";

use Test::More tests => 31;
use Test::Exception;
use cPanel::TaskQueue::Task;

ok( !defined cPanel::TaskQueue::Task->reconstitute(undef), 'Leave undef alone.' );

throws_ok { cPanel::TaskQueue::Task->reconstitute('foo') } qr/hash reference/, 'Dies if argument is string';
throws_ok { cPanel::TaskQueue::Task->reconstitute( [] ) } qr/hash reference/, 'Dies if argument is array';
throws_ok { cPanel::TaskQueue::Task->reconstitute( {} ) } qr/Missing .* field/, 'Dies if argument hash is empty';

{

    # Testing reconstituting a Task object
    my $task = cPanel::TaskQueue::Task->new( { cmd => 'foo', id => 1 } );
    isa_ok( $task, 'cPanel::TaskQueue::Task' );
    my $rtask = cPanel::TaskQueue::Task->reconstitute($task);
    is_deeply( $rtask, $task, 'Return the supplied task if right type.' )
      or note explain $rtask;
    isa_ok( $rtask, 'cPanel::TaskQueue::Task' );
}

{

    # Testing reconstituting the hash from a Task object
    my $task  = cPanel::TaskQueue::Task->new( { cmd => 'foo', id => 1 } );
    my $hash  = { %{$task} };                                                # Clone the task hash, removing the type.
    my $rtask = cPanel::TaskQueue::Task->reconstitute($hash);
    is_deeply( $rtask, $task, 'Restore the type' ) or note explain $rtask;
    isa_ok( $rtask, 'cPanel::TaskQueue::Task' );
}

{

    # Testing reconstituting the hashes that are missing fields
    my $task  = cPanel::TaskQueue::Task->new( { cmd => 'foo', id => 1 } );
    my $ohash = { %{$task} };                                                # Clone the task hash, removing the type.
    foreach my $field ( sort keys %{$ohash} ) {
        my $hash = { %{$ohash} };
        delete $hash->{$field};
        throws_ok { cPanel::TaskQueue::Task->reconstitute($hash) } qr/Missing.*$field/, "Detect missing '$field'";
    }
}

{

    # Testing reconstituting hashes with undefined fields
    my $task  = cPanel::TaskQueue::Task->new( { cmd => 'foo', id => 1 } );
    my $ohash = { %{$task} };                                                # Clone the task hash, removing the type.
    foreach my $field ( sort keys %{$ohash} ) {
        my $hash = { %{$ohash} };
        $hash->{$field} = undef;
        if ( $field eq '_pid' or $field eq '_started' ) {
            lives_ok { cPanel::TaskQueue::Task->reconstitute($hash) } "Undefined '$field' is allowed";
        }
        else {
            throws_ok { cPanel::TaskQueue::Task->reconstitute($hash) } qr/Field '$field' has no/, "Undefined '$field' detected";
        }
    }
}

{

    # Testing reconstituting hashes invalid args
    my $task = cPanel::TaskQueue::Task->new( { cmd => 'foo', id => 1 } );
    my $ohash = { %{$task} };    # Clone the task hash, removing the type.
    {
        my $hash = { %{$ohash}, _args => 'a string' };
        throws_ok { cPanel::TaskQueue::Task->reconstitute($hash) } qr/The '_args' field.*array/, "'_args' cannot be a string";
    }
    {
        my $hash = { %{$ohash}, _args => {} };
        throws_ok { cPanel::TaskQueue::Task->reconstitute($hash) } qr/The '_args' field.*array/, "'_args' cannot be a hash";
    }
}
