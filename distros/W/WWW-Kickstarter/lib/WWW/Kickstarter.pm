
package WWW::Kickstarter;

use strict;
use warnings;
no autovivification;

use version; our $VERSION = qv('v1.12.0');


use Time::HiRes                              qw( );
use URI                                      qw( );
use URI::Escape                              qw( uri_escape_utf8 );
use URI::QueryParam                          qw( );
use WWW::Kickstarter::Data::Categories       qw( );
use WWW::Kickstarter::Data::Category         qw( );
use WWW::Kickstarter::Data::Location         qw( );
use WWW::Kickstarter::Data::NotificationPref qw( );
use WWW::Kickstarter::Data::Project          qw( );
use WWW::Kickstarter::Data::Reward           qw( );
use WWW::Kickstarter::Data::User             qw( );
use WWW::Kickstarter::Data::User::Myself     qw( );
use WWW::Kickstarter::Error                  qw( my_croak );
use WWW::Kickstarter::Iterator               qw( );


# ---


our $HTTP_CLIENT_CLASS = 'WWW::Kickstarter::HttpClient::Lwp';
our $JSON_PARSER_CLASS = 'WWW::Kickstarter::JsonParser::JsonXs';


# ---


sub _load_class {
   my ($class) = @_;

   # This isn't exactly what Perl accepts as an identifier, but close enough.
   $class =~ /^\w+(?:::\w+)*\z/
      or my_croak(400, "Unacceptable class name $class");

   eval("require $class")
      or die($@);

   return $class;
}


sub _expand_agent {
   my ($agent) = @_;

   return $agent if defined($agent) && $agent !~ / \z/;

   $agent = 'unspecified_application/0.00 ' if !defined($agent);

   my $version = $VERSION;
   $version =~ s/^v//;
   $agent .= "perl-WWW-Kickstarter/$version ";

   return $agent;
}


# ---


sub new {
   my ($class, %opts) = @_;

   my $http_client_class = delete($opts{http_client_class}) || $HTTP_CLIENT_CLASS;
   my $json_parser_class = delete($opts{json_parser_class}) || $JSON_PARSER_CLASS;
   my $agent             = delete($opts{agent});
   my $impolite          = delete($opts{impolite});

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $self = bless({}, $class);
   $self->{http_client } = _load_class($http_client_class)->new( agent => _expand_agent($agent) );
   $self->{json_parser } = _load_class($json_parser_class)->new();
   $self->{polite      } = !$impolite;
   $self->{wait_until  } = 0;
   $self->{access_token} = undef;
   $self->{my_id       } = undef;

   return $self;
}


# ---


sub _validate_response {
   my ($self, $response, %opts) = @_;

   my $recognize_404 = delete($opts{recognize_404});

   return 1
      if (ref($response) || '') ne 'HASH';

   my $ksr_code  = $response->{ksr_code};
   my $http_code = $response->{http_code};
   my $messages  = $response->{error_messages};

   my $msg = "Error from Kickstarter";
   $msg .= ": $ksr_code"                                         if $ksr_code;
   $msg .= ": HTTP $http_code"                                   if $http_code;
   $msg .= ": " . join(' // ', @{ $response->{error_messages} }) if $messages && @$messages;

   if ($recognize_404 && $http_code && $http_code eq '404') {
      my_croak(404, $msg);
   }

   if ($messages && @$messages) {
      my_croak(500, $msg);
   }

   return 1;
}


sub _http_request {
   my ($self, $method, $url, $form) = @_;

   my $req_content;
   if ($form) {
      if ($method eq 'GET' ) {
         $url = URI->new($url);
         for (my $i=0; $i<@$form; $i+=2) {
            $url->query_param_append($form->[$i+0] => $form->[$i+1]);
         }
      } else {
         my @params;
         for (my $i=0; $i<@$form; $i+=2) {
            push @params, uri_escape_utf8($form->[$i+0]) . '=' . uri_escape_utf8($form->[$i+1]);
         }

         $req_content = join('&', @params);
      }
   }


   my $stime = Time::HiRes::time();

   if ($self->{polite}) {
      # Throttle requests
      my $wait_until = $self->{wait_until};
      while ($stime < $wait_until) {
         # Sometimes, it sleeps a little less than requested,
         # resulting in a loop of ever-shorter sleeps.
         # Sleeping an extra millisecond avoids that waste.
         Time::HiRes::sleep($wait_until - $stime + 0.001);
         $stime = Time::HiRes::time();
      }
   }


   my ( $status_code, $status_line, $content_type, $content_encoding, $content ) = $self->{http_client}->request($method, $url, $req_content);

   my $etime = Time::HiRes::time();

   my $cool_down = $etime - $stime;
   $cool_down = 4 if $cool_down > 4;
   $self->{wait_until} = $etime + $cool_down;

   if ($content_type ne 'application/json') {
      if ($status_code >= 200 && $status_code < 300) {
         my_croak(500, "Error parsing response: Unexpected content type");
      } else {
         my_croak(500, "HTTP error: $status_line");
      }
   }

   if ($content_encoding && uc($content_encoding) ne 'UTF-8') {
      my_croak(500, "Error parsing response: Unexpected content encoding \"$content_encoding\"");
   }

   my $response = eval { $self->{json_parser}->decode($content) }
      or my_croak(500, "Error parsing response: Invalid JSON");

   return $response;
}


my %ks_iterator_name_by_class = (
    'WWW::Kickstarter::Data::Category' => 'categories',
    'WWW::Kickstarter::Data::Project'  => 'projects',
    'WWW::Kickstarter::Data::User'     => 'users',
);

sub _call_api {
   my_croak(400, "Incorrect usage") if @_ < 4;
   my ($self, $url, $call_type, $class, %opts) = @_;

   my $recognize_404 = 0;
   my $cursor_style;
   if (ref($call_type)) {
      ($call_type, my %call_opts) = @$call_type;
      $recognize_404 = delete($call_opts{recognize_404});
      $cursor_style  = delete($call_opts{cursor_style});
   }

   my @cursor;
   if (defined($cursor_style)) {
      if ($cursor_style eq 'start') {
         my $start = delete($opts{start});
         @cursor = ( cursor => $start ) if defined($start) && length($start);
      }
      elsif ($cursor_style eq 'page') {
         my $page = delete($opts{page});
         @cursor = ( page => $page ) if defined($page) && length($page);
      }
      else {
         die("Invalid cursor style $cursor_style");
      }
   }

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $access_token = $self->{access_token}
      or my_croak(400, "Must login first");

   $url = URI->new('https://api.kickstarter.com/v1/' . $url);
   $url->query_param_append(oauth_token => $access_token);

   $class = 'WWW::Kickstarter::Data::' . $class;

   if ($call_type eq 'single') {
      my $response = $self->_http_request(GET => $url);
      $self->_validate_response($response, recognize_404 => $recognize_404);

      return $class->_new($self, $response);
   }
   elsif ($call_type eq 'list') {
      my $response = $self->_http_request(GET => $url);
      $self->_validate_response($response, recognize_404 => $recognize_404);

      return map { $class->_new($self, $_) } @$response;
   }
   elsif ($call_type eq 'iterator') {
      my $ks_iterator_name = $ks_iterator_name_by_class{$class}
         or die("Can't determine Kickstarter iterator name for $class");

      $url->query_param_append(@cursor)
         if @cursor;

      my $fetcher = sub {
         my ($recognize_404) = @_;

         return () if !$url;

         my $response = $self->_http_request(GET => $url);
         $self->_validate_response($response, recognize_404 => $recognize_404);

         $response->{$ks_iterator_name}
            or my_croak(500, "Error parsing response: Unrecognized format");

         if (my $more_url = $response->{urls}{api}{"more_".$ks_iterator_name}) {
            $url = URI->new($more_url);
            $url->query_param_delete('signature');
            $url->query_param_append(oauth_token => $access_token);
         } else {
            $url = undef;
         }

         return map { $class->_new($self, $_) } @{ $response->{$ks_iterator_name} };
      };

      # Prefetch the first batch to check for 404 errors.
      my @results = $fetcher->($recognize_404);

      return WWW::Kickstarter::Iterator->new($fetcher, \@results);
   }
   else {
      die("Invalid call type $call_type");
   }
}


# ---


sub login {
   my_croak(400, "Incorrect usage") if @_ < 3;
   my ($self, $email, $password, %opts) = @_;

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $response = $self->_http_request(
      POST => 'https://api.kickstarter.com/xauth/access_token?client_id=2II5GGBZLOOZAA5XBU1U0Y44BU57Q58L8KOGM7H0E0YFHP3KTG',
      [
         email    => $email,
         password => $password,
      ],
   );

   {
      my $ksr_code = $response->{ksr_code};
      if ($ksr_code && $ksr_code eq 'invalid_xauth_login') {
         my_croak(401, "Invalid user name or password");
      }
   }

   $self->_validate_response($response);

   my $access_token = $response->{access_token}
      or my_croak(500, "Error parsing response: Missing access token");

   $self->{access_token} = $access_token;

   my $user_data = $response->{user}
      or my_croak(500, "Error parsing response: Missing user data");

   my $myself = WWW::Kickstarter::Data::User::Myself->_new($self, $user_data);

   $self->{my_id} = $myself->id;

   return $myself;
}


# ---


sub _projects {
   my ($self, $fixed, %opts) = @_;

   my %form;
   for my $field_name (
      'q',                  # Search terms
      'category',           # Category's "id", "slug" or "name".
      'tag',                # Tag's "id" or "slug".
      'location',           # Location's "id" (which is a "Where on Earth Identifier").
      'backed_by_self',     # Boolean
      'starred_by_self',    # Boolean
      'backed_by_friends',  # Boolean
      'picked_by_staff',    # Boolean
      'state',              # 'all' (default), 'live', 'successful'
      'pledged',            # 'all' (default), '0':<=$1k, '1':$1k to $10k, '2':$10k to $100k, '3':$100k to $1M, '4':>$1M
      'goal',               # 'all' (default), '0':<=$1k, '1':$1k to $10k, '2':$10k to $100k, '3':$100k to $1M, '4':>$1M
      'raised',             # 'all' (default), '0':<75%, '1':75% to 100%, '2':>100%
      'sort',               # 'magic' (default), 'end_date', 'newest', 'launch_date', 'popularity', 'most_funded'
   ) {
      $form{$field_name} = exists($fixed->{$field_name}) ? $fixed->{$field_name} : delete($opts{$field_name});
   }

   $form{q}        = ''      if !defined($form{q});
   $form{category} = ''      if !defined($form{category});
   $form{tag}      = ''      if !defined($form{tag});
   $form{location} = ''      if !defined($form{location});
   $form{state}    = 'all'   if !defined($form{state})       || !length($form{state});
   $form{pledged}  = 'all'   if !defined($form{pledged})     || !length($form{pledged});
   $form{goal}     = 'all'   if !defined($form{goal})        || !length($form{goal});
   $form{raised}   = 'all'   if !defined($form{raised})      || !length($form{raised});
   $form{sort}     = 'magic' if !defined($form{sort})        || !length($form{sort});

   $form{state} =~ /^(?:all|live|successful)\z/
      or my_croak(400, "Unrecognized value for state. Valid: all, live, successful");
   $form{pledged} =~ /^(?:all|[01234])\z/
      or my_croak(400, "Unrecognized value for pledged. Valid: all, 0, 1, 2, 3, 4");
   $form{goal} =~ /^(?:all|[01234])\z/
      or my_croak(400, "Unrecognized value for goal. Valid: all, 0, 1, 2, 3, 4");
   $form{raised} =~ /^(?:all|[012])\z/
      or my_croak(400, "Unrecognized value for raised. Valid: all, 0, 1, 2");
   $form{sort} =~ /^(?:magic|end_date|newest|launch_date|popularity|most_funded)\z/
      or my_croak(400, "Unrecognized value for sort. Valid: magic, end_date, newest, launch_date, popularity, most_funded");

   my $url = URI->new('discover', 'http');
   $url->query_param_append( term        => $form{q}        ) if length($form{q});
   $url->query_param_append( category_id => $form{category} ) if length($form{category});
   $url->query_param_append( tag_id      => $form{tag}      ) if length($form{tag});
   $url->query_param_append( woe_id      => $form{location} ) if length($form{location});
   $url->query_param_append( backed      => '1'             ) if $form{backed_by_self};
   $url->query_param_append( starred     => '1'             ) if $form{starred_by_self};
   $url->query_param_append( social      => '1'             ) if $form{backed_by_friends};
   $url->query_param_append( staff_picks => '1'             ) if $form{picked_by_staff};
   $url->query_param_append( state       => $form{state}    ) if $form{state}   ne 'all';
   $url->query_param_append( pledged     => $form{pledged}  ) if $form{pledged} ne 'all';
   $url->query_param_append( goal        => $form{goal}     ) if $form{goal}    ne 'all';
   $url->query_param_append( raised      => $form{raised}   ) if $form{raised}  ne 'all';
   $url->query_param_append( sort        => $form{sort}     ) if $form{sort} ne 'magic';

   return $self->_call_api($url, [ 'iterator', cursor_style=>'page' ], 'Project', %opts);
}


# ---


sub myself {
   my $self = shift;
   return $self->_call_api('users/self', 'single', 'User::Myself', @_);
}

sub my_id {
   my ($self) = @_;
   return $self->{my_id};
}

sub my_notification_prefs {
   my $self = shift;
   return $self->_call_api('users/self/notifications', 'list', 'NotificationPref', @_);
}

sub my_projects_created {
   my $self = shift;
   return $self->_call_api('users/self/projects/created', 'list', 'Project', @_);
}

# There's no way to have 'discover?backed=1' return the results sorted by backing timestamp,
# so we'll continue to use the original interface ('users/self/projects/backed').
# But for consistency and possibly for foward-compatibility, we'll require a page-style cursor.
sub my_projects_backed {
   my ($self, %opts) = @_;

   if (exists($opts{start})) {
      my_croak(400, "Unrecognized parameter start");
   }

   if (defined(my $page = delete($opts{page}))) {
      $opts{start} = ($page - 1) * 10;
   }

   return $self->_call_api('users/self/projects/backed', [ 'iterator', cursor_style=>'start' ], 'Project', %opts);
}

# There's no way to have 'discover?starred=1' return the results sorted by starring timestamp,
# so we'll continue to use the original interface ('users/self/projects/starred').
# But for consistency and possibly for forward-compatibility, we'll require a page-style cursor.
sub my_projects_starred {
   my ($self, %opts) = @_;

   if (exists($opts{start})) {
      my_croak(400, "Unrecognized parameter start");
   }

   if (defined(my $page = delete($opts{page}))) {
      $opts{start} = ($page - 1) * 10;
   }

   return $self->_call_api('users/self/projects/starred', [ 'iterator', cursor_style=>'start' ], 'Project', %opts);
}

sub user {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self    = shift;
   my $user_id = shift;  # From "id" field. Cannot be "slug".
   return $self->_call_api('users/'.uri_escape_utf8($user_id), [ 'single', recognize_404=>1 ], 'User', @_);
}

sub user_projects_created {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self    = shift;
   my $user_id = shift;  # From "id" field. Cannot be "slug".
   return $self->_call_api('users/'.uri_escape_utf8($user_id).'/projects/created', [ 'list', recognize_404=>1 ], 'Project', @_);
}

sub project {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self       = shift;
   my $project_id = shift;  # "id" or "slug".
   return $self->_call_api('projects/'.uri_escape_utf8($project_id), [ 'single', recognize_404=>1 ], 'Project', @_);
}

sub project_rewards {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self       = shift;
   my $project_id = shift;  # "id" or "slug".
   return $self->_call_api('projects/'.uri_escape_utf8($project_id).'/rewards', [ 'list', recognize_404=>1 ], 'Reward', @_);
}

sub projects {
   my $self = shift;
   return $self->_projects({}, @_);
}

sub projects_recommended {
   my $self = shift;
   return $self->_projects({ staff_picks => 1 }, @_);
}

sub projects_ending_soon {
   my $self = shift;
   return $self->_projects({ state => 'live', sort => 'end_date' }, @_);
}

sub projects_recently_launched {
   my $self = shift;
   return $self->_projects({ state => 'live', sort => 'newest' }, @_);
}

sub popular_projects {
   my $self = shift;
   return $self->_projects({ sort => 'popularity' }, @_);
}

sub location {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self        = shift;
   my $location_id = shift;  # From "id" field. Cannot be "slug".
   return $self->_call_api('locations/'.uri_escape_utf8($location_id), [ 'single', recognize_404=>1 ], 'Location', @_);
}

sub projects_near_location {
   my $self        = shift;
   my $location_id = shift;  # From "id" field. Cannot be "slug".
   return $self->_projects({ location => $location_id }, @_);
}

sub category {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self        = shift;
   my $category_id = shift;  # "id", "slug" or "name".
   return $self->_call_api('categories/'.uri_escape_utf8($category_id), [ 'single', recognize_404=>1 ], 'Category', @_);
}

sub categories {
   my $self = shift;
   my $iter = $self->_call_api('categories', 'iterator', 'Category');
   return WWW::Kickstarter::Data::Categories->_new($self, [ $iter->get_rest() ]);
}

sub category_projects {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self        = shift;
   my $category_id = shift;  # "id", "slug" or "name".
   return $self->_projects({ category => $category_id }, @_);
}

sub category_projects_recommended {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self        = shift;
   my $category_id = shift;  # "id", "slug" or "name".
   return $self->_projects({ category => $category_id, staff_picks => 1 }, @_);
}


# ---


1;


__END__

=head1 NAME

WWW::Kickstarter - Retrieve information from Kickstarter


=head1 VERSION

Version 1.12.0


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   my $myself = $ks->login($email, $password);

   my $iter = $ks->projects_ending_soon();
   while (my ($project) = $iter->get()) {
      print($project->name, "\n");
   }


=head1 DESCRIPTION

This distribution provides access to Kickstarter's private API
to obtain information about your account, other users and projects.


=head1 CONSTRUCTOR

=head2 new

   my $ks = WWW::Kickstarter->new(%opts);

This is the starting point to using the API, after which you much login
using the C<< $ks->login >> method documented immediately below.

Options:

=over

=item * C<< agent => "application_name/version " >>

The string to pass to Kickstarter in the User-Agent HTTP header.
If the string ends with a space, the name and version of this library will be appended,
as will the name of version of the underling HTTP client.


=item * C<< impolite => 1 >>

This module throttles the rate at which it sends requests to Kickstarter.
It won't place another request until C<$X> seconds has passed since the last request,
where C<$X> is the amount of time taken to fulfill the last request, but at most 4 seconds.

C<< impolite => 1 >> disables the throttling.


=item * C<< http_client_class => $class_name >>

The class to use instead of L<WWW::Kickstarter::HttpClient::Lwp> as the HTTP client.
For example, this would allow you to easily substitute L<Net::Curl> for L<LWP::UserAgent>.
See L<WWW::Kickstarter::HttpClient> for documentation on the interface the replacement class needs to provide.


=item * C<< json_parser_class => $class_name >>

The class to use instead of L<WWW::Kickstarter::JsonParser::JsonXs> as the JSON parser.
For example, this would allow you to easily substitute L<JSON::PP> for L<JSON::XS>.
See L<WWW::Kickstarter::JsonParser> for documentation on the interface the replacement class needs to provide.


=back


=head1 ACCESSORS

=head2 my_id

   my $user_id = $ks->my_id;

Returns the id of the logged-in user.


=head1 API CALLS

=head2 login

   my $myself = $ks->login($email, $password);

You must login using your standard Kickstarter credentials before you can query the API.

Returns a L<WWW::Kickstarter::Data::User::Myself> object for the user that logged in.


=head2 myself

   my $myself = $ks->myself();

Fetches and returns the logged-in user as a L<WWW::Kickstarter::Data::User::Myself> object.


=head2 my_notification_prefs

   my @notification_prefs = $ks->my_notification_prefs();

Fetches and returns the the logged-in user's notification preferences of backed projects as L<WWW::Kickstarter::Data::NotificationPref> objects.
The notification preferences for the project created last is returned first.


=head2 my_projects_created

   my @projects = $ks->my_projects_created();

Fetches and returns the projects created by the logged-in user as L<WWW::Kickstarter::Data::Project> objects.
The project created last is returned first.


=head2 my_projects_backed

   my $projects_iter = $ks->my_projects_backed(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns the projects backed by the logged-in user as L<WWW::Kickstarter::Data::Project> objects.
The most recently backed project is returned first.

Note that some projects may be returned twice. This happens when the data being queried changes while the results are being traversed.

Options:

=over

=item * C<< page => $page_num >>

If provided, the pages of results before the specified page number are skipped.

=back


=head2 my_projects_starred

   my $projects_iter = $ks->my_projects_starred(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns the projects starred by the logged-in user as L<WWW::Kickstarter::Data::Project> objects.
The most recently starred project is returned first.

Note that some projects may be returned twice. This happens when the data being queried changes while the results are being traversed.

Options:

=over

=item * C<< page => $page_num >>

If provided, the pages of results before the specified page number are skipped.

=back


=head2 user

   my $user = $ks->user($user_id);

Fetches and returns the specified user as a L<WWW::Kickstarter::Data::User> object.

Note that the argument must be the user's numerical id (as returned by L<C<< $user->id >>|WWW::Kickstarter::Data::User/id>).


=head2 user_projects_created

   my @projects = $ks->user_projects_created($user_id);

Fetches and returns the projects created by the specified user as L<WWW::Kickstarter::Data::Project> objects. The project created last is returned first.

Note that the argument must be the user's numerical id (as returned by L<C<< $user->id >>|WWW::Kickstarter::Data::User/id>).


=head2 project

   my $project = $ks->project($project_id);
   my $project = $ks->project($project_slug);

Fetches and returns the specified project as a L<WWW::Kickstarter::Data::Project> object.

The argument may be the project's numerical id (as returned by L<C<< $project->id >>|WWW::Kickstarter::Data::Project/id>) or
its "slug" (as returned by L<C<< $project->slug >>|WWW::Kickstarter::Data::Project/slug>).


=head2 project_rewards

   my @rewards = $ks->project_rewards($project_id);
   my @rewards = $ks->project_rewards($project_slug);

Fetches and returns the rewards of the specified project as L<WWW::Kickstarter::Data::Reward> objects.

The argument may be the project's numerical id (as returned by L<C<< $project->id >>|WWW::Kickstarter::Data::Project/id>) or
its "slug" (as returned by L<C<< $project->slug >>|WWW::Kickstarter::Data::Project/slug>).


=head2 projects

   my $projects_iter = $ks->projects(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns all Kickstarter projects as L<WWW::Kickstarter::Data::Project> objects.

Note that some projects may be returned twice, and some might be skipped. This happens when the data being queried changes while the results are being traversed.

Options:

=over

=item * C<< q => $search_terms >>

Limits the projects returned to those matching the string of search terms.

=item * C<< category => $category_id >>

=item * C<< category => $category_slug >>

=item * C<< category => $category_name >>

Limits the projects returned to those of the specified category (or one of its subcategories).

=item * C<< tag => $tag_id >>

=item * C<< tag => $tag_slug >>

Limits the projects returned to those with the specified tag.

The list of tags available changes often. I don't know of an API endpoint that returns a list of available tags, but you can find some of them on L<Kickstarter's Advanced Discover page|https://www.kickstarter.com/discover/advanced>. See L<WWW::Kickstarter::Data::Tags> for the list of tags known to exist at the time of this writing.

=item * C<< location => $woe_id >>

Limits the projects returned to those associated with the specified location.

=item * C<< backed_by_self => 1 >>

Limits the projects returned to those backed by the logged-in user.

=item * C<< starred_by_self => 1 >>

Limits the projects returned to those starred by the logged-in user.

=item * C<< backed_by_friends => 1 >>

Limits the projects returned to those backed by friends of the logged-in user.

=item * C<< picked_by_staff => 1 >>

Limits the projects returned to those recommended by Kickstarter.

=item * C<< state => 'live' >>

=item * C<< state => 'successful' >>

Limits the projects returned to those with the specified state.

The empty string and the string C<all> are accepted as equivalent to not providing the option at all.

=item * C<< goal => $goal_range_id >>

Limits the projects returned to those which have a goal that falls within the specified range. The ranges are defined as follows:

=over

=item * C<0>: E<le>$1k

=item * C<1>: E<gt>$1k and E<le>$10k

=item * C<2>: E<gt>$10k and E<le>$100k

=item * C<3>: E<gt>$100k and E<le>$1M

=item * C<4>: E<gt>$1M

=back

The empty string and the string C<all> are accepted as equivalent to not providing the option at all.

=item * C<< pledged => $pledged_range_id >>

Limits the projects returned to those to which the amount pledged falls within the specified range. The ranges are defined as follows:

=over

=item * C<0>: E<le>$1k

=item * C<1>: E<gt>$1k and E<le>$10k

=item * C<2>: E<gt>$10k and E<le>$100k

=item * C<3>: E<gt>$100k and E<le>$1M

=item * C<4>: E<gt>$1M

=back

The empty string and the string C<all> are accepted as equivalent to not providing the option at all.

=item * C<< raised => $raised_range_id >>

Limits the projects returned to those to which the amount pledged falls within the specified range. The ranges are defined as follows:

=over

=item * C<0>: E<lt>75%

=item * C<1>: 75% to 100%

=item * C<2>: E<gt>100%

=back

The empty string and the string C<all> are accepted as equivalent to not providing the option at all.

=item * C<< sort => 'magic' >> (default)

=item * C<< sort => 'end_date' >>

=item * C<< sort => 'newest' >>

=item * C<< sort => 'launch_date' >>

=item * C<< sort => 'popularity' >>

=item * C<< sort => 'most_funded' >>

Controls the order in which the projects are returned.

=item * C<< page => $page_num >>

If provided, the pages of results before the specified page number are skipped.

=back

=head2 projects_recommended

   my $projects_iter = $ks->projects_recommended(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns recommended projects as L<WWW::Kickstarter::Data::Project> objects.

It accepts the same options as L<C<projects>|/projects>.


=head2 projects_ending_soon

   my $projects_iter = $ks->projects_ending_soon(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns projects ending soon as L<WWW::Kickstarter::Data::Project> objects. The project closest to its deadline is returned first.

It accepts the same options as L<C<projects>|/projects>.


=head2 projects_recently_launched

   my $projects_iter = $ks->projects_recently_launched(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns recently launched projects as L<WWW::Kickstarter::Data::Project> objects. The most recently launched project is returned first.

It accepts the same options as L<C<projects>|/projects>.


=head2 popular_projects

   my $projects_iter = $ks->popular_projects(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns popular projects as L<WWW::Kickstarter::Data::Project> objects.

It accepts the same options as L<C<projects>|/projects>.


=head2 location

   my $location = $ks->location($location_id);

Fetches and returns the specified location as a L<WWW::Kickstarter::Data::Location> object.

Note that the argument must be the location's numerical id (as returned by L<C<< $location->id >>|WWW::Kickstarter::Data::Location/id>).


=head2 projects_near_location

   my $projects_iter = $ks->projects_near_location($location_id, %opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns the projects near the specified location as L<WWW::Kickstarter::Data::Project> objects.

The argument must be the location's id (as returned by L<C<< $location->id >>|WWW::Kickstarter::Data::Location/id>).

It accepts the same options as L<C<projects>|/projects>.


=head2 category

   my $category = $ks->category($category_id);
   my $category = $ks->category($category_slug);
   my $category = $ks->category($category_name);

Fetches and returns the specified category as a L<WWW::Kickstarter::Data::Category> object.

The argument may be the category's numerical id (as returned by L<C<< $category->id >>|WWW::Kickstarter::Data::Category/id>),
its "slug" (as returned by L<C<< $category->slug >>|WWW::Kickstarter::Data::Category/slug>) or
its name (as returned by L<C<< $category->name >>|WWW::Kickstarter::Data::Category/name>).


=head2 categories

    my $categories = $ks->categories();

Fetches and returns all the categories as a L<WWW::Kickstarter::Data::Categories> object.


=head2 category_projects

   my $projects_iter = $ks->category_projects($category_id,   %opts);
   my $projects_iter = $ks->category_projects($category_slug, %opts);
   my $projects_iter = $ks->category_projects($category_name, %opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns projects in the specified category as L<WWW::Kickstarter::Data::Project> objects.

The argument may be the category's numerical id (as returned by L<C<< $category->id >>|WWW::Kickstarter::Data::Category/id>),
its "slug" (as returned by L<C<< $category->slug >>|WWW::Kickstarter::Data::Category/slug>) or
its name (as returned by L<C<< $category->name >>|WWW::Kickstarter::Data::Category/name>).

It accepts the same options as L<C<projects>|/projects>.


=head2 category_projects_recommended

   my $projects_iter = $ks->category_projects_recommended($category_id,   %opts);
   my $projects_iter = $ks->category_projects_recommended($category_slug, %opts);
   my $projects_iter = $ks->category_projects_recommended($category_name, %opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns the recommended projects in the specified category as L<WWW::Kickstarter::Data::Project> objects.

The argument may be the category's numerical id (as returned by L<C<< $category->id >>|WWW::Kickstarter::Data::Category/id>),
its "slug" (as returned by L<C<< $category->slug >>|WWW::Kickstarter::Data::Category/slug>) or
its name (as returned by L<C<< $category->name >>|WWW::Kickstarter::Data::Category/name>).

It accepts the same options as L<C<projects>|/projects>.


=head1 ERROR REPORTING

When an API call encounters an error, it throws a L<WWW::Kickstarter::Error> object as an exception.


=head1 GUARANTEE

Kickstarter has not provided a public API. As such,
this distribution uses a private API to obtain information.
The API is subject to incompatible change without notice.
This has already happened, and may happen again. I cannot
guarantee the continuing operation of this distribution.


=head1 KNOWN ISSUES

The following issues are known:

=over

=item * A lot of the data returned by the API has not been made available through accessors (though the data is available by accessing the object hash directly).

=item * Some API calls may not have been made available.

=item * Non-existent test suite.

=back

Feel free to bug the L<author|/AUTHOR> to work on these, or to submit a patch to one of the bug trackers listed below.


=head1 DOCUMENTATION AND SUPPORT

You can find documentation for this module with the perldoc command.

   perldoc WWW::Kickstarter

You can also find it online at these locations:

=over

=item * L<http://search.cpan.org/dist/WWW-Kickstarter>

=item * L<https://metacpan.org/release/WWW-Kickstarter>

=back

If you need help, the following are great resources:

=over

=item * L<Stack Overflow|https://stackoverflow.com/>

=item * L<PerlMonks|http://www.perlmonks.org/>

=item * You may also contact the L<author|/AUTHOR> directly.

=back

Bugs and improvements can be reported using any of the following systems:

=over

=item Using CPAN's request tracker by emailing C<bug-WWW-Kickstarter at rt.cpan.org>

=item Using CPAN's request tracker at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Kickstarter>

=item Using GitHub's issue tracker at L<https://github.com/ikegami/perl-WWW-Kickstarter/issues>

=back


=head1 REPOSITORY

=over

=item * Web: L<https://github.com/ikegami/perl-WWW-Kickstarter>

=item * git: L<https://github.com/ikegami/perl-WWW-Kickstarter.git>

=back


=head1 AUTHOR

Eric Brine C<< <ikegami@adaelis.com> >>

Initial release assisted by Mark Olson's "Kickscraper" project for Ruby.


=head1 COPYRIGHT AND LICENSE

No rights reserved.

The author has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.


=cut
