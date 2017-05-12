# Check that there are no uncommitted changes and we are on the master
# branch before releasing to CPAN.

use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Perl::Build::Git ':all';
ok (no_uncommited_changes ($Bin), "no uncommited changes");
ok (branch_is_master ($Bin), "branch is master");
done_testing ();
