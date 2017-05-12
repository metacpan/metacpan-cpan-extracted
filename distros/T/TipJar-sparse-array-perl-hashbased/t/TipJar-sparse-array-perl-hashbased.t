# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TipJar-sparse-array-perl-hashbased.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { use_ok('TipJar::sparse::array::perl::hashbased') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sparse my @S;
my @A;
# after each transform applied to both arrays, "@A" eq "@S" should be true.
is("@A","@S", "empty");
my @both = (\@S,\@A);
push @$_,"bubblegum" for @both;
is("@A","@S", "push");
unshift @$_, "pink" for @both;
is("@A","@S", "unshift");
${$_}[37] = 'rox', for @both;
my $title;
sub three{
   no warnings;
   is("@S","@A", "$title - interpolated into strings");
   # print "NATIVE: @A\n";
   # print "SPARSE: @S\n";
   is(scalar(@S) ,scalar(@A), "$title - size");
   ok(exists($S[$_]) == exists($A[$_]) , "$title - element $_ existence") for 0 .. $#A;
};
three;
$title = "pop";
pop (@$_) for @both;
three;
$title = "delete";
delete ${$_}[22], for @both;
three;
$title = "set size";
$#$_ = 10, for @both;
three;
$title = "delete again";
delete ${$_}[10], for @both;
three;
$title = "shift result";
is ( (shift @{$both[0]}), (shift @{$both[1]}), "shift result");
three;
$title = "splice with offset outside of array";
splice @$_, 10,2,qw/a b c d/ for @both;
three;
$title = "splice with neg len";
splice @$_, 0,-3,qw/z y x w/ for @both;
three;
$title = "splice with neg len larger than array";
splice @$_, 0,-300,qw/fe fi fo fum/ for @both;
three;
@A = @S = qw/zero one two three four/;
splice @$_, 4,0,qw/five six/ for @both;
$title = "splice with offset exactly at end";
three;
splice @$_, -7 ,0,qw/neg_two neg_one/ for @both;
$title = "splice with negative offset exactly at beginning";
three;
done_testing;

__END__


