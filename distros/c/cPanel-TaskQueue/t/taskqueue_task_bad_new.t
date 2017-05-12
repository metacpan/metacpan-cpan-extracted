#!/usr/bin/perl

# Test the cPanel::TaskQueue::Task module.
#

use strict;
use FindBin;
use lib "$FindBin::Bin/mocks";

use Test::More tests => 14;
use cPanel::TaskQueue::Task;

eval {
    cPanel::TaskQueue::Task->new();
};
like( $@, qr/Missing arguments/, q{Don't create with no arguments} );

eval {
    cPanel::TaskQueue::Task->new( ' ' );
};
like( $@, qr/Args parameter .*? hash ref/, q{Args not a hash ref} );

eval {
    cPanel::TaskQueue::Task->new({});
};
like( $@, qr/Missing command/, q{Don't create with no command string} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>' '} );
};
like( $@, qr/Missing command/, q{Don't create with empty command string} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', nsid=>undef} );
};
like( $@, qr/Invalid Namespace/, q{Can't pass an undefined namespace id.} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', nsid=>''} );
};
like( $@, qr/Invalid Namespace/, q{Can't pass an empty namespace id.} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', nsid=>'fr:ed'} );
};
like( $@, qr/Invalid Namespace/, q{Can't pass an invalid namespace id.} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop'} );
};
like( $@, qr/Invalid id/, q{Don't create with missing queue id} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>'none'} );
};
like( $@, qr/Invalid id/, q{Don't create with non-numeric queue id} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>-12} );
};
like( $@, qr/Invalid id/, q{Don't create with negtive queue id} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, timeout=>'fred'} );
};
like( $@, qr/Invalid child timeout/, q{Don't create with non-numeric child timeout} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, timeout=>-12} );
};
like( $@, qr/Invalid child timeout/, q{Don't create with negative child timeout} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, timeout=>0} );
};
like( $@, qr/Invalid child timeout/, q{Don't create with zero child timeout} );

eval {
    cPanel::TaskQueue::Task->new( {cmd=>'noop', id=>1, retries=>-12} );
};
like( $@, qr/Invalid value for retries/, q{Don't create with negative retry count.} );
