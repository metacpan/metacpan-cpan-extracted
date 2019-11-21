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

my @orig = ('a', 'b', 'c');
my %map = $list->listToMap(@orig);
ok(keys %map == 3);
ok($map{a} == 1);
ok($map{b} == 1);
ok($map{c} == 1);

#####################################
# min
#####################################

my $min = $list->min(7, 4, 99);
ok($min == 4);

#####################################
# nsort
#####################################

my @sorted = $list->nsort(qw(foobar bizbaz Foobar Bizbaz));

ok($sorted[0] eq 'bizbaz');
ok($sorted[1] eq 'Bizbaz');
ok($sorted[2] eq 'foobar');
ok($sorted[3] eq 'Foobar');

#####################################
# undefsToStrings
#####################################

my @have = ('a', 'b', 'c', undef);
my @expect = ('a', 'b', 'c', '');

my $aref = $list->undefsToStrings(\@have);
is(\@expect, $aref);

#####################################
# uniq
#####################################

@have = qw(a b c a a d b);
@expect = qw(a b c d);

my @uniq = $list->uniq(\@have);


done_testing;
