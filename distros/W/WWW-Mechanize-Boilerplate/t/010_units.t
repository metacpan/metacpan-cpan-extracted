#!perl

use strict;
use warnings;
use Test::More;
use Test::Differences;
use Test::MockObject;

# Basic unit-tests for the interface
use_ok('WWW::Mechanize::Boilerplate');

# We'll start by testing the ->indent_note() method, as it's going to be a
# little fiddly to knock out Test::More's note() method beyond that. Once we've
# checked it works, we'll knock it itself out and replace it with something we
# can easily use for capturing test output
{
    my @notes;
    no warnings 'redefine';
    local *Test::More::note = sub {
        my $note = shift;
        push( @notes, $note );
    };

    WWW::Mechanize::Boilerplate->indent_note('Quick', 0);
    WWW::Mechanize::Boilerplate->indent_note('Brown', 1);
    WWW::Mechanize::Boilerplate->indent_note('Fox',   2);
    WWW::Mechanize::Boilerplate->indent_note("Jumps\nOver", 3);

    eq_or_diff( \@notes, [
        "\tQuick", "\t\tBrown", "\t\t\tFox", "\t\t\t\tJumps\n\t\t\t\tOver"
    ], "indent_note seems to work");
}

# OK, now we know indent_note works properly, let's knock it out for something
# useful for us testing
my @notes;
{
    no warnings qw/redefine once/;
    *WWW::Mechanize::Boilerplate::indent_note = sub {
        my ( $class, $note ) = @_;
        push( @notes, $note );
    }
}

# Start with show_method_name. We don't want to be too closely tied to the
# underlying serialization mechanism, so we'll do a light-touch check...
my @method_args = qw/foo bar baz ban/;
WWW::Mechanize::Boilerplate->show_method_name( 'mname', { @method_args } );
is( scalar @notes, 1, "show_method_name adds one note" );

my $method_note = shift( @notes );
note "Returned: $method_note";
like( $method_note, qr/$_/, " ... and it contains $_") for @method_args;

# Test note_status...
my $mech = Test::MockObject->new();
$mech->set_isa('WWW::Mechanize');

my $client = WWW::Mechanize::Boilerplate->new({
    mech => $mech
});

# Pretend it worked
$mech->set_true( 'success' );
$client->note_status;

# Pretend it failed
$mech->set_false( 'success' );
$client->note_status;

# Check the right stuff showed up in the notes
is( scalar @notes, 2, "Two notes generated" );
like( $notes[0], qr/true/,  "mech success is true for first note" );
like( $notes[1], qr/false/, "mech success is false for second note");

# Test the location assertion
{
    # Make the failed location assertion just return 0 instead of croaking
    no warnings qw/redefine once/;
    local *WWW::Mechanize::Boilerplate::assert_location_failed = sub { return 0; };

    # Set up a ->uri method for the mech
    my $uri = Test::MockObject->new();
    $mech->set_always( uri => $uri );

    for my $test (
        { uri => 'http://foo/bar', assert => 'http://foo/bar', expect => 'pass' },
        { uri => 'http://foo/bar', assert => 'http://bar/foo', expect => 'fail' },
        { uri => 'http://foo/bar', assert => qr/foo/, expect => 'pass' },
        { uri => 'http://foo/bar', assert => qr/oof/, expect => 'fail' },
    ) {
        $uri->set_always( path_query => $test->{'uri'} );
        my $result = $client->assert_location( $test->{'assert'} );
        is( $result, ( $test->{'expect'} eq 'pass' ? 1 : 0 ),
            sprintf("Assert location [%s] on [%s] should [%s]",
                @$test{qw/assert uri expect/} ) );
    }
}

done_testing();
