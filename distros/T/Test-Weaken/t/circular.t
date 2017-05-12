#!perl

# Based on the test case created by Kevin Ryde for #42502

# This is a basic circular reference class which undoes its circularities
# under an explicit undo() method.  This is a little like HTML::Tree.

package MyCircular;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    my $self = bless { data => 'this is mycircular' }, $class;
    $self->{'circular'} = [$self];
    return $self;
}

sub undo {
    my ($self) = @_;
    @{ $self->{'circular'} } = ();
    return 1;
}

package main;

use strict;
use warnings;
use Test::Weaken;
use Test::More tests => 2;

use lib 't/lib';
use Test::Weaken::Test;

my $test = Test::Weaken::leaks(
    sub { MyCircular->new },
    sub {
        my ($obj) = @_;
        $obj->undo;
    }
);
my $unfreed_count = $test ? $test->unfreed_count() : 0;
Test::Weaken::Test::is( $unfreed_count, 0, 'good destructor' );

$test = Test::Weaken::leaks( sub { MyCircular->new }, sub { } );
$unfreed_count = $test ? $test->unfreed_count() : 0;
Test::Weaken::Test::is( $unfreed_count, 5, 'null destructor' );
