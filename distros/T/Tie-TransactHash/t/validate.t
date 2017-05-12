#!./perl -w

=head1 check validation function works

This just does some changes, commits them and then runs the verify_write
function.  When more complex validation is available it might do that too.

=cut
print "1..1\n";

use Tie::TransactHash;

sub ok { print "ok ", shift, "\n" }
sub nok { print "not ok ", shift, "\n" }

%::originalhash = (
	fred => "hi there",
	jim => "yo",
	john => "greetings",
	jenny => "howdy",
	ellen => "F***",
	andy => "howsitgoing",
);

$::edit_object=tie %::edit_hash, "Tie::TransactHash", \%::originalhash;

$::edit_hash{"fred"} = "hi there"; #okay, not really a change
$::edit_hash{"jim" } = "haven't I seen you around here someplace before?";
$::edit_hash{"ellen"} = "Hello, person who I'm not entriely pleased to see.";

$::edit_object->commit();

if ($::edit_object->verify_write() ) { ok 1 } else { nok 1 }

