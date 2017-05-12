use Thread::Tie; # use as first to get maximum effect
use strict;
use warnings;

BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 26;

use_ok( 'Thread::Tie' );

my $times = 10000;
my $testfile = 'testfile';

#= ARRAY ==============================================================

{
my $tied = tie my @array,'Thread::Tie';
isa_ok( $tied,'Thread::Tie',		'check object type' );

my $count = $tied->semaphore;
isa_ok( $count,'SCALAR',		'check object type' );
$$count = 0; # to prevent warnings

my @thread;
push( @thread,threads->new( sub {
    while (1) {
        {lock ($count);
         return if $$count == $times;
         push( @array,++$$count );
        }
    }
} ) ) foreach 1..10;
$_->join foreach @thread;

my $check;
$check = join( ' ',1..$times );
is( "@array",$check,			'check array contents' );

pop( @array ) foreach 1..$times;
is( "@array",'',			'check array contents' );

untie( @array );
}

#= HASH ===============================================================

{
my $tied = tie my %hash,'Thread::Tie';
isa_ok( $tied,'Thread::Tie',		'check object type' );

my $count = $tied->semaphore;
isa_ok( $count,'SCALAR',		'check object type' );
$$count = 0; # to prevent warnings

my @thread;
push( @thread,threads->new( sub {
    while (1) {
        {lock ($count);
         return if $$count == $times;
         $$count++;
         $hash{$$count} = $$count;
        }
    }
} ) ) foreach 1..10;
$_->join foreach @thread;

my $check;
$check .= ($_.$_) foreach 1..$times;
my $hash;
$hash .= ($_.$hash{$_}) foreach (sort {$a <=> $b} keys %hash);
is( $hash,$check,			'check hash contents' );

delete( $hash{$_} ) foreach 1..$times; # attempt to free unreferenced scalar
is( join('',%hash),'',			'check hash contents' );

untie( %hash );
}

#= HANDLE (output) ====================================================

{
my $tied = tie *HANDLE,'Thread::Tie';
isa_ok( $tied,'Thread::Tie',		'check object type' );

my $count = $tied->semaphore;
isa_ok( $count,'SCALAR',		'check object type' );
$$count = 0; # to prevent warnings

ok( open( HANDLE,">$testfile" ),	'check opening of file' );

my @thread;
push( @thread,threads->new( sub {
    while (1) {
        {lock ($count);
         return if $$count == $times;
         $$count++;
         print HANDLE $$count;
        }
    }
} ) ) foreach 1..10;
$_->join foreach @thread;

ok( close( HANDLE ),			'check closing of handle' );

my $check;
$check .= $_ foreach 1..$times;
ok( open( my $handle,'<',$testfile ),	'check opening of file' );
is( <$handle>,$check,			'check file contents' );
ok( close( $handle ),			'check closing of handle' );

ok( unlink( $testfile ),		'check removing of file' );
1 while unlink $testfile; # multiversioned filesystems

untie( *HANDLE );
}

#= HANDLE (input) =====================================================

{
ok( open( my $handle,'>',$testfile ),	'check opening of file' );
my $check;
foreach (1..$times) {
    $check .= "$_\n";
    print $handle "$_\n";
}
ok( close( $handle ),			'check closing of handle' );

my $tied = tie *HANDLE,'Thread::Tie';
isa_ok( $tied,'Thread::Tie',		'check object type' );

my $count = $tied->semaphore;
isa_ok( $count,'SCALAR',		'check object type' );
$$count = 0; # to prevent warnings

ok( open( HANDLE,'<',$testfile ),	'check opening of file' );

my @check : shared;
my @thread;
push( @thread,threads->new( sub {
    while (1) {
        {lock ($count);
         return if $$count == $times;
         $$count++;
	 my $line = <HANDLE>;
	 push( @check,$line );
        }
    }
} ) ) foreach 1..10;
$_->join foreach @thread;

ok( close( HANDLE ),			'check closing of handle' );

is( join('',@check),$check,		'check file contents' );

ok( unlink( $testfile ),		'check removing of file' );
1 while unlink $testfile; # multiversioned filesystems

untie( *HANDLE );
}

my @thread = threads->list;
cmp_ok( scalar(@thread),'==',1,		'check number of threads' );
