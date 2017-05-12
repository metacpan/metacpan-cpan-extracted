use Thread::Tie; # use as first to get maximum effect
use strict;
use warnings;

BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 71;

use_ok( 'Thread::Tie::Thread' );
can_ok( 'Thread::Tie::Thread',qw(
 new
 thread
 tid
) );

use_ok( 'Thread::Tie' );
can_ok( 'Thread::Tie',qw(
 module
 semaphore
 TIESCALAR
 TIEARRAY
 TIEHASH
 TIEHANDLE
 thread
) );

#== SCALAR =========================================================

my $tied = tie my $scalar, 'Thread::Tie',{},10;
isa_ok( $tied,'Thread::Tie',		'check tied object type' );

isa_ok( $tied->thread,'Thread::Tie::Thread','check thread object type' );
cmp_ok( $tied->thread->tid,'==',1,	'check tid of thread' );
isa_ok( $tied->thread->thread,'threads','check thread object type' );
isa_ok( $tied->semaphore,'SCALAR',	'check semaphore type' );

cmp_ok( $scalar,'==',10,		'check scalar numerical fetch' );
$scalar++;
cmp_ok( $scalar,'==',11,		'check scalar increment' );
$scalar = 'Apenootjes';
is( $scalar,'Apenootjes',		'check scalar fetch' );

threads->new( sub {$scalar = 'from thread'} )->join;
is( $scalar,'from thread',		'check scalar fetch' );

#== ARRAY ==========================================================

$tied = tie my @array, 'Thread::Tie',{},qw(a b c);
isa_ok( $tied,'Thread::Tie',		'check tied object type' );
is( "@array",'a b c',			'check array fetch' );

push( @array,qw(d e f) );
is( "@array",'a b c d e f',		'check array fetch' );

threads->new( sub {push( @array,qw(g h i) )} )->join;
is( "@array",'a b c d e f g h i',	'check array fetch' );

shift( @array );
is( "@array",'b c d e f g h i',		'check array fetch' );

unshift( @array,'a' );
is( "@array",'a b c d e f g h i',	'check array fetch' );

pop( @array );
is( "@array",'a b c d e f g h',		'check array fetch' );

push( @array,'i' );
is( "@array",'a b c d e f g h i',	'check array fetch' );

splice( @array,3,3 );
is( "@array",'a b c g h i',		'check array fetch' );

splice( @array,3,0,qw(d e f) );
is( "@array",'a b c d e f g h i',	'check array fetch' );

splice( @array,0,3,qw(d e f) );
is( "@array",'d e f d e f g h i',	'check array fetch' );

delete( $array[0] );
{no warnings 'uninitialized';
 is( "@array",' e f d e f g h i',	'check array fetch' );
}

@array = qw(a b c d e f g h i);
is( join('',@array),'abcdefghi',	'check array fetch' );

cmp_ok( $#array,'==',8,			'check size' );
ok( exists( $array[8] ),		'check whether array element exists' );
ok( !exists( $array[9] ),		'check whether array element exists' );

$#array = 10;
cmp_ok( scalar(@array),'==',11,		'check number of elements' );
{no warnings 'uninitialized';
 is( "@array",'a b c d e f g h i  ',	'check array fetch' );
}

ok( !exists( $array[10] ),		'check whether array element exists' );
$array[10] = undef;
ok( exists( $array[10] ),		'check whether array element exists' );

ok( !exists( $array[11] ),		'check whether array element exists' );
ok( !defined( $array[10] ),		'check whether array element defined' );
ok( !defined( $array[11] ),		'check whether array element defined' );
cmp_ok( scalar(@array),'==',11,		'check number of elements' );

@array = ();
cmp_ok( scalar(@array),'==',0,		'check number of elements' );
is( join('',@array),'',			'check array fetch' );

#== HASH ===========================================================

$tied = tie my %hash, 'Thread::Tie',{},(a => 'A');
isa_ok( $tied,'Thread::Tie',		'check tied object type' );
is( $hash{'a'},'A',			'check hash fetch' );

$hash{'b'} = 'B';
is( $hash{'b'},'B',			'check hash fetch' );

is( join('',sort keys %hash),'ab',	'check hash keys' );

ok( !exists( $hash{'c'} ),		'check existence of key' );
threads->new( sub { $hash{'c'} = 'C' } )->join;
ok( exists( $hash{'c'} ),		'check existence of key' );
is( $hash{'c'},'C',			'check hash fetch' );

is( join('',sort keys %hash),'abc',	'check hash keys' );

my %otherhash = %hash;
is( join('',sort keys %otherhash),'abc','check hash keys' );

my @list;
while (my ($key,$value) = each %hash) { push( @list,$key,$value ) }
is( join('',sort @list),'ABCabc',	'check all eaches' );

delete( $hash{'b'} ); # attempt to free unreferenced scalar ?
is( join('',sort keys %hash),'ac',	'check hash keys' );

%hash = ();
cmp_ok( scalar(keys %hash),'==',0,	'check number of elements' );
is( join('',keys %hash),'',		'check hash fetch' );

#== HANDLE =========================================================

my $file = 'testfile';
ok( open( my $handle,'>',$file ),	'check opening of file' );

my $text = <<EOD;
This is some text
over multiple lines
that will be read
by a shared handle.
EOD
ok( (print $handle $text),		'check printing to file' );
ok( close( $handle ),			'close the file' );

tie *HANDLE,'Thread::Tie',{},'<',$file;
isa_ok( $tied,'Thread::Tie',		'check tied object type' );

my $read;
$read .= $_ while <HANDLE>;
is( $read,$text,			'check contents of file' );
ok( close( HANDLE ),			'close the file' );

ok( open( HANDLE,">$file" ),		'check opening of file' );
ok( (print HANDLE $text),		'check printing to the file' );
ok( (printf HANDLE '%s',$text),		'check printing to the file' );
ok( close( HANDLE ),			'close the file' );

ok( open( $handle,$file ),		'check opening of file' );
$read = '';
$read.= $_ while <$handle>;
is( $read,$text.$text,			'check contents of file' );

ok( unlink( $file ),			"unlink $file" );
1 while unlink $file; # multiversioned filesystems

my @thread = threads->list;
cmp_ok( scalar(@thread),'==',1,         'check number of threads' );
Thread::Tie->shutdown;
@thread = threads->list;
cmp_ok( scalar(@thread),'==',0,         'check number of threads' );

eval{ $scalar = 'a' };
is( $@,"Cannot handle Thread::Tie::Scalar::STORE after shutdown\n",
 'check error message' );

eval{ @array = ('a') };
is( $@,"Cannot handle Thread::Tie::Array::CLEAR after shutdown\n",
 'check error message' );

eval{ %hash = (a => 'A') };
is( $@,"Cannot handle Thread::Tie::Hash::CLEAR after shutdown\n",
 'check error message' );

eval{ readline( HANDLE ) };
is( $@,"Cannot handle Thread::Tie::Handle::READLINE after shutdown\n",
 'check error message' );
