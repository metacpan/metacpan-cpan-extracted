#!/usr/local/bin/perl -w
my @custom_inc;
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @custom_inc = @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, (@custom_inc = ('../blib/lib', '../blib/arch'));
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

use forks; # must be done _before_ Test::More which loads real threads.pm
use forks::shared;

diag( <<EOD );

These tests check CLONE and SKIP_CLONE functionality.

EOD

# "Unpatch" Test::More, who internally tries to disable threads
BEGIN {
    no warnings 'redefine';
    if ($] < 5.008001) {
        require forks::shared::global_filter;
        import forks::shared::global_filter 'Test::Builder';
        require Test::Builder;
        *Test::Builder::share = \&threads::shared::share;
        *Test::Builder::lock = \&threads::shared::lock;
        Test::Builder->new->reset;
    }
}

# Patch Test::Builder to add fork-thread awareness
{
    no warnings 'redefine';
    my $_sanity_check_old = \&Test::Builder::_sanity_check;
    *Test::Builder::_sanity_check = sub {
        my $self = $_[0];
        # Don't bother with an ending if this is a forked copy.  Only the parent
        # should do the ending.
        if( $self->{Original_Pid} != $$ ) {
            return;
        }
        $_sanity_check_old->(@_);
    };
}

package ClassClone;
use threads::shared;
use vars qw(%OBJ);
use Scalar::Util qw(weaken);

sub CLONE { $OBJ->{$_}->{cloned} = 1 foreach keys %OBJ; }
sub new_href { my $o = bless { new => 1 }; $OBJ{$o} = $o; weaken $OBJ{$o}; $o; }
sub new_aref { my $o = bless [5]; $OBJ{$o} = $o; weaken $OBJ{$o}; $o; }
sub new_sref { my $o = bless \(my $s = 10); $OBJ{$o} = $o; weaken $OBJ{$o}; $o; }

package ClassSkipClone;
use threads::shared;

sub CLONE_SKIP { 1 }
sub new_href { bless { new => 1 } }
sub new_aref { bless [5] }
sub new_sref { bless \(my $s = 10) }


package main;

use Test::More tests => 18;
use strict;
use warnings;

sub check_obj {
    my $obj = shift;
    my $type = shift;
    is( ref($obj), $type, "Check that object type is $type" );
    ok( defined($obj), "Check that object type is defined" );
}

# Check that CLONE_SKIP behaves as expected
my %ops = qw/HASH new_href ARRAY new_aref SCALAR new_sref/;
while (my ($type, $new) = each %ops) {
    my $obj = ClassSkipClone->$new();
    check_obj($obj, 'ClassSkipClone');
    threads->create(sub {
        check_obj($obj, $type);
        1;
    })->join();
    check_obj($obj, 'ClassSkipClone');
}

1;
