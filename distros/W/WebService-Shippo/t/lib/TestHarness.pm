use strict;
use warnings;

package TestHarness;
use Carp ( 'croak' );
use Data::Dumper::Concise;
use Test::More;
use Test::Deep;
use boolean ':all';
use base ( 'Exporter' );

#<<<
our @EXPORT = ( 
    @Test::More::EXPORT,
    @Test::Deep::EXPORT,
    qw/
    __TEST__
    __STASH__ 
    not_deeply
    stash 
    Dumper 
    dump 
    true
    false
    boolean
/ );
#>>>

our $__TEST__  = undef;
our $__STASH__ = undef;

sub not_deeply
{
    my ( $s1, $s2, $name ) = @_;
    my ( $identical ) = Test::Deep::cmp_details( $s1, $s2 );
    ok( !$identical, $name );
}

# * dump ( LIST )
#   Parameters:
#       LIST - the list of items you want dumped.
#   Return Value:
#       STRING - Data::Dumper::Concise rendition of LIST.
#
# Dumps data in a human-readable format.
#
sub dump
{
    for my $thing ( @_ ) {
        if ( ref $thing ) {
            Test::More::diag( Dumper( $thing ) );
        }
        else {
            Test::More::diag( $thing );
        }
    }

    return @_;
}

# * __TEST__
#   Return Value:
#       STRING - the name of the test currently being executed.
# * __TEST__ (LIST)
#   Parameters:
#       LIST - list of comments that will appear after the name of the test
#           currently being executed.
#   Return Value:
#       STRING - the name of the test currently being executed, together
#           with the comments passed. A colon (:) separates the test's name
#           from the comments.
#
sub __TEST__
{
    # Return the name of the test if no comments were passed
    return $__TEST__ unless @_;
    # Return the name of the test plus comments
    return $__TEST__ . ': ' . join( '', @_ );
}

# * __STASH__
#   Return Value:
#       HASHREF - the structure used by the test as a medium for sharing
#           data with other tests in the same test sequence.
# * __STASH__ (KEY-NAME)
#   Parameters:
#       KEY-NAME - the name of the key for which the value is sought.
#   Return Value:
#       SCALAR - the value associated with the key name.
# * __STASH__ (KEY-VALUES)
#   Parameters:
#       KEY-VALUES - a list of key/value pairs that should be set in the
#           stash.
#   Return Value:
#       HASHREF - the structure used by the test as a medium for sharing
#           data with other tests in the same test sequence.
#
# A place to share data among tests in the same sequence. The "__STASH__"
# symbol also has an alias called "stash".
#
sub __STASH__
{
    return $__STASH__ unless @_;
    return $__STASH__->{ $_[0] } unless @_ > 1;
    while ( @_ ) {
        my $key   = shift;
        my $value = shift;
        $__STASH__->{$key} = $value;
    }
    return $__STASH__;
}

# * INVOCANT->run_tests (TESTS)
# * INVOCANT->run_tests (TESTS, PARENT-NAME, PARENT-STASH)
#   Arguments:
#       TESTS - reference to a array (the test sequence) defined as a list
#           of key/value pairs for which the key is a test's name and the
#           value is a code reference (a test) or an array (another test
#           sequence). Due to their sequential nature test sequences are
#           expressed as arrays instead of hashes.
#       PARENT-NAME - the name of the test that defined this test sequence,
#           usually set by "run_tests" on a recursive call for nested test
#           sequences and combined with the current test's name.
#       PARENT-STASH - the stash used by the test that defined this test
#           sequence, usually set by "run_tests" on a recursive call for
#           nested test sequences and comined with the current test's stash.
#   Return Value:
#       INVOCANT - the same entity used to invoke the method.
#
# Executes a sequence of tests.
#
sub run_tests
{
    my ( $invocant, $tests, $parent_name, $parent_stash ) = @_;
    my @tests = @{$tests};
    croak 'Odd number of elements in test array'
        if @tests % 2;
    local $__STASH__ = $parent_stash ? {%$parent_stash} : {};
    local $__TEST__;
    while ( @tests ) {
        my $test_name = shift @tests;
        my $test      = shift @tests;
        $__TEST__ = $parent_name ? "$parent_name.$test_name" : $test_name;
        if ( ref( $test ) eq 'ARRAY' ) {
            $invocant->run_tests( $test, $__TEST__, $__STASH__ );
        }
        else {
            $test->();
        }
    }
    return $invocant;
}

BEGIN {
    no warnings 'once';
    *stash = *__STASH__;
}
1;
