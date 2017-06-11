package WebService::Moodle::Simple;

use 5.008_005;
our $VERSION = '0.05';
use namespace::clean;

use HTTP::Request;
use JSON;
use List::Util qw/first/;
use LWP::UserAgent;
use Moo;
use Ouch;
use URI;
use Sys::SigAction qw( timeout_call );


# ABSTRACT: API client for Stripe


my $REST_FORMAT = 'json';
# https://moodle.org/mod/forum/discuss.php?d=340377
my $STUDENT_ROLE_ID = 5;

# the base domain like moodle.example.com
has domain => (
    is => 'ro',
);

# name of the moodle external service
has target => (
    is      => 'ro',
);

has token => (
    is      => 'ro',
);

has port => (
    is      => 'ro',
    default => 443,
);

has timeout => (
    is      => 'ro',
    default => 1000,
);

has scheme => (
    is      => 'rw',
    default => 'https',
);



sub dns_uri {
    my $self = shift;
    return URI->new($self->scheme.'://'.$self->domain.':'.$self->port);
}

sub rest_call {
    my ($self, $dns_uri) = @_;

    my $timeout = $self->timeout + 1;

    my $res;

    if ( timeout_call( $timeout,
        sub {
            my $req = HTTP::Request->new (GET => $dns_uri);
            $req->content_type('application/json');

            my $lwp = LWP::UserAgent->new;
            $lwp->timeout($timeout);
            $res = $lwp->request( $req );
        }
    )) {
            ouch 408, 'Timeout: no response from '.$self->domain;
    }

    unless ($res->is_success) {
        ouch $res->code, $res->message;
    }

    return $res;
}


sub set_password {
    my $self = shift;
    my %args = (
        username   => undef,
        password   => undef,
        @_
    );

    my $username = lc($args{username});

    my $params = {
        'wstoken'                      => $self->token,
        'wsfunction'                   => "core_user_update_users",
        'moodlewsrestformat'           => $REST_FORMAT,
        'users[0][id]'                 => $self->get_user(username => $username )->{id},
        'users[0][password]'           => $args{password},
    };


    my $dns_uri = $self->dns_uri;
    $dns_uri->path('webservice/rest/server.php');
    $dns_uri->query_form( $params );

    my $res = $self->rest_call($dns_uri);

    return { ok => $res->is_success };
}



sub add_user {
    my $self = shift;
    my %args = (
        firstname => undef,
        lastname  => undef,
        email     => undef,
        username  => undef,
        password  => undef,
        @_
    );


    my $username = lc($args{username});

    my $params = {
        'wstoken'                      => $self->token,
        'wsfunction'                   => "core_user_create_users",
        'moodlewsrestformat'           => $REST_FORMAT,
        'users[0][username]'           => $username,
        'users[0][email]'              => $args{email},
        'users[0][firstname]'          => $args{firstname},
        'users[0][lastname]'           => $args{lastname},
        'users[0][password]'           => $args{password},
    };


    my $dns_uri = $self->dns_uri;
    $dns_uri->path('webservice/rest/server.php');
    $dns_uri->query_form( $params );

    my $res = $self->rest_call($dns_uri);

    my $response = from_json($res->content);

    unless (ref($response) eq 'ARRAY') {
        return { ok => 0, msg => $response->{debuginfo} };
    }


    return { ok => 1, %{$response->[0]} }
}

sub get_user {
    my $self = shift;
    my %args = (
        username  => undef,
        @_
    );


    my $username = lc($args{username});

    my $params = {
        'wstoken'                      => $self->token,
        'wsfunction'                   => "core_user_get_users_by_field",
        'moodlewsrestformat'           => $REST_FORMAT,
        'field'                        => 'username',
        'values[0]'                    => $username,
    };


    my $dns_uri = $self->dns_uri;
    $dns_uri->path('webservice/rest/server.php');
    $dns_uri->query_form( $params );

    my $res = $self->rest_call($dns_uri);

    my $dat = from_json($res->content);
    unless ($dat && ref($dat) eq 'ARRAY' && scalar(@$dat)) {
        return;
    }
    return $dat->[0];
}


sub enrol_student {
    my $self = shift;
    my %args = (
        username   => undef,
        course    => undef,
        @_
    );

    my $user = $self->get_user(
        username => $args{username}
    );
    return { ok => undef, msg => "Invalid user $args{username}" } unless $user;

    my $user_id = $user->{id};

    my $params = {
        'wstoken'                      => $self->token,
        'wsfunction'                   => "enrol_manual_enrol_users",
        'moodlewsrestformat'           => $REST_FORMAT,
        'enrolments[0][roleid]'        => $STUDENT_ROLE_ID,
        'enrolments[0][userid]'        => $user_id,
        'enrolments[0][courseid]'      => $self->get_course_id (  short_cname => $args{course} ),
    };


    my $dns_uri = $self->dns_uri;
    $dns_uri->path('webservice/rest/server.php');
    $dns_uri->query_form( $params );

    my $res = $self->rest_call($dns_uri);
    unless ($res->is_success) {
        ouch $res->code, $res->message;
    }

    return { ok => 1, msg => "$args{username} enrolled in $args{course}" } if ($res->content eq 'null');
    return { ok => undef, msg => from_json($res->content)->{message} };
}

sub get_course_id {
    my $self = shift;
    my %args = (
        short_cname => undef,
        @_
    );

    my $dns_uri = $self->dns_uri;
    $dns_uri->path('webservice/rest/server.php');
    $dns_uri->query_form( {
        wstoken            =>  $self->token,
        wsfunction         => 'core_course_get_courses',
        moodlewsrestformat => $REST_FORMAT,
    } );

    my $res = $self->rest_call($dns_uri);
    my $ra_courses = from_json($res->content);
    foreach my $rh_course (@$ra_courses) {
        if ($rh_course->{shortname} eq $args{short_cname}) {
            return $rh_course->{id};
        }
    }

    ouch 'MSE-0002', 'failed to find course of name '.$args{short_cname};
}


# NOTE: suspend_user depends on the 'suspended' parameter
# https://tracker.moodle.org/browse/MDL-31465

sub suspend_user {
    my $self = shift;
    my %args = (
        username => undef,
        suspend  => 1, # suspend unless it is 0
        @_
    );

    my $mdl_user = $self->get_user( username => $args{username} );

    my $params = {
        'wstoken'                      => $self->token,
        'wsfunction'                   => "core_user_update_users",
        'moodlewsrestformat'           => $REST_FORMAT,
        'users[0][id]'                 => $mdl_user->{id},
        'users[0][suspended]'          => $args{suspend} + 0,
    };


    my $dns_uri = $self->dns_uri;
    $dns_uri->path('webservice/rest/server.php');
    $dns_uri->query_form( $params );

    $self->rest_call($dns_uri);

    return;
}


sub check_password  {
    my $self = shift;
    my %args = (
        username => undef,
        password => undef,
        @_
    );

    my $username = $args{username};
    my $password = $args{password};

    my $params = {
        'username'   => $args{username},
        'password'   => $args{password},
        'service'    => 'moodle_mobile_app',
    };


    my $dns_uri = $self->dns_uri;
    $dns_uri->path('login/token.php');
    $dns_uri->query_form( $params );

    my $res = $self->rest_call($dns_uri);

    my $content = $res->content;

    my $data;
    eval {
        $data = from_json($res->content);
    };
    if ($@){
        return {
            msg => "'$username' login failed",
            ok  => 0,
        };
    }

    if ( $data->{token} ) {
        return {
            msg => "'$username' has the correct password",
            ok  => 1,
        };
    }

    return {
        msg => "'$username' login failed, error code: ".$data->{errorcode},
        ok  => 0,
    };

}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

WebService::Moodle::Simple - API client for Stripe

=head1 VERSION

version 0.06

=head1 SYNOPSIS

=head2 CLI

    ./bin/moodlews --help

Example

    $ ./bin/moodlews add_user -u freddy -f Fred -l Flintstone -e freddy09@example.com -o 0123456789abcdef -p ff1234 -d moodle.example.com -t local_wssetup

    { id => 57, ok => 1, username => "freddy09" }

=head2 API

  use WebService::Moodle::Simple;

  my $moodle = WebService::Moodle::Simple->new(
    domain   => 'moodle.example.edu',
    port     => 80,                  # default 443
    timeout  => 100,                 # default 1000
    scheme   => 'http',              # default 'https'
    target   => 'example_webservice'
    token    => '0123456789abcdef',
  );

=head1 DESCRIPTION

WebService::Moodle::Simple is Client API and CLI for Moodle Web Services

__THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE__.

=head1 NAME

WebService::Moodle::Simple - Client API and CLI for Moodle Web Services

=head1 USAGE

=head2 CLI

Get instructions on CLI usage

  moodlews

=head2 Example - Login and Get Users

Retrieve the user list using the token

  moodlews get_users -o becac8d120119eb2a312a385644eb709 -d moodle.example.edu -t example_webservice

=head2 Unit Tests

  prove -rlv t

=head3 Full Unit Tests

    TEST_WSMS_SCHEME=https \
    TEST_WSMS_PORT=443 \
    TEST_WSMS_DOMAIN=moodle.example.com \
    TEST_WSMS_TARGET=example_webservice \
    TEST_WSMS_TOKEN=0123456789abcdef \
    TEST_WSMS_COURSE=example-short-course-name \
    prove -rlv t/

__NOTE: Full unit tests write to Moodle Database - only run them against a test Moodle server__.

=head2 Methods

=over 4

=item * add_user

    $OBJ->add_user(
        firstname => <str>,
        lastname  => <str>,
        email     => <str>,
        username  => <str>,
        password  => <str>,
        token     => <str>,
    );

On failure, returns a hashref of the form

    {
        ok  => 0,
        msg => <str>,
    }

or

    {
        ok       => 1,
        id       => <int>,
        username => <str>,
    }

=item * check_password

    $OBJ->check_password(
        username => <str>,
        password => <str>,
    )

Returns

     { msg => <str>, ok => <bool> }

=item * set_password

    $OBJ->set_password(
        username => <str>,
        password => <str>,
    )

Returns

    { ok => <bool> }

=item * get_user

    $OBJ->get_user(
        username => <str>,
    )

Returns

    {
        username  => <str>,
        id        => <int>,
        suspended => <JSON::PP::Boolean>,
        ...
    }

=item * enrol_student

    $OBJ->enrol_student(
      username  => <str>,
      course    => <str>,
    )

Returns

    { ok => <bool>, msg => <str> }

=item * get_course_id

    $OBJ->get_course_id(
        short_cname  => <str>,
    )

Returns an integer

=item * suspend_user

    $OBJ->suspend_user(
        username => <str>,
        suspend  => <bool default TRUE>
    )

Always returns undef

If suspend is true/nonzero (which is the default) it kills the user's session
and suspends their account preventing them from logging in. If suspend is false
they are given permission to login.

=back

=head1 AUTHOR

Andrew Solomon E<lt>andrew@geekuni.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Andrew Solomon

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=head1 AUTHOR

Andrew Solomon

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Copyright 2014- Andrew Solomon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
