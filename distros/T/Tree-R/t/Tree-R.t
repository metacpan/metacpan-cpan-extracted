# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tree-R.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
use vars qw/$warning/;
BEGIN { 
    use_ok('Tree::R');
    $SIG{__WARN__} = sub {  $warning = "@_"; }
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
    my $rtree = Tree::R->new;
    eval {
        $rtree->query_point();
    };
    ok($warning eq '', "Empty tree should not issue any warnings (rt.cpan.org 57055).");
}

my %objects = (
	       1 => [2,4,4,7],
	       2 => [3,2,7,6],
	       3 => [6,3,9,5],
	       4 => [6,8,9,10],
	       5 => [10,7,13,9]
	       );

my $rtree = new Tree::R m=>2,M=>3;

for my $object (keys %objects) {
    my @bbox = @{$objects{$object}}; # (minx,miny,maxx,maxy)
    $rtree->insert($object,@bbox);
}

for (1..2) {
    my @point = (6.5,4); # (x,y)
    my @results;
    $rtree->query_point(@point,\@results);
    
    my @test = sort @results;
    ok("@test" eq "2 3", "query_point $_");
    
    my @rect = (5,0,11,11); # (minx,miny,maxx,maxy)
    @results = ();
    $rtree->query_completely_within_rect(@rect,\@results);
    
    @test = sort @results;
    ok("@test" eq "3 4", "query_completely_within_rect $_");
    
    @results = ();
    $rtree->query_partly_within_rect(@rect,\@results);
    
    @test = sort @results;
    ok("@test" eq "2 3 4 5", "query_partly_within_rect $_");
    
    $rtree->remove(3);
    $rtree->insert(3,@{$objects{3}});   
}

$rtree = new Tree::R m=>2,M=>3;

for my $object (keys %objects) {
    my @bbox = @{$objects{$object}}; # (minx,miny,maxx,maxy)
    $rtree->insert($object,@bbox);
}

for my $object (keys %objects) {

    my @o1;
    $rtree->objects(\@o1);
    @o1 = sort @o1;

    $rtree->remove($object);

    $rtree->insert($object,@{$objects{$object}});

    my @o2;
    $rtree->objects(\@o2);
    @o2 = sort @o2;

    is_deeply(\@o1, \@o2, 'remove and insert');

}

# Tests	from Brandon Forehand:

my $r_tree = Tree::R->new();

isa_ok($r_tree, 'Tree::R');

my $rects = {
    1 => [0, 0, 10, 20],
    2 => [20, 0, 10, 20],
    3 => [0, 30, 10, 20],
    4 => [20, 30, 10, 20],
};

for my $rect (keys %$rects) {
    $r_tree->insert($rect, @{$rects->{$rect}});
}

{
    my @objects;
    $r_tree->objects(\@objects);

    is(scalar(@objects), 4);
}

for my $rect (keys %$rects) {
    $r_tree->remove($rect);
}

{
    my @objects;
    $r_tree->objects(\@objects);

    is(scalar(@objects), 0);
}

$r_tree->insert($rects->{1}, @{$rects->{1}});
{
    my @objects;
    $r_tree->objects(\@objects);

    is(scalar(@objects), 1);
}
