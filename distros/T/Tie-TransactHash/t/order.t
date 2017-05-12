#!./perl -w

=head1 tests for order

Various tests to check that the edit hash keeps the order of the
original hash protected

=cut
print "1..2\n";

use Tie::TransactHash;

sub ok { print "ok ", shift, "\n" }
sub nok { print "not ok ", shift, "\n" }

sub array_compare {
    $array_one=shift;
    $array_two=shift;
    return 0 unless #$array_one = #$array_two;
    @temparray=@$array_two;
    my ($first, $second);
    foreach $first (@$array_one) {
	$second=shift @temparray;
	return 0 unless $first=$second;
    }
    return 1;
}

%::originalhash = (
	fred => "hi there",
	jim => "yo",
	john => "greetings",
	jenny => "howdy",
	ellen => "F***",
	andy => "howsitgoing",
);

@order=keys(%::originalhash);

$::edit_object=tie %::edit_hash, "Tie::TransactHash", \%::originalhash;

=head2 Check for altering elements

We change some elements in the hash

=cut

$::edit_hash{"fred"} = "hi there"; #okay, not really a change
$::edit_hash{"jim" } = "haven't I seen you around here someplace before?";
$::edit_hash{"ellen"} = "Hello, person who I'm not entriely pleased to see.";

if (array_compare( [keys(%::edit_hash)], [@order] ) ) { ok 1 } else { nok 1 }

=head2

Check for adding some elements.  These should go at the end and not
cause any problems.

=cut

$::edit_hash{"johnny"} = "here's johnny";

if (array_compare( [keys (%::edit_hash)], [(@order, "johnny")] ) ) 
     { ok 2 } 
else { nok 2 }

$::edit_object=undef; #shh..
