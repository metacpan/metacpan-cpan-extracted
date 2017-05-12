#!perl

use strict;
use warnings;

use Test::More;
use Test::Builder;
use Test::More::Prefix qw/test_prefix/;

if ( $INC{'Test/More/Prefix/TB1.pm'} ) {
    pass("Using ::TB1");
} elsif ( $INC{'Test/More/Prefix/TB2.pm'} ) {
    pass("Using ::TB2");
} else {
    fail("Didn't load either of the TB helper modules?!");
}

# Get the Test Builder singleton
my $tb = Test::Builder->new;

# These are where we'll pipe our test output to
my $note_output = '';
my $diag_output = '';

# Take copies of the default
my $old_note_output = $tb->output;
my $old_diag_output = $tb->failure_output;

# Set our strings to pick up the output
$tb->output( \$note_output );
$tb->failure_output( \$diag_output );

# Generate some output without a prefix
note "No prefix - a";
diag "No prefix - b";

# Generate some output with a prefix
test_prefix("Hi there!");
note "With prefix - c";
diag "With prefix - d";

# Generate some output without a prefix, again
test_prefix(undef);
note "No prefix - e";
diag "No prefix - f";

# Put the old outputs back
$tb->output($old_note_output);
$tb->failure_output($old_diag_output);

# Test we picked up what we were expecting
is(
    $note_output,
    '# No prefix - a
# Hi there!: With prefix - c
# No prefix - e
', "Note msg interception works"
);

is(
    $diag_output,
    '# No prefix - b
# Hi there!: With prefix - d
# No prefix - f
', "Diag msg interception works"
);

done_testing;
