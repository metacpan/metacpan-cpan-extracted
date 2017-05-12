package WebService::Moodle::Simple;

use 5.008_005;
our $VERSION = '0.05';

use Moo;
use namespace::clean;
use URI;
use HTTP::Request;
use LWP::UserAgent;
use Sys::SigAction qw( timeout_call );
use JSON;
use Ouch;
use List::Util qw/first/;

my $REST_FORMAT = 'json';
# https://moodle.org/mod/forum/discuss.php?d=340377
my $STUDENT_ROLE_ID = 5;

# the base domain like moodle.example.com
has domain => (
  is => 'ro',
);

has port => (
  is      => 'rw',
  default => 80,
);

has timeout => (
  is      => 'rw',
  default => 1000,
);

has target => (
  is      => 'rw',
);


has scheme => (
  is      => 'rw',
  default => 'http',
);

sub dns_uri {
  my $self = shift;
  return URI->new($self->scheme.'://'.$self->domain.':'.$self->port);
}

sub rest_call {
  my ($self, $dns_uri) = @_;

  my $res;

  my $timeout = $self->timeout + 1;

  if (timeout_call( $timeout,
    sub {
      my $req = HTTP::Request->new (GET => $dns_uri);
      $req->content_type('application/json');

      my $lwp = LWP::UserAgent->new;
      $lwp->timeout($timeout);
      $res = $lwp->request( $req );
    })) {
    ouch 408, 'Timeout: no response from '.$self->domain;
  }

  unless ($res->is_success) {
    ouch $res->code, $res->message;
  }

  return $res;
}

sub token {
  my $self = shift;
  my %args = (
    username => undef,
    password => undef,
    @_
  );

  my $dns_uri = $self->dns_uri;
  $dns_uri->path('login/token.php');
  $dns_uri->query_form( {
    username => $args{username},
    password => $args{password},
    service  => $self->target,
  });

  my $res = $self->rest_call($dns_uri);

  return from_json($res->content);
}

sub login  {
  my $self = shift;
  my %args = (
    username => undef,
    password => undef,
    @_
  );

  my $username = $args{username};
  my $password = $args{password};
  my $target = $self->target;

  my $token = $self->token(
    username  => $username,
    password  => $password,
  );



  if (defined($token->{token})) {
    return {
      msg => "'$username' has access to the '$target' web service",
      ok  => 1,
      token => $token->{token},
    };
  }
  elsif ($token->{error} =~ m/No permission/) {
    return {
      msg => "'$username' has the correct password but no access to the '$target' web service",
      ok => 1,
    };
  }
  elsif ($token->{error}) {
    # a bit of a guess as to why, but the message has changed across Moodle verions
    return {
      msg => "'$username' does not exist, or did not enter the correct password",
      ok  => 0,
    };
  }
  else {
    ouch 'MSE:0001', "Service '$target': ".$token->{error}, $token;
  }

}

sub set_password {
  my $self = shift;
  my %args = (
    username  => undef,
    password   => undef,
    token     => undef,
    @_
  );


  my $username = lc($args{username});


  my $params = {
    'wstoken'                      => $args{token},
    'wsfunction'                   => "core_user_update_users",
    'moodlewsrestformat'           => $REST_FORMAT,
    'users[0][id]'                 => $self->get_user(token => $args{token}, username => $username )->{id},
    'users[0][password]'           => $args{password},
  };


  my $dns_uri = $self->dns_uri;
  $dns_uri->path('webservice/rest/server.php');
  $dns_uri->query_form( $params );

  my $res = $self->rest_call($dns_uri);

  return $res->is_success;
}

sub add_user {
  my $self = shift;
  my %args = (
    firstname => undef,
    lastname  => undef,
    email     => undef,
    username  => undef,
    token     => undef,
    password  => undef,
    @_
  );


  my $username = lc($args{username});

  my $params = {
    'wstoken'                      => $args{token},
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

  return from_json($res->content)->[0];
}

sub get_user {
  my $self = shift;
  my %args = (
    username  => undef,
    token     => undef,
    @_
  );


  my $username = lc($args{username});

  my $params = {
    'wstoken'                      => $args{token},
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


sub get_users {
  my $self = shift;
  my %args = (
    token     => undef,
    @_
  );

  my $params = {
    'wstoken'                      => $args{token},
    'wsfunction'                   => "core_user_get_users",
    'moodlewsrestformat'           => $REST_FORMAT,
    'criteria[0][key]'             => 'dummyparam',
    'criteria[0][value]'           => '',
  };


  my $dns_uri = $self->dns_uri;
  $dns_uri->path('webservice/rest/server.php');
  $dns_uri->query_form( $params );

  my $res = $self->rest_call($dns_uri);

  my $rh_res = from_json($res->content);
  return $rh_res->{users};
}

sub enrol_student {
  my $self = shift;
  my %args = (
    username   => undef,
    course => undef,
    token      => undef,
    @_
  );

  my $user_id = $self->get_user(
    token => $args{token},
    username => $args{username}
  )->{id};
  

  my $params = {
    'wstoken'                      => $args{token},
    'wsfunction'                   => "enrol_manual_enrol_users",
    'moodlewsrestformat'           => $REST_FORMAT,
    'enrolments[0][roleid]'        => $STUDENT_ROLE_ID,
    'enrolments[0][userid]'        => $user_id,
    'enrolments[0][courseid]'      => $self->get_course_id (  token => $args{token}, short_cname => $args{course} ),
  };


  my $dns_uri = $self->dns_uri;
  $dns_uri->path('webservice/rest/server.php');
  $dns_uri->query_form( $params );

  my $res = $self->rest_call($dns_uri);
  unless ($res->is_success) {
    ouch $res->code, $res->message;
  }
  return 1;
}

sub get_course_id {
  my $self = shift;
  my %args = (
    short_cname => undef,
    token       => undef,
    @_
  );

  my $dns_uri = $self->dns_uri;
  $dns_uri->path('webservice/rest/server.php');
  $dns_uri->query_form( {
    wstoken   => $args{token},
    wsfunction => 'core_course_get_courses',
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

# DEPRECATED: this depends on core_role_get_all_roles which isn't in the
# core Moodle distribution.
sub get_student_role {
  my $self = shift;
  my %args = (
    token       => undef,
    @_
  );

  my $dns_uri = $self->dns_uri;
  $dns_uri->path('webservice/rest/server.php');
  $dns_uri->query_form( {
    wstoken   => $args{token},
    wsfunction => 'core_role_get_all_roles',
    moodlewsrestformat => $REST_FORMAT,
  } );

  my $res = $self->rest_call($dns_uri);
  my $ra_roles = from_json($res->content);

  my $rh_student_role = first { $_->{shortname} eq 'student' } @$ra_roles;
  return $rh_student_role;
}


# WARNING: suspend_user depends on the 'suspended' parameter
# https://tracker.moodle.org/browse/MDL-31465

sub suspend_user {
  my $self = shift;
  my %args = (
    token    => undef,
    username => undef,
    suspend  => 1, # suspend unless it is 0
    @_
  );

  my $mdl_user = $self->get_user( username => $args{username}, token => $args{token});

  my $params = {
    'wstoken'                      => $args{token},
    'wsfunction'                   => "core_user_update_users",
    'moodlewsrestformat'           => $REST_FORMAT,
    'users[0][id]'                 => $mdl_user->{id},
    'users[0][suspended]'          => $args{suspend} + 0,
  };


  my $dns_uri = $self->dns_uri;
  $dns_uri->path('webservice/rest/server.php');
  $dns_uri->query_form( $params );

  my $res = $self->rest_call($dns_uri);

  return $res->content;
}


sub raw_api {
  my $self = shift;
  my %args = (
    token    => undef,
    method   => undef,
    params   => {},
    @_
  );

  my $params = {
    'wstoken'                      => $args{token},
    'wsfunction'                   => $args{method},
    'moodlewsrestformat'           => $REST_FORMAT,
    %{$args{params}}
  };


  my $dns_uri = $self->dns_uri;
  $dns_uri->path('webservice/rest/server.php');
  $dns_uri->query_form( $params );

  my $res = $self->rest_call($dns_uri);

  return if $res->content eq 'null';
  return from_json($res->content);
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Moodle::Simple - Client API and CLI for Moodle Web Services

=head1 SYNOPSIS


=head2 CLI

  moodlews login        - login with your Moodle password and retrieve token
  moodlews add_user     - Create a Moodle user account
  moodlews get_users    - Get all users
  moodlews enrol        - Enrol user into a course
  moodlews set_password - Update a user account password


=head2 API

  use WebService::Moodle::Simple;

  my $moodle = WebService::Moodle::Simple->new(
    domain   =>  'moodle.example.edu',
    target   =>  'example_webservice'
  );

  my $rh_token = $moodle->login( username => 'admin', password => 'p4ssw0rd');


=head1 DESCRIPTION

WebService::Moodle::Simple is Client API and CLI for Moodle Web Services

__THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE__.

=head1 USAGE


=head2 CLI

Get instructions on CLI usage

  moodlews

=head2 Example - Login and Get Users

  moodlews login -u admin -d moodle.example.edu -p p4ssw0rd -t example_webservice

Retrieve the user list using the token returned from the login command

  moodlews get_users -o becac8d120119eb2a312a385644eb709 -d moodle.example.edu -t example_webservice

=head2 Unit Tests

  prove -rlv t

=head3 Full Unit Tests

  TEST_WSMS_ADMIN_PWD=p4ssw0rd \
  TEST_WSMS_DOMAIN=moodle.example.edu \
  TEST_WSMS_TARGET=example_webservice prove -rlv t

__NOTE: Full unit tests write to Moodle Database - only run them against a test Moodle server__.

=head2 Methods

=over 4

=item *

I<$OBJ>->login(
  username => I<str>,
  password => I<str>,
)

Returns { msg => I<str>, ok => I<bool>, token => I<str> }

=item *

I<$OBJ>->set_password(
  username => I<str>,
  password => I<str>,
  token    => I<str>,
)

=item *

I<$OBJ>->add_user(
  firstname => I<str>,
  lastname  => I<str>,
  email     => I<str>,
  username  => I<str>,
  password  => I<str>,
  token     => I<str>,
)

=item *

I<$OBJ>->get_users(
  token     => I<str>,
)


=item *

I<$OBJ>->enrol_student(
  username  => I<str>,
  course    => I<str>,
  token     => I<str>,
)

=item *

I<$OBJ>->get_course_id(
  short_cname  => I<str>,
  token        => I<str>,
)

=item *

I<$OBJ>->get_user(
  token        => I<str>,
  username     => I<str>,
)

=item *

I<$OBJ>->suspend_user(
  token    => I<str>,
  username => I<str>,
  suspend  => I<bool default TRUE>
)

If suspend is true/nonzero (which is the default) it kills the user's session
and suspends their account preventing them from logging in. If suspend is false
they are given permission to login. NOTE: This will only work if the Moodle
server has had this patch (or its equivalent) applied:
https://github.com/fabiomsouto/moodle/compare/MOODLE_22_STABLE...MDL-31465-MOODLE_22_STABLE

=item *

I<$OBJ>->raw_api(
    method => I<moodle webservice method name>,
    token  => I<str>,
    params => I<hashref of method parameters>
)

returns Moodle's response.

=back

=head1 AUTHOR

Andrew Solomon E<lt>andrew@geekuni.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Andrew Solomon

=head1 ACKNOWLEDGEMENT

Built by Dist::Milla

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
