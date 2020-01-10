use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::List;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $list = Util::Medley::List->new;
ok($list);

#####################################
# listToMap
#####################################

my @orig = ( 'a', 'b', 'c' );
my %map  = $list->listToMap(@orig);
ok( keys %map == 3 );
ok( $map{a} == 1 );
ok( $map{b} == 1 );
ok( $map{c} == 1 );

#####################################
# min
#####################################

my $min = $list->min( 7, 4, 99 );
ok( $min == 4 );

#####################################
# nsort
#####################################

my @list = qw(0 01 1 1_foobar 1_foobar_1 1foobar);
push @list, qw(10_foobar 10foobar Bizbaz bizbaz Foobar foobar foobar_10);
my @sorted = $list->nsort( $list->shuffle(@list) );
ok( "@sorted" eq "@list" );

#####################################
# undefsToStrings
#####################################

my @have   = ( 'a', 'b', 'c', undef );
my @expect = ( 'a', 'b', 'c', '' );

my $aref = $list->undefsToStrings( \@have );
is( \@expect, $aref );

#####################################
# uniq
#####################################

@have   = qw(a b c a a d b);
@expect = qw(a b c d);

my @uniq = $list->uniq( \@have );

#####################################
# diff
#####################################

my @diff = $list->diff([qw(1 2 3)], [qw(1 2 3)], 0);
ok(!@diff);

@diff = $list->diff([qw(1 2 3)], [qw(3 2 1)], 1);
ok(!@diff);

@diff = $list->diff([qw(1 2 3)], [qw(a b c)], 0);
ok(@diff == 6);

#####################################
# differ
#####################################

my $differ = $list->differ([qw(1 2 3)], [qw(1 2 3)], 0);
ok(!$differ);

$differ = $list->differ([qw(1 2 3)], [qw(3 2 1)], 1);
ok(!$differ);

$differ = $list->differ([qw(1 2 3)], [qw(a b c)], 0);
ok($differ);

#####################################

done_testing;
