use Test::More;
use Modern::Perl;
use Util::Medley::Simple::List qw(:all);
use Data::Printer alias => 'pdump';

#####################################
# contains
#####################################

my @list = qw(a b c d);
push @list, undef;

ok(contains(\@list, 'd'));
ok(contains(\@list, qr/^d$/));
ok(contains(\@list, undef));

#####################################
# listToMap
#####################################

my @orig = ( 'a', 'b', 'c' );
my %map  = listToMap(@orig);
ok( keys %map == 3 );
ok( $map{a} == 1 );
ok( $map{b} == 1 );
ok( $map{c} == 1 );

#####################################
# min
#####################################

my $min = min( 7, 4, 99 );
ok( $min == 4 );

#####################################
# nsort
#####################################

@list = qw(0 01 1 1_foobar 1_foobar_1 1foobar);
push @list, qw(10_foobar 10foobar Bizbaz bizbaz Foobar foobar foobar_10);
my @sorted = nsort( shuffle(@list) );
ok( "@sorted" eq "@list" );

#####################################
# undefsToStrings
#####################################

my @have   = ( 'a', 'b', 'c', undef );
my @expect = ( 'a', 'b', 'c', '' );

my $aref = undefsToStrings( \@have );
is_deeply( \@expect, $aref );

#####################################
# uniq
#####################################

@have   = qw(a b c a a d b);
@expect = qw(a b c d);

my @uniq = uniq( \@have );

#####################################
# diff
#####################################

my @diff = diff([qw(1 2 3)], [qw(1 2 3)], 0);
ok(!@diff);

@diff = diff([qw(1 2 3)], [qw(3 2 1)], 1);
ok(!@diff);

@diff = diff([qw(1 2 3)], [qw(a b c)], 0);
ok(@diff == 6);

#####################################
# differ
#####################################

my $differ = differ([qw(1 2 3)], [qw(1 2 3)], 0);
ok(!$differ);

$differ = differ([qw(1 2 3)], [qw(3 2 1)], 1);
ok(!$differ);

$differ = differ([qw(1 2 3)], [qw(a b c)], 0);
ok($differ);

#####################################

done_testing;
