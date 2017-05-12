use strict;
use warnings;

use File::Spec;

# Yes, the size of this file is actually encoded within it.  If you
# change this file in any shape or form (including version control
# tags!!), this number must reflect it.  (If the number proves too
# much trouble, I'll nuke the test).  Also, don't be surprised if
# other clever tests know about this particular variable declaration
# and twiddle it.
my $this_file_size = "02108";
my $loaded;

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded };

my @SAVE_INC;
BEGIN { @SAVE_INC = @INC; }

use Unix::MyPathToInc;
$loaded = 1;
print "ok 1\n";

# Prove that the code nominally does something, and that we seem to find
# "ourselves".
sub test_ourself {
    my $test_no = shift;
    my $dir_adjust = shift;

    if((@SAVE_INC + 1) != @INC) {
	print "not ok $test_no\n";
    } elsif(! -x "$INC[0]/$dir_adjust/test.pl" ) {
	print "not ok $test_no\n";
    } elsif(((stat("$INC[0]/$dir_adjust/test.pl"))[7]) != $this_file_size) {
	print "not ok $test_no\n";
    } else {
	print "ok $test_no\n";
    }
}

# Shortcut that works, for now.
my $test_counter = 2;
sub test {
    test_ourself($test_counter++, $_[0]);
}

test(".");

# As we know our own interface, it's easy enough to call ourselves
# more than once to test different ways of getting here.  Note that
# we're making foolish assumptions about what MakeMaker will write for
# output paths.

# Test our ability to include a directory other than .
@INC = @SAVE_INC;
Unix::MyPathToInc->import("blib");
test("..");

# Importing / should name ., rather than say, the filesystem root.
@INC = @SAVE_INC;
Unix::MyPathToInc->import("/");
test(".");

# Fully qualified.  Note that we depend on $0 being unqualified.
@INC = @SAVE_INC;
{
    local $0 = File::Spec->abs2rel($0);
  Unix::MyPathToInc->import();
    test(".");
}

chdir("blib") || die "chdir: $!";

# Search PATH
@INC = @SAVE_INC;
{
    local $ENV{PATH} = "$ENV{PATH}:..";
  Unix::MyPathToInc->import();
    test(".");
}

@INC = @SAVE_INC;
# Relative directory
{
    local $0 = "../$0";
  Unix::MyPathToInc->import();
    test(".");
}
