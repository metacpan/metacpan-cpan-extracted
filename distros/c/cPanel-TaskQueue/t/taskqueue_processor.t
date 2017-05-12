#!/usr/bin/perl

# Test the cPanel::TaskQueue::Processor module.
#
use strict;
use warnings;

use Test::More tests => 12;
use cPanel::TaskQueue::Processor;

my $proc = cPanel::TaskQueue::Processor->new;
isa_ok( $proc, 'cPanel::TaskQueue::Processor' );

{

    package MockTask;

    sub new {
        my $class = shift;
        my $self  = {@_};
        return bless $self, $class;
    }

    sub command {
        return $_[0]->{command};
    }

    sub args {
        return @{ $_[0]->{args} };
    }
}

# Test the is_dupe method.
my @dupe_checks = (
    [
        MockTask->new( command => 'me',  args => [] ),
        MockTask->new( command => 'you', args => [] ),
        0,
        'is_dupe: commands are different'
    ],
    [
        MockTask->new( command => 'me', args => [] ),
        MockTask->new( command => 'me', args => [] ),
        1,
        'is_dupe: Same commands no args'
    ],
    [
        MockTask->new( command => 'me', args => ['a'] ),
        MockTask->new( command => 'me', args => ['a'] ),
        1,
        'is_dupe: Same commands 1 matching arg'
    ],
    [
        MockTask->new( command => 'me', args => ['a'] ),
        MockTask->new( command => 'me', args => ['b'] ),
        0,
        'is_dupe: Same commands 1 non-matching arg'
    ],
    [
        MockTask->new( command => 'me', args => [qw/a b c d e f g/] ),
        MockTask->new( command => 'me', args => [qw/a b c d e f g/] ),
        1,
        'is_dupe: Same commands matching n args'
    ],
    [
        MockTask->new( command => 'me', args => [qw/a b c d e f g/] ),
        MockTask->new( command => 'me', args => [qw/a b c d e f g h/] ),
        0,
        'is_dupe: Same commands different number of args'
    ],
);

foreach my $try (@dupe_checks) {
    is( !!$proc->is_dupe( $try->[0], $try->[1] ), !!$try->[2], $try->[3] );
}

eval { $proc->process_task(); };
like( $@, qr/No processing/, "process_task: default exceptions" );

ok( !defined $proc->get_timeout(), q{Default to use queue's timeout.} );

eval { cPanel::TaskQueue::Processor::CodeRef->new( {} ); };
like( $@, qr/required code/, 'Cannot create without code param.' );

eval { cPanel::TaskQueue::Processor::CodeRef->new( { code => undef } ); };
like( $@, qr/required code/, 'Cannot create with undefined code param.' );

eval { cPanel::TaskQueue::Processor::CodeRef->new( { code => 'fred' } ); };
like( $@, qr/required code/, 'Code param must be a code ref.' );

