package Test::WWW::PivotalTracker;

use strict;
use warnings;

use base qw(Test::Class);

use Sub::Override;
use Test::Most;

sub make_fixture : Test(setup => 1)
{
    my $self = shift;

    use_ok('WWW::PivotalTracker');

    $self->{'override'} = Sub::Override->new(
        'WWW::PivotalTracker::_post_request' => sub($$) {
            die "You should override _post_request, so you're not depending on PivotalTracker being available.";
        }
    );
}

sub TEST__IS_ONE_OF : Test(4)
{
    is(
        WWW::PivotalTracker->_is_one_of('foo', [qw/ foo /]),
        1,
        "foo is in [qw/ foo /]",
    );

    is(
        WWW::PivotalTracker->_is_one_of('bar', [qw/ foo /]),
        0,
        "bar is not in [qw/ foo /]",
    );

    is(
        WWW::PivotalTracker->_is_one_of('foo', [qw/ bar baz foo qux /]),
        1,
        "Find element, even if it's not the first one in the list.",
    );

    is(
        WWW::PivotalTracker->_is_one_of('cheese', [qw/ bar baz foo qux /]),
        0,
        "Doesn't find element, even if there's more than one element in the list.",
    );
}

sub TEST__CHECK_PROJECT_ID : Test(3)
{
    is(
        WWW::PivotalTracker->_check_project_id(1234),
        1,
        "'1234' is a valid project id",
    );

    is(
        WWW::PivotalTracker->_check_project_id('12a34'),
        0,
        "'12a34' is not a valid project id",
    );

    is(
        WWW::PivotalTracker->_check_project_id('a'),
        0,
        "'a' is not a valid project id",
    );
}

sub TEST__CHECK_STORY_ID : Test(3)
{
    is(
        WWW::PivotalTracker->_check_story_id(1234),
        1,
        "'1234' is a valid story id",
    );

    is(
        WWW::PivotalTracker->_check_story_id('12a34'),
        0,
        "'12a34' is not a valid story id",
    );

    is(
        WWW::PivotalTracker->_check_story_id('a'),
        0,
        "'a' is not a valid story id",
    );
}

sub TEST__DO_REQUEST__ARRAYIFIES_ELEMENTS_THAT_COULD_APPEAR_MORE_THAN_ONCE : Test(4)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) {
            return <<"            HERE";
<?xml version="1.0" encoding="UTF-8"?>
<response success="true">
  <story>
    <id type="integer">320532</id>
    <story_type>release</story_type>
    <url>https://www.pivotaltracker.com/story/show/320532</url>
    <estimate type="integer">-1</estimate>
    <current_state>unscheduled</current_state>
    <description></description>
    <name>Release 1</name>
    <requested_by>Jacob Helwig</requested_by>
    <created_at>Dec 20, 2008</created_at>
    <deadline>Dec 31, 2008</deadline>
    <notes type="array">
      <note>
        <id type="integer">209033</id>
        <text>Comment!</text>
        <author>Jacob Helwig</author>
        <noted_at type="datetime">Dec 20, 2008</noted_at>
      </note>
    </notes>
    <labels>needs feedback</labels>
  </story>
</response>
            HERE
        }
    );

    my $response = WWW::PivotalTracker->_do_request('token', 'some/place', 'GET');

    ok(defined $response);

    isa_ok(
        $response->{'story'},
        'ARRAY',
        '$response->{story}',
    );

    isa_ok(
        $response->{'story'}->[0]->{'notes'}->{'note'},
        'ARRAY',
        '$response->{story}->[0]->{notes}->{note}',
    );
}

sub TEST__SANITIZE_STORY_XML : Test(4)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) {
            return <<"            HERE";
<?xml version="1.0" encoding="UTF-8"?>
<story>
  <id type="integer">320532</id>
  <story_type>release</story_type>
  <url>https://www.pivotaltracker.com/story/show/320532</url>
  <estimate type="integer">-1</estimate>
  <current_state>unscheduled</current_state>
  <description></description>
  <name>Release 1</name>
  <requested_by>Jacob Helwig</requested_by>
  <created_at type="datetime">Dec 20, 2008</created_at>
  <deadline type="datetime">Dec 31, 2008</deadline>
  <notes type="array">
    <note>
      <id type="integer">209033</id>
      <text>Comment!</text>
      <author>Jacob Helwig</author>
      <noted_at type="datetime">Dec 20, 2008</noted_at>
    </note>
  </notes>
  <labels>needs feedback</labels>
</story>
            HERE
        }
    );

    my $response = WWW::PivotalTracker->_do_request('c0ffe', 'request/goes/here', 'GET');
    isa_ok($response, 'HASH', '_do_request return value');

    eq_or_diff(
        $response,
        {
            created_at    => {
                type    => 'datetime',
                content => 'Dec 20, 2008',
            },
            current_state => 'unscheduled',
            deadline      => {
                type    => 'datetime',
                content => 'Dec 31, 2008',
            },
            description   => undef,
            estimate      => { type => 'integer', content => '-1', },
            id            => { type => 'integer', content => '320532', },
            name          => 'Release 1',
            requested_by  => 'Jacob Helwig',
            story_type    => 'release',
            url           => 'https://www.pivotaltracker.com/story/show/320532',
            labels        => 'needs feedback',
            notes         => {
                type => 'array',
                note => [{
                    author   => 'Jacob Helwig',
                    noted_at => {
                        type    => 'datetime',
                        content => 'Dec 20, 2008',
                    },
                    id       => { type => 'integer', content => '209033', },
                    text     => 'Comment!',
                }],
            },
        },
        '$response ok',
    );

    my $sanitized_response = WWW::PivotalTracker->_sanitize_story_xml($response);
    isa_ok($sanitized_response, 'HASH', '_sanitize_story_xml return value');

    eq_or_diff(
        $sanitized_response,
        {
            accepted_at   => undef,
            created_at    => 'Dec 20, 2008',
            current_state => 'unscheduled',
            deadline      => 'Dec 31, 2008',
            description   => undef,
            estimate      => '-1',
            id            => '320532',
            labels        => [ 'needs feedback', ],
            name          => 'Release 1',
            requested_by  => 'Jacob Helwig',
            owned_by      => undef,
            story_type    => 'release',
            url           => 'https://www.pivotaltracker.com/story/show/320532',
            notes => [{
                author => 'Jacob Helwig',
                date   => 'Dec 20, 2008',
                id     => '209033',
                text   => 'Comment!',
            }],
        },
        '$sanitized_response ok',
    );
}

sub TEST_PROJECT_DETAILS__BASE_CASE : Test(3)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) {
            return <<"            HERE";
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <name>Sample Project</name>
  <iteration_length type="integer">2</iteration_length>
  <week_start_day>Monday</week_start_day>
  <point_scale>0,1,2,3</point_scale>
</project>
            HERE
        }
    );

    use_ok('WWW::PivotalTracker', qw/ project_details /);

    my $response = project_details('c0ffe', 1);

    isa_ok($response, 'HASH', 'project_details return value');

    eq_or_diff(
        $response,
        {
            success         => 'true',
            iteration_weeks => '2',
            name            => 'Sample Project',
            point_scale     => '0,1,2,3',
            start_day       => 'Monday',
        },
        "project_details response ok"
    );
}

sub TEST_PROJECT_DETAILS__HANDLES_WHEN_SUCCESS_IS_NOT_TRUE : Test(3)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) { die }
    );

    use_ok('WWW::PivotalTracker', qw/ project_details /);

    my $response = project_details('c0ffe', 1);

    isa_ok($response, 'HASH', 'project_details return value');

    eq_or_diff(
        $response,
        { success => 'false' },
        "project_details response ok"
    );
}

sub TEST_SHOW_STORY__BASE_CASE : Test(3)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) {
            return <<"            HERE";
<?xml version="1.0" encoding="UTF-8"?>
<story>
  <id type="integer">320532</id>
  <story_type>release</story_type>
  <url>https://www.pivotaltracker.com/story/show/320532</url>
  <estimate type="integer">-1</estimate>
  <current_state>unscheduled</current_state>
  <description></description>
  <name>Release 1</name>
  <requested_by>Jacob Helwig</requested_by>
  <created_at type="datetime">Dec 20, 2008</created_at>
  <deadline type="datetime">Dec 31, 2008</deadline>
  <notes type="array">
    <note>
      <id type="integer">209033</id>
      <text>Comment!</text>
      <author>Jacob Helwig</author>
      <noted_at type="datetime">Dec 20, 2008</noted_at>
    </note>
  </notes>
  <labels>needs feedback</labels>
</story>
            HERE
        }
    );

    use_ok('WWW::PivotalTracker', qw/ show_story /);

    my $response = show_story('c0ffe', 1, 320532);
    isa_ok($response, 'HASH', 'show_story return value');

    eq_or_diff(
        $response,
        {
            success       => 'true',
            accepted_at   => undef,
            created_at    => 'Dec 20, 2008',
            current_state => 'unscheduled',
            deadline      => 'Dec 31, 2008',
            description   => undef,
            estimate      => '-1',
            id            => '320532',
            labels        => [ 'needs feedback', ],
            name          => 'Release 1',
            requested_by  => 'Jacob Helwig',
            owned_by      => undef,
            story_type    => 'release',
            url           => 'https://www.pivotaltracker.com/story/show/320532',
            notes => [{
                author => 'Jacob Helwig',
                date   => 'Dec 20, 2008',
                id     => '209033',
                text   => 'Comment!',
            }],
        },
        'show_story ok',
    );
}

sub TEST_SHOW_STORY__HANDLES_WHEN_SUCCESS_IS_NOT_TRUE : Test(3)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) { die }
    );

    use_ok('WWW::PivotalTracker', qw/ show_story /);

    my $response = show_story('c0ffe', 1, 320532);
    isa_ok($response, 'HASH', 'show_story return value');

    eq_or_diff(
        $response,
        { success => 'false' },
        'show_story ok',
    );
}

sub TEST_ALL_STORIES__BASE_CASE : Test(3)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) {
            return <<"            HERE";
<?xml version="1.0" encoding="UTF-8"?>
<stories type="array" count="2" total="2">
  <story>
    <id type="integer">320532</id>
    <story_type>release</story_type>
    <url>https://www.pivotaltracker.com/story/show/320532</url>
    <estimate type="integer">-1</estimate>
    <current_state>unscheduled</current_state>
    <description></description>
    <name>Release 1</name>
    <requested_by>Jacob Helwig</requested_by>
    <created_at type="datetime">Dec 20, 2008</created_at>
    <deadline type="datetime">Dec 31, 2008</deadline>
    <notes type="array">
      <note>
        <id type="integer">209033</id>
        <text>Comment!</text>
        <author>Jacob Helwig</author>
        <noted_at type="datetime">Dec 20, 2008</noted_at>
      </note>
      <note>
        <id type="integer">209034</id>
        <text>Another comment!</text>
        <author>Jacob Helwig</author>
        <noted_at type="datetime">Dec 20, 2008</noted_at>
      </note>
    </notes>
  </story>
  <story>
    <id type="integer">320008</id>
    <story_type>feature</story_type>
    <url>https://www.pivotaltracker.com/story/show/320008</url>
    <estimate type="integer">-1</estimate>
    <current_state>unscheduled</current_state>
    <description></description>
    <name>Story!</name>
    <requested_by>Jacob Helwig</requested_by>
    <created_at type="datetime">Dec 20, 2008</created_at>
    <labels>needs feedback</labels>
  </story>
</stories>
            HERE
        }
    );

    use_ok('WWW::PivotalTracker', qw/ all_stories /);

    my $response = all_stories('c0ffe', 1);
    isa_ok($response, 'HASH', 'all_stories return value');

    eq_or_diff(
        $response,
        {
            success => 'true',
            stories => [
                {
                    accepted_at   => undef,
                    created_at    => 'Dec 20, 2008',
                    current_state => 'unscheduled',
                    deadline      => 'Dec 31, 2008',
                    description   => undef,
                    estimate      => '-1',
                    id            => '320532',
                    labels        => undef,
                    name          => 'Release 1',
                    requested_by  => 'Jacob Helwig',
                    owned_by      => undef,
                    story_type    => 'release',
                    url           => 'https://www.pivotaltracker.com/story/show/320532',
                    notes => [
                    {
                        author => 'Jacob Helwig',
                        date   => 'Dec 20, 2008',
                        id     => '209033',
                        text   => 'Comment!'
                    },
                    {
                        author => 'Jacob Helwig',
                        date   => 'Dec 20, 2008',
                        id     => '209034',
                        text   => 'Another comment!'
                    }
                    ],
                },
                {
                    accepted_at   => undef,
                    created_at    => 'Dec 20, 2008',
                    current_state => 'unscheduled',
                    deadline      => undef,
                    description   => undef,
                    estimate      => '-1',
                    id            => '320008',
                    name          => 'Story!',
                    notes         => undef,
                    requested_by  => 'Jacob Helwig',
                    owned_by      => undef,
                    story_type    => 'feature',
                    url           => 'https://www.pivotaltracker.com/story/show/320008',
                    labels => [
                    'needs feedback'
                    ],
                }
            ],
        },
        'all_stories ok',
    );
}

sub TEST_ALL_STORIES__HANDLES_WHEN_SUCCESS_IS_NOT_TRUE : Test(3)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) { die }
    );

    use_ok('WWW::PivotalTracker', qw/ all_stories /);

    my $response = all_stories('c0ffe', 1);
    isa_ok($response, 'HASH', 'show_story return value');

    eq_or_diff(
        $response,
        { success => 'false' },
        'show_story ok',
    );
}

sub TEST_STORIES_FOR_FILTER__URL_ENCODES_FILTER : Test(2)
{
    my $self = shift;

    my $query_string;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_do_request' => sub($$$$;$) {
            $query_string = $_[2];

            return {
                success => 'false',
                errors  => [ 'Dummy Data', ],
            };
        }
    );

    use_ok('WWW::PivotalTracker', qw/ stories_for_filter /);

    my $response = stories_for_filter('c0ffe', 1, 'This should be URL <Encoded>');

    eq_or_diff($query_string, "projects/1/stories?filter=This%20should%20be%20URL%20%3CEncoded%3E", "stories_for_filter URL encodes filter");
}

sub TEST_STORIES_FOR_FILTER__SANITIZES_STORY_XML : Test(3)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) {
            return <<"            HERE";
<?xml version="1.0" encoding="UTF-8"?>
<stories type="array" count="2" total="2" filter="requested_by:'Jacob Helwig'">
<story>
  <id type="integer">320532</id>
  <story_type>release</story_type>
  <url>https://www.pivotaltracker.com/story/show/320532</url>
  <estimate type="integer">-1</estimate>
  <current_state>unscheduled</current_state>
  <description></description>
  <name>Release 1</name>
  <requested_by>Jacob Helwig</requested_by>
  <created_at type="datetime">Dec 20, 2008</created_at>
  <deadline type="datetime">Dec 31, 2008</deadline>
  <notes type="array">
    <note>
      <id type="integer">209033</id>
      <text>Comment!</text>
      <author>Jacob Helwig</author>
      <noted_at type="datetime">Dec 20, 2008</noted_at>
    </note>
    <note>
      <id type="integer">209034</id>
      <text>Another comment!</text>
      <author>Jacob Helwig</author>
      <noted_at type="datetime">Dec 20, 2008</noted_at>
    </note>
  </notes>
</story>
<story>
  <id type="integer">320008</id>
  <story_type>feature</story_type>
  <url>https://www.pivotaltracker.com/story/show/320008</url>
  <estimate type="integer">-1</estimate>
  <current_state>unscheduled</current_state>
  <description></description>
  <name>Story!</name>
  <requested_by>Jacob Helwig</requested_by>
  <created_at type="datetime">Dec 20, 2008</created_at>
  <labels>needs feedback</labels>
</story>
</stories>
            HERE
        }
    );

    use_ok('WWW::PivotalTracker', qw/ stories_for_filter /);

    my $response = stories_for_filter('c0ffe', 1, 'requested_by:"Jacob Helwig"');
    isa_ok($response, 'HASH', 'stories_for_filter return value');

    eq_or_diff(
        $response,
        {
            filter => q{requested_by:'Jacob Helwig'},
            success => 'true',
            stories => [
                {
                    accepted_at   => undef,
                    created_at    => 'Dec 20, 2008',
                    current_state => 'unscheduled',
                    deadline      => 'Dec 31, 2008',
                    description   => undef,
                    estimate      => '-1',
                    id            => '320532',
                    labels        => undef,
                    name          => 'Release 1',
                    requested_by  => 'Jacob Helwig',
                    owned_by      => undef,
                    story_type    => 'release',
                    url           => 'https://www.pivotaltracker.com/story/show/320532',
                    notes => [
                    {
                        author => 'Jacob Helwig',
                        date   => 'Dec 20, 2008',
                        id     => '209033',
                        text   => 'Comment!'
                    },
                    {
                        author => 'Jacob Helwig',
                        date   => 'Dec 20, 2008',
                        id     => '209034',
                        text   => 'Another comment!'
                    }
                    ],
                },
                {
                    accepted_at   => undef,
                    created_at    => 'Dec 20, 2008',
                    current_state => 'unscheduled',
                    deadline      => undef,
                    description   => undef,
                    estimate      => '-1',
                    id            => '320008',
                    name          => 'Story!',
                    notes         => undef,
                    requested_by  => 'Jacob Helwig',
                    owned_by      => undef,
                    story_type    => 'feature',
                    url           => 'https://www.pivotaltracker.com/story/show/320008',
                    labels => [
                    'needs feedback'
                    ],
                }
            ],
        },
        'stories_for_filter sanitized story XML ok',
    );
}

sub TEST_UPDATE_STORY__BASE_CASE : Test(3)
{
    my $self = shift;

    my $request_content;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) {
            return <<"            HERE";
<?xml version="1.0" encoding="UTF-8"?>
<story>
  <id type="integer">320532</id>
  <story_type>release</story_type>
  <url>https://www.pivotaltracker.com/story/show/320532</url>
  <estimate type="integer">-1</estimate>
  <current_state>unscheduled</current_state>
  <description></description>
  <name>Release 1</name>
  <requested_by>Jacob Helwig</requested_by>
  <created_at type="datetime">Dec 20, 2008</created_at>
  <deadline type="datetime">Dec 31, 2008</deadline>
  <notes type="array">
    <note>
      <id type="integer">209033</id>
      <text>Comment!</text>
      <author>Jacob Helwig</author>
      <noted_at type="datetime">Dec 20, 2008</noted_at>
    </note>
  </notes>
  <labels>needs feedback</labels>
</story>
            HERE
        }
    );

    use_ok('WWW::PivotalTracker', qw/ show_story /);

    my $response = show_story('c0ffe', 1, 320532);
    isa_ok($response, 'HASH', 'show_story return value');

    eq_or_diff(
        $response,
        {
            success       => 'true',
            accepted_at   => undef,
            created_at    => 'Dec 20, 2008',
            current_state => 'unscheduled',
            deadline      => 'Dec 31, 2008',
            description   => undef,
            estimate      => '-1',
            id            => '320532',
            labels        => [ 'needs feedback', ],
            name          => 'Release 1',
            requested_by  => 'Jacob Helwig',
            owned_by      => undef,
            story_type    => 'release',
            url           => 'https://www.pivotaltracker.com/story/show/320532',
            notes => [{
                author => 'Jacob Helwig',
                date   => 'Dec 20, 2008',
                id     => '209033',
                text   => 'Comment!',
            }],
        },
        'show_story ok',
    );
}

sub TEST_UPDATE_STORY__HANDLES_WHEN_SUCCESS_IS_NOT_TRUE : Test(3)
{
    my $self = shift;

    $self->{'override'}->replace(
        'WWW::PivotalTracker::_post_request' => sub($$) { die; }
    );

    use_ok('WWW::PivotalTracker', qw/ update_story /);

    my $response = update_story('c0ffe', 1, 320532);
    isa_ok($response, 'HASH', 'update_story return value');

    eq_or_diff(
        $response,
        { success => 'false' },
        'update_story ok',
    );
}

sub teardown : Test(teardown)
{
    my $self = shift;

    $self->{'override'} = undef;
}

1;
