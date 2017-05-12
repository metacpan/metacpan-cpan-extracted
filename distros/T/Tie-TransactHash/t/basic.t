#!./perl -w

=head1 tests for transacthash

These are the tests for standard transacthash functionality overlayed
on a normal in memory hash

=cut
print "1..3\n";

use Tie::TransactHash;

sub ok { print "ok ", shift, "\n" }
sub nok { print "not ok ", shift, "\n" }

=head2 Test for read write to hash

We test to see that if we put something into the hash it is recorded
there.

=cut
$::t=1;

%::originalhash=();
$::edit_object=tie %::edit_hash, "Tie::TransactHash", \%::originalhash;

$::edit_hash{"fred"} = "hi there";

if ($::edit_hash{"fred"} eq "hi there") { ok $::t } else { nok $::t }

=head2 Test for protected underlying hash

We test to see that if we put something into the hash it is not passed
through to the underlying hash.

=cut
$::t=2;

unless (defined $::originalhash{"fred"}) { ok $::t } else { nok $::t }

=head2 Test for commit on destruct

=cut
$::t=3;

$::edit_object=undef; #must untie afterwards, not before..
untie %::edit_hash;

if ($::originalhash{"fred"} eq "hi there") { ok $::t } else { nok $::t }
