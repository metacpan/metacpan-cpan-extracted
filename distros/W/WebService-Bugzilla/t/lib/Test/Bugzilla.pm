#!perl
# ABSTRACT: Mock Bugzilla client for testing — shared fixture data

package Test::Bugzilla;

use Moo;
extends 'WebService::Bugzilla';

has '+allow_http' => (default => 1);

sub _flag_activity_array {
    return [{
        id            => 1,
        bug_id        => 100,
        flag_id       => 42,
        attachment_id => undef,
        creation_time => '2024-01-01',
        status        => '?',
        requestee     => { id => 2, name => 'req@example.com', nick => 'req',
                           real_name => 'Requestee', email => 'req@example.com' },
        setter        => { id => 3, name => 'set@example.com', nick => 'set',
                           real_name => 'Setter', email => 'set@example.com' },
        type          => { id => 800, name => 'review', description => 'Review flag',
                           type => 'bug', is_active => 1,
                           is_multiplicable => 0, is_requesteeble => 1 },
    }];
}

sub get {
    my ($self, $path, $params) = @_;

    if ($path =~ m{bug_user_last_visit/(\d+)$}) {
        return [{ id => 1, bug_id => $1+0, last_visit_ts => '2024-01-01T00:00:00Z' }];
    }
    if ($path eq 'bug_user_last_visit') {
        return [{ id => 1, bug_id => 123, last_visit_ts => '2024-01-01T00:00:00Z' }];
    }

    if ($path =~ m{classification/(\w+)$}) {
        return { classifications => [{ id => $1+0, name => 'MyClassification',
            description => 'A test classification', sort_key => 0,
            products => [{ id => 1, name => 'TestProduct', description => 'A test product' }] }] };
    }

    if ($path =~ m{reminder/(\d+)$}) {
        return { id => $1+0, bug_id => 456, note => 'Test reminder',
            reminder_ts => '2024-06-08', creation_ts => '2024-06-07', sent => 0 };
    }
    if ($path eq 'reminder') {
        return { reminders => [{ id => 1, bug_id => 456, note => 'Test reminder',
            reminder_ts => '2024-06-08', creation_ts => '2024-06-07', sent => 0 }] };
    }

    if ($path =~ m{bug/(\d+)/history$}) {
        return { bugs => [{ id => $1+0, alias => undef, history => [{
            when    => '2024-01-01T00:00:00Z',
            who     => 'dev@example.com',
            changes => [
                { field_name => 'status',         removed => 'NEW',  added => 'ASSIGNED' },
                { field_name => 'flagtypes.name', removed => '',     added => 'review?',
                  attachment_id => 5 },
            ],
        }]}] };
    }

    if ($path =~ m{bug/(\d+)/duplicates$}) {
        return { bugs => [{ id => 999, summary => 'Duplicate', status => 'RESOLVED' }] };
    }

    if ($path =~ m{bug/comment/(\d+)/reactions$}) {
        return { '+1' => [{ id => 2, name => 'dev@example.com',
            nick => 'dev', real_name => 'Developer', email => 'dev@example.com' }] };
    }

    if ($path =~ m{bug/comment/tags/(\w+)$}) {
        return ['spam', 'invalid'];
    }

    if ($path =~ m{bug/comment/(\d+)$}) {
        return { comments => { "$1" => { id => $1+0, bug_id => 123, count => 1,
            text => 'A comment', creator => 'dev@example.com',
            creation_time => '2024-01-01T00:00:00Z', time => '2024-01-01T00:00:00Z',
            is_private => 0, is_markdown => 0, reactions => {}, tags => [] } } };
    }

    if ($path =~ m{bug/(\d+)/comment$}) {
        return { bugs => { "$1" => { comments => [
            { id => 77, bug_id => $1+0, count => 0, text => 'Hello',
              creator => 'dev@example.com', creation_time => '2024-01-01T00:00:00Z',
              time => '2024-01-01T00:00:00Z', is_private => 0, is_markdown => 0,
              reactions => {}, tags => [] }
        ]}} };
    }

    if ($path =~ m{attachment/(\d+)$}) {
        return { attachments => [{ id => $1+0, file_name => 'readme.md',
            bug_id => 123, content_type => 'text/markdown' }] };
    }

    if ($path =~ m{bug/(\d+)/attachment$}) {
        return { bugs => { "$1" => [{ id => 9, file_name => 'readme.md',
            bug_id => $1+0, content_type => 'text/markdown' }] } };
    }

    if ($path =~ m{bug/(\d+)$}) {
        return { bugs => [{ id => $1+0, summary => 'Example', status => 'NEW', product => 'Test' }] };
    }

    if ($path eq 'bug') {
        return { bugs => [{ id => 123, summary => 'Example', status => 'NEW', product => 'Test' }] };
    }

    if ($path =~ m{component/([^/]+)/([^/]+)$}) {
        return { components => [{ id => 50, name => $2,
            product_id => 1, description => 'Test component', is_active => 1 }] };
    }

    if ($path =~ m{field/bug/(\w+)/(\d+)/values$}) {
        return { values => ['P1', 'P2'] };
    }

    if ($path =~ m{field/bug/(\w+)/values$}) {
        return { values => ['P1', 'P2', 'P3'] };
    }

    if ($path =~ m{field/bug/(\w+)$}) {
        return { fields => [{ id => 13, name => $1, display_name => 'Priority',
            type => 2, is_custom => 0, is_mandatory => 0, is_on_bug_entry => 0,
            visibility_field => undef, visibility_values => [], value_field => undef,
            values => [{ name => 'P1', sort_key => 100, visibility_values => [] }] }] };
    }

    if ($path eq 'field/bug') {
        return { fields => [{ id => 13, name => 'priority', display_name => 'Priority',
            type => 2, is_custom => 0, is_mandatory => 0, is_on_bug_entry => 0,
            visibility_field => undef, visibility_values => [], value_field => undef,
            values => [{ name => 'P1', sort_key => 100, visibility_values => [] }] }] };
    }

    if ($path =~ m{review/flag_activity/requestee/([^/]+)$}) {
        return $self->_flag_activity_array();
    }
    if ($path =~ m{review/flag_activity/setter/([^/]+)$}) {
        return $self->_flag_activity_array();
    }
    if ($path =~ m{review/flag_activity/type_id/(\d+)$}) {
        return $self->_flag_activity_array();
    }
    if ($path =~ m{review/flag_activity/type_name/([^/]+)$}) {
        return $self->_flag_activity_array();
    }
    if ($path =~ m{review/flag_activity/(\d+)$}) {
        return $self->_flag_activity_array();
    }
    if ($path eq 'review/flag_activity') {
        return $self->_flag_activity_array();
    }

    if ($path =~ m{group/(\d+)$}) {
        return { groups => [{ id => $1+0, name => 'devs', is_active => 1 }] };
    }

    if ($path eq 'group') {
        return { groups => [{ id => 5, name => 'devs', is_active => 1 }] };
    }

    if ($path =~ m{product/(\d+)$}) {
        return { products => [{ id => $1+0, name => 'Test', is_active => 1 }] };
    }

    if ($path eq 'product') {
        return { products => [{ id => 3, name => 'Test', is_active => 1 }] };
    }

    if ($path eq 'valid_login') {
        return { result => 1 };
    }

    if ($path eq 'whoami') {
        return { id => 7, login => 'developer', name => 'Developer', email => 'dev@example.com' };
    }

    if ($path =~ m{user/(\d+)$}) {
        return { users => [{ id => $1+0, login => 'developer', name => 'Developer',
            email => 'dev@example.com' }] };
    }

    if ($path eq 'user') {
        return { users => [{ id => 7, login => 'developer', name => 'Developer',
            email => 'dev@example.com' }] };
    }

    die "Unexpected GET path: $path";
}

sub post {
    my ($self, $path, $data) = @_;

    if ($path =~ m{bug_user_last_visit/(\d+)$}) {
        return [{ id => 1, bug_id => $1+0, last_visit_ts => '2024-01-02T00:00:00Z' }];
    }

    if ($path eq 'bug_user_last_visit') {
        return [{ id => 1, bug_id => 123, last_visit_ts => '2024-01-02T00:00:00Z' }];
    }

    if ($path =~ m{bug/(\d+)/comment$}) {
        return { id => 500 };
    }

    if ($path eq 'bug/comment/render') {
        return { html => '<p>Hello world</p>' };
    }

    if ($path eq 'component') {
        return { id => 50, %{ $data } };
    }

    if ($path eq 'group') {
        return { id => 30, %{ $data } };
    }

    if ($path eq 'reminder') {
        return { id => 999, bug_id => $data->{bug_id}, note => $data->{note},
            reminder_ts => $data->{reminder_ts}, creation_ts => '2024-06-07', sent => 0 };
    }

    if ($path eq 'bug') {
        return { id => 456, %{ $data } };
    }

    if ($path =~ m{bug/(\d+)/attachment$}) {
        return { ids => [456] };
    }

    if ($path eq 'product') {
        return { id => 10, %{ $data } };
    }

    if ($path eq 'user') {
        return { id => 20, %{ $data } };
    }

    if ($path eq 'login') {
        return { id => 7, token => 'abc123' };
    }

    if ($path eq 'logout') {
        return {};
    }

    die "Unexpected POST path: $path";
}

sub put {
    my ($self, $path, $data) = @_;

    if ($path =~ m{attachment/(\d+)$}) {
        return { attachments => [{ id => $1+0, file_name => 'updated.md',
            bug_id => 123, content_type => 'text/plain' }] };
    }

    if ($path =~ m{bug/comment/(\d+)/reactions$}) {
        return { '+1' => [{ id => 2, name => 'dev@example.com',
            nick => 'dev', real_name => 'Developer', email => 'dev@example.com' }] };
    }

    if ($path =~ m{bug/comment/(\d+)/tags$}) {
        return ['spam'];
    }

    if ($path =~ m{bug/(\d+)$}) {
        return { bugs => [{ id => $1+0, %{ $data } }] };
    }

    if ($path =~ m{component/([^/]+)/([^/]+)$}) {
        return { components => [{ id => 50, name => $2, product_id => 1,
            description => 'Updated', is_active => 1 }] };
    }

    if ($path =~ m{group/(\d+)$}) {
        return { groups => [{ id => $1+0, name => 'updated-devs', is_active => 1 }] };
    }

    if ($path =~ m{product/(\d+)$}) {
        return { products => [{ id => $1+0, name => 'UpdatedProduct', is_active => 1 }] };
    }

    if ($path =~ m{user/(\d+)$}) {
        return { users => [{ id => $1+0, login => 'developer',
            name => 'Developer Updated', email => 'dev@example.com' }] };
    }

    die "Unexpected PUT path: $path";
}

sub delete {
    my ($self, $path) = @_;

    if ($path =~ m{reminder/(\d+)$}) {
        return { success => 1 };
    }

    die "Unexpected DELETE path: $path";
}

1;
