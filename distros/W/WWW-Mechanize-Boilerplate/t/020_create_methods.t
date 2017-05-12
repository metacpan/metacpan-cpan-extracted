#!perl

use strict;
use warnings;

use Test::More;
use Test::MockObject;
use WWW::Mechanize::Boilerplate;

# Happy-path tests for method creation

# Set up to capture all diagnostic output
our @notes;
{
    no warnings qw/redefine once/;
    *WWW::Mechanize::Boilerplate::indent_note = sub {
        my ( $class, $note ) = @_;
        push( @notes, $note );
    }
}

# Set up a fake mech, and instantiate a new client
my $mech = Test::MockObject->new();
$mech->set_isa('WWW::Mechanize');

my $client = WWW::Mechanize::Boilerplate->new({ mech => $mech });

my $uri = Test::MockObject->new();
$uri->set_always( path_query => '/foo/bar' );
$mech->set_always( uri => $uri ); # General URI method
$mech->set_always( url => 'http://www.wired.com/' ); # Used for find_link


# Capture stuff sent to various mechanize methods
our @mech_actions;
sub add_action { my $type = shift; my $class = shift; push( @mech_actions, [$type, @_] ) }
for (qw/get success form_name form_id set_fields submit_form find_link flag/) {
    my $method = $_;
    $mech->mock( $method => sub { add_action($method, @_); return $mech } );
}

# Test cases
for my $test (
    {
        description => "Simplest fetch method",
        method      => {
            type             => 'fetch',
            call_with        => [],
            page_description => 'some page',
            page_url         => 'http://foo/bar'
        },
        expected    => {
            actions => [
                [ get => 'http://foo/bar' ],
                [ 'success' ]
            ]
        }
    },
    {
        description => "Parameterized fetch method",
        method      => {
            type             => 'fetch',
            call_with        => ['roomba'],
            page_description => 'some page',
            page_url         => 'http://foo/bar?zoomba=',
            required_param   => 'zoomba'
        },
        expected    => {
            actions => [
                [ get => 'http://foo/bar?zoomba=roomba' ],
                [ 'success' ]
            ]
        }
    },
    {
        description => "Simple form method",
        method      => {
            type             => 'form',
            call_with        => [{ foo => 'bar' }],
            form_name        => sub {'boom'},
            form_description => 'doom',
            assert_location  => '/foo/bar',
            transform_fields => sub { return $_[1] }
        },
        expected    => {
            actions => [
                [ form_name  => 'boom' ],
                [ set_fields => foo => 'bar' ],
                [ submit_form => fields => { foo => 'bar' } ],
                [ 'success' ]
            ]
        }
    },
    {
        description => "Form via id",
        method      => {
            type             => 'form',
            call_with        => [{ foo => 'bar' }],
            form_id          => 'boom',
            form_description => 'doom',
            assert_location  => '/foo/bar',
            transform_fields => sub { return $_[1] }
        },
        expected    => {
            actions => [
                [ form_id    => 'boom' ],
                [ set_fields => foo => 'bar' ],
                [ submit_form => fields => { foo => 'bar' } ],
                [ 'success' ]
            ]
        }
    },
    {
        description => "Simple link method",
        method      => {
            type             => 'link',
            call_with        => [],
            assert_location  => '/foo/bar',
            link_description => 'somelink',
            find_link        => { boom => 'bang' }
        },
        expected    => {
            actions => [
                [ find_link  => boom => 'bang' ],
                [ get        => 'http://www.wired.com/' ],
                [ 'success' ]
            ]
        }
    },
    {
        description => "Simple custom method",
        method      => {
            type             => 'custom',
            call_with        => [],
            handler          => sub { $_[0]->mech->flag },
        },
        expected    => {
            actions => [
                [ 'flag'    ],
                [ 'success' ]
            ]
        }
    },
) {
    # Localize our capture vars
    local @notes;
    local @mech_actions;

    # Generate a sensible method name
    my $type = delete $test->{'method'}->{'type'};
    my $args = delete $test->{'method'}->{'call_with'};
    my $method_name = sprintf('test_%s_%s', $type, ($test + 0) );

    # Create the method
    my $create_method = "create_${type}_method";
    $client->$create_method(
        method_name => $method_name,
        %{ $test->{'method'} }
    );

    # Execute it
    $client->$method_name( @$args );

    # Check the output
    is_deeply( \@mech_actions, $test->{'expected'}->{'actions'},
        "Output steps matched for: " . $test->{'description'} );
}

done_testing();