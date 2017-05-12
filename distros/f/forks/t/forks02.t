#!/usr/local/bin/perl -T -w
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, ('../blib/lib', '../blib/arch');
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

use forks; # must be done _before_ Test::More which loads real threads.pm
use forks::shared;

my $times = 100;

diag( <<EOD );

The following tests are a stress test for shared arrays and shared hashes
that may take a few minutes on slower machines.

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

use Test::More tests => 6;

#= ARRAY ==============================================================

{
my @array : shared;
my $tied = tied( @array );
isa_ok( $tied,'threads::shared',    'check object type' );

my @thread;
my $count : shared;
$count  = 0;
#warn "lock = ".(\&lock)."\n";
push( @thread,threads->new( sub {
    while (1) {
        {lock( $count );
         return if $count == $times;
         $count++;
         push( @array,0+$count );
        }
    }
} ) ) foreach 1..10;
$_->join foreach @thread;

my $check;
$check .= $_ foreach 1..$times;
is( join('',@array),$check,     'check array contents' );

pop( @array ) foreach 1..$times;
is( join('',@array),'',         'check array contents' );
}

#= HASH ===============================================================

{
my %hash : shared;
my $tied = tied( %hash );
isa_ok( $tied,'threads::shared',    'check object type' );

my @thread;
my $count : shared;
$count = 0;
my $sub = sub {
    while (1) {
        {lock( $count );
         return if $count == $times;
         $count++;
         $hash{$count} = $count;
        }
    }
};
foreach (1..10) {
    my $thread = threads->new( $sub );
    push @thread,$thread;
}
$_->join foreach @thread;

my $check;
$check .= ($_.$_) foreach 1..$times;
my $hash;
$hash .= ($_.$hash{$_}) foreach (sort {$a <=> $b} keys %hash);
is( $hash,$check,           'check hash contents' );

delete( $hash{$_} ) foreach 1..$times;
is( join('',%hash),'',          'check hash contents' );
}

#======================================================================

1;
