use strict;
use warnings;

use Test::More;
use Function::Parameters;
use v5.10;

BEGIN {
    use_ok('Moo');
    use_ok('WebService::Gitter');
    use_ok( 'LWP::Online', 'online' );
    use_ok('WebService::Client');
    use_ok('Function::Parameters');
}

my $true  = 1;
my $false = 0;

# change $false to $true if you want to do advanced test
my $DEVELOPER_TESTING = $false;

SKIP:
{
    skip "developer testing", 1 unless $DEVELOPER_TESTING;

    ok(
        my $git = WebService::Gitter->new(
            api_key => $ENV{GITTER_KEY}
        )
    );

  SKIP:
    {
        skip "No internet connection", 1 unless online();

        cmp_ok(
            'github', 'eq',
            $git->get_me->{providers}[0],
            "Retrieve authenticated user's authentication provider."
        );

        fun is_uri_exist($uri) {
            return 0 if not $uri;

            return 1
              if $uri eq 'private-only'
              or $uri eq 'FreeCodeCamp'
              or $uri eq 'share-your-project';
        }

        my $group_id = '5880e37ad73408ce4f44a189';
        ok(
            is_uri_exist( $git->list_groups->[1]{uri} ),
            "Retrieve authenticated user's group URI."
        );

        my $room_id = '5a561773d73408ce4f8765fe';
        cmp_ok( $git->rooms_under_group($room_id)->[0]{userCount},
            '==', 1, 'Retrieve private-only room total members count.' );

        cmp_ok( $git->rooms->[14]{url},
            'eq', '/QuincyLarson', 'Retrieve particular room url.' );

        cmp_ok(
            $git->rooms( q => 'QuincyLarson' )->{results}[0]{url},
            'eq',
            '/QuincyLarson/TwitchTV',
            'Retrieve particular room url with query parameter option.'
        );

        my $ujango_room_response =
          $git->room_from_uri( uri => 'private-only/ujango' );
        cmp_ok( $ujango_room_response->{id},
            'eq', '5a5b8818d73408ce4f882f9d',
            'room_from_uri ujango room ID matched.' );

        my $authenticated_user_id = '584ab515d73408ce4f3be368';
        cmp_ok(
            $git->join_room( $ujango_room_response->{id},
                $authenticated_user_id )->{userCount},
            '==', 1,
            'Join private-only/ujango room.'
        );

        cmp_ok(
            $git->update_room(
                $ujango_room_response->{id},
                topic => 'Topic changed.',
                tags  => 'perl5, perl6, perl7'
            )->{topic},
            'eq',
            'Topic changed.',
            "Matching updated room topic."
        );

        cmp_ok(
            $git->remove_user_from_room( $ujango_room_response->{id},
                $git->get_me->{id} )->{success},
            '==', '1',
            'Leave private-only/ujango room.'
        );

# delete room test skipped because it needs manual setting to be done correctly.

        my $room_id2 = '5880e3b6d73408ce4f44a1aa';
        cmp_ok(
            $git->room_users( $room_id2, q => 'faraco' )->[0]{id},
            'eq',
            $authenticated_user_id,
            'Retrieve authenticated user ID with room_users.'
        );

        like(
            $git->list_messages( $room_id2, q => 'faraco' )->[0]{id},
            qr/^[0-9a-z]+$/,
            'Check if particular user ID matched the regex from list_messages.'
        );

        my $message_id = '591444f733e9ee771c96b8ca';
        cmp_ok(
            $git->single_message( $room_id2, $message_id )->{text},
            'eq',
            '@faraco Thanks, feel free to make a PR;)',
            'Check if message is same with single_message.'
        );

        # Avoid spamming the room. Only do this manually.
        #my $send_response =
        #  $git->send_message( $room_id2, text => 'Hello world3' );
        #cmp_ok( $send_response->{text},
        #    'eq', 'Hello world3', 'Check if send_message is working.' );

        # Avoid spamming the room. Only do this manually.
        #cmp_ok(
        #    $git->update_message(
        #        $room_id2,
        #        $send_response->{id},
        #        text => 'Hello world3 is changed to Hi!'
        #    )->{text},
        #    'eq',
        #    'Hello world3 is changed to Hi!',
        #    'Update previous sent message.'
        #);
    }
}

done_testing;
