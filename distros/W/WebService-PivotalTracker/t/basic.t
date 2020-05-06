use strict;
use warnings;

use lib 't/lib';

use Secret ();
use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;
use Test::LWP::UserAgent ();
use Test::UA qw( ua );

use WebService::PivotalTracker;

my $pt;
is(
    dies {
        $pt = WebService::PivotalTracker->new(
            token => 'e99a18c428cb38d5f260853678922e03',
            ua    => ua(),
        );
    },
    undef,
    'made a new WebService::PivotalTracker object'
);

isa_ok(
    $pt->_client,
    'WebService::PivotalTracker::Client',
);

my $story = $pt->story( story_id => 120292647 );
is(
    $story,
    object {
        call id            => 120292647;
        call project_id    => 557367;
        call name          => 'Do a thing!';
        call description   => 'We want to do a thing.';
        call story_type    => 'feature';
        call current_state => 'unscheduled';
        call estimate      => undef;
        call accepted_at   => undef;
        call deadline      => undef;
        call requested_by  => object {
            call name => 'Darth Vader';
        };
        call requested_by_id => 670657;
        call owner_ids       => [];
        call task_ids        => [];
        call follower_ids    => [];
        call created_at      => object {
            call iso8601 => '2016-05-25T16:10:06';
        };
        call updated_at => object {
            call iso8601 => '2016-05-25T16:10:06';
        };
        call url => object {
            call canonical =>
                'https://www.pivotaltracker.com/story/show/120292647';
        };
        call kind => 'story';
    },
    'got expected object'
);

my $token = 'e99a18c428cb38d5f260853678922e03';
my @tests = (
    {
        description => 'string token',
        token       => $token,
    },
    {
        description => 'object token',
        token       => Secret->new($token),
    },
);
for my $test (@tests) {
    subtest $test->{description} => sub {
        my $ua = Test::LWP::UserAgent->new;
        $ua->map_response(
            sub {
                my $request = shift;
                return $request->header('X-TrackerToken') eq $token;
            },
            HTTP::Response->new('500'),
        );

        like(
            dies {
                WebService::PivotalTracker->new(
                    token => $test->{token},
                    ua    => $ua,
                )->story( story_id => 120292647 );
            },
            qr/Internal Server Error/,
            'hit correct code path',
        );
    };
}

my $ex = dies {
    WebService::PivotalTracker->new(
        token => 'foo',
    );
};
like(
    $ex,
    qr/token does not stringify/,
    'invalid token is rejected and is not in exception',
);
unlike( $ex, qr/\Q$token/, 'token itself is not in the exception' );

done_testing();
