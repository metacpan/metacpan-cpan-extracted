package WebService::Eventful;

=head1 NAME

WebService::Eventful - Perl interface to Eventful public API

=head1 SYNOPSIS

  use WebService::Eventful;
  use Data::Dumper;
  
  my $evdb = WebService::Eventful->new(app_key => $app_key);
  
  # call() accepts either an array ref or a hash ref.
  my $event = $evdb->call('events/get', {id => 'E0-001-000218163-6'})
    or die "Can't retrieve event: $WebService::Eventful::errstr";
  
  print "Title: $event->{title}\n";

  my $venue = $evdb->call('venues/get', [id => $event->{venue_id}])
    or die "Can't retrieve venue: $WebService::Eventful::errstr";
  
  print "Venue: $venue->{name}\n";

  $evdb->setup_Oauth (
  consumer_key    => "Your_Consumer_Key",
  consumer_secret => "Your_Consumer_Secret",
  oauth_token     => "Your_Oauth_Token",
  oauth_secret    => "Your_Oauth_Token_Secret");


my $locs = $evdb->call('users/locales/list' )
    or die "Can't retrieve user locales : $WebService::Eventful::errstr";

print "Your locations are => " . Dumper ($locs) . "\n";


=head1 DESCRIPTION

The Eventful API allows you to build tools and applications that interact with Eventful.  This module provides a Perl interface to that API, including oauth authentication .  

See http://api.eventful.com/ for details.

=head1 AUTHORS

Copyright 2013 Eventful, Inc. All rights reserved.

You may distribute under the terms of either the GNU General Public License or the Artistic License, as specified in the Perl README file.

=head1 ACKNOWLEDGEMENTS

Special thanks to Daniel Westermann-Clark for adding support for "flavors" of 
plug-in parsers.  Visit Podbop.org to see other cool things made by Daniel.

=cut

require 5.6.0;

use strict;
use warnings;
no warnings qw(uninitialized);

use Carp;
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);
use OAuth::Lite::Consumer;
use Module::Pluggable::Object;
use Data::Dumper;

=head1 VERSION

1.01 - September 2006
1.03 - August 2013
1.05 - Sept 2013

=cut

our $VERSION = 1.05;

our $VERBOSE = 0;
our $DEBUG = 0;

our $default_api_server = 'http://api.eventful.com';
our $default_flavor = 'rest';

our $errcode;
our $errstr;

=head1 CLASS METHODS

=head2 new
  
  $evdb = WebService::Eventful->new(app_key => $app_key);

Creates a new API object. Requires a valid app_key as provided by Eventful.

You can also specify an API "flavor", such as C<yaml>, to use a different format.

  $evdb = WebService::Eventful->new(app_key => $app_key, flavor => 'yaml');

Valid flavors are C<rest>, C<yaml>, and C<json>.

=cut

sub new
{
  my $thing = shift;
  my $class = ref($thing) || $thing;
  
  my %params = @_;
  my $self = 
  {
    'app_key'     => $params{app_key} || $params{app_token},
    'debug'       => $params{debug},
    'verbose'     => $params{verbose},
    'api_root'    => $params{api_root} || $default_api_server,
  };
  
  $DEBUG   ||= $params{debug};
  $VERBOSE ||= $params{verbose};
  
  print "Creating object in class ($class)...\n" if $VERBOSE;
  
  bless $self, $class;
  
  my $flavor = $params{flavor} || $default_flavor;
  $self->{parser} = $self->_find_parser($flavor);
  croak "No parser found for flavor [$flavor]"
    unless $self->{parser};


  # Create an LWP user agent for later use.
  $self->{user_agent} = LWP::UserAgent->new(
    agent => "Eventful_API_Perl_Wrapper/$VERSION-$flavor",
  );
  
  return $self;
}

# Attempt to find a parser for the specified API flavor. 
# Returns the package name if one is found.
sub _find_parser
{
  my ($self, $requested_flavor) = @_;

  # Based on Catalyst::Plugin::ConfigLoader
  my $finder = Module::Pluggable::Object->new(
    search_path => [ __PACKAGE__ ],
    require     => 1,
  );

  my $parser;
  foreach my $plugin ($finder->plugins) {
    my $flavor = $plugin->flavor;
    if ($flavor eq $requested_flavor) {
      $parser = $plugin;
    }
  }

  return $parser;
}


=head1 OBJECT METHODS

=head2 setup_Oauth

  $evdb->setup_Oauth(consumer_key => 'CoNsUmErKey', consumer_secret => 'CoNsUmErSeCrEt', oauth_token => 'AcCeSsToKeN', oauth_secret => 'SeCrEtToKeN');

Sets up the OAuth parameters that will be used to construct the Authorization header with an oauth signature computed on the parameters of the call.

=cut

sub setup_Oauth 
{
  my $self = shift;
  
  my %args = @_;

# Generate Consumer 
  my $oauth_consumer = OAuth::Lite::Consumer->new(
  consumer_key       =>  $args{consumer_key},
  consumer_secret    =>  $args{consumer_secret},
  signature_method   => ($args{signature_method} || 'HMAC-SHA1') );

# Generate Token
  my $oauth_token = OAuth::Lite::Token->new (
  token  => $args{oauth_token},
  secret => $args{oauth_secret});

# Save them for when we need to compute the signature when the url is requested in the call.
  $self->{oauth_consumer} = $oauth_consumer;
  $self->{oauth_token}    = $oauth_token;

  return 1;
}

=head2 call

  $data = $evdb->call($method, \%arguments, [$force_array]);

Calls the specified method with the given arguments and any previous authentication information (including C<app_key>).  Returns a hash reference containing the results.

=cut

sub call 
{
  my $self = shift;
  
  my $method = shift;
  my $args = shift || [];
  my $force_array = shift;

  # Remove any leading slash from the method name.
  $method =~ s%^/%%;
  # If we have no force_array, see if we have one for this method.
  if ($self->{parser}->flavor eq 'rest' and !$force_array) {

    # The following code is automatically generated.  
    # 
    # BEGIN REPLACE
    if($method eq 'calendars/latest/stickers') {
      $force_array = ['site'];
    }

    elsif($method eq 'calendars/tags/cloud') {
      $force_array = ['tag'];
    }

    elsif($method eq 'demands/get') {
      $force_array = ['link', 'comment', 'image', 'tag', 'event', 'member'];
    }

    elsif($method eq 'demands/latest/hottest') {
      $force_array = ['demand', 'event'];
    }

    elsif($method eq 'demands/search') {
      $force_array = ['demand', 'event'];
    }

    elsif($method eq 'events/get') {
      $force_array = ['link', 'comment', 'trackback', 'image', 'parent', 'child', 'tag', 'feed', 'calendar', 'group', 'user', 'relationship', 'performer', 'rrule', 'exrule', 'rdate', 'exdate', 'date', 'category'];
    }

    elsif($method eq 'events/recurrence/list') {
      $force_array = ['recurrence'];
    }

    elsif($method eq 'events/tags/cloud') {
      $force_array = ['tag'];
    }

    elsif($method eq 'events/validate/hcal') {
      $force_array = ['tag', 'event_url', 'venue_url', 'event'];
    }

    elsif($method eq 'groups/get') {
      $force_array = ['user', 'calendar', 'link', 'comment', 'trackback', 'image', 'tag'];
    }

    elsif($method eq 'groups/search') {
      $force_array = ['group'];
    }

    elsif($method eq 'groups/users/list') {
      $force_array = ['user'];
    }

    elsif($method eq 'internal/events/submissions/pending') {
      $force_array = ['submission'];
    }

    elsif($method eq 'internal/events/submissions/set_status') {
      $force_array = ['submission'];
    }

    elsif($method eq 'internal/events/submissions/status') {
      $force_array = ['target'];
    }

    elsif($method eq 'internal/submissions/targets') {
      $force_array = ['target'];
    }

    elsif($method eq 'locales/search') {
      $force_array = ['suggestion'];
    }

    elsif($method eq 'performers/demands/list') {
      $force_array = ['demand'];
    }

    elsif($method eq 'performers/get') {
      $force_array = ['link', 'comment', 'image', 'tag', 'event', 'demand', 'trackback'];
    }

    elsif($method eq 'performers/search') {
      $force_array = ['performer'];
    }

    elsif($method eq 'users/calendars/get') {
      $force_array = ['rule', 'feed'];
    }

    elsif($method eq 'users/calendars/list') {
      $force_array = ['calendar'];
    }

    elsif($method eq 'users/comments/get') {
      $force_array = ['comment'];
    }

    elsif($method eq 'users/demands/list') {
      $force_array = ['demand', 'event'];
    }

    elsif($method eq 'users/details/get') {
      $force_array = ['demand', 'event', 'group', 'link', 'performer', 'venue', 'friend'];
    }

    elsif($method eq 'users/events/recent') {
      $force_array = ['event'];
    }

    elsif($method eq 'users/favorites/tags/list') {
      $force_array = ['tag'];
    }

    elsif($method eq 'users/friends/demands/list') {
      $force_array = ['demand', 'event', 'user'];
    }

    elsif($method eq 'users/get') {
      $force_array = ['site', 'im_account', 'event', 'venue', 'performer', 'comment', 'trackback', 'calendar', 'locale', 'link', 'event', 'image'];
    }

    elsif($method eq 'users/groups/list') {
      $force_array = ['group'];
    }

    elsif($method eq 'users/performers/demands/list') {
      $force_array = ['demand'];
    }

    elsif($method eq 'users/search') {
      $force_array = ['user'];
    }

    elsif($method eq 'users/venues/get') {
      $force_array = ['user_venue'];
    }

    elsif($method eq 'venues/get') {
      $force_array = ['link', 'comment', 'trackback', 'image', 'parent', 'child', 'event', 'tag', 'feed', 'calendar', 'group'];
    }

    elsif($method eq 'venues/tags/cloud') {
      $force_array = ['tag'];
    }

    else {
      $force_array = ['event', 'venue', 'comment', 'trackback', 'calendar', 'group', 'user', 'performer', 'member'];
    }

    # END REPLACE

  }

  # Construct the method URL.
	my $url = join '/', $self->{api_root}, $self->{parser}->flavor, $method;
  print "Calling ($url)...\n" if $VERBOSE;
  
  # Pre-process the arguments into a hash (for searching) and an array ref
  my $arg_present = {};
  if (ref($args) eq 'ARRAY')
  {
    # Create a hash of the array values (assumes [foo => 'bar', baz => 1]).
    my %arg_present = @{$args};
    $arg_present = \%arg_present;
  }
  elsif (ref($args) eq 'HASH')
  {
    # Migrate the provided hash to an array ref.
    $arg_present = $args;
    my @args = %{$args};
    $args = \@args;
  }
  else
  {
    $errcode = 'Missing parameter';
    $errstr  = 'Missing parameters: The second argument to call() should be an array or hash reference.';
    return undef;
  }
  
  # Add the standard arguments to the list.
  if ($self->{app_key} and !$arg_present->{app_key}) {
    push @{$args}, 'app_key' , $self->{app_key};
  }
  
  # If one of the arguments is a file, set up the Common-friendly 
  # file indicator field and set the content-type.
  my $content_type = '';
  foreach my $this_field (keys %{$arg_present})
  {
    # Any argument with a name that ends in "_file" is a file.
    if ($this_field =~ /_file$/)
    {
      $content_type = 'form-data';
      next if ref($arg_present->{$this_field}) eq 'ARRAY'; 
      my $file = 
      [
        $arg_present->{$this_field},
      ];
      
      # Replace the original argument with the file indicator.
      $arg_present->{$this_field} = $file;
      my $last_arg = scalar(@{$args}) - 1;
      ARG: for my $i (0..$last_arg)
      {
        if ($args->[$i] eq $this_field)
        {
          # If this is the right arg, replace the item after it.
          splice(@{$args}, $i + 1, 1, $file);
          last ARG;
        }
      }
    }
  }
  
  # Fetch the data using the POST method.
  my $ua = $self->{user_agent};

  # If we are doing Oauth authentication then we need to compute the signature/nonce/etc and add them into the query string
  if (exists $self->{oauth_consumer} ) {

     my %oauth_data;
     my $jx = 0;
     #  $content_type = 'form-data';
     if ($content_type eq 'form-data') {
      $oauth_data{app_key} = $self->{app_key};
     } else {
      %oauth_data = %$arg_present;
      $oauth_data{app_key} = $self->{app_key};
     }
     print "Your oauth params for signature are => " . Dumper (\%oauth_data) . "\n" if ($DEBUG);
     my $oauth_query = $self->{oauth_consumer}->gen_auth_query('POST', $url, $self->{oauth_token}, \%oauth_data );
     my $oauth_header = 'OAuth';
     my $comma = '';
     foreach my $pair (split ('&',$oauth_query)) {
       my ($var,$val) = (split ('=',$pair) );
       $oauth_header .= ($comma . " $var=" . '"' . $val . '"') ;
       $comma = ',';
     }
     print "Oauth added to your url => $oauth_header\n" if ($DEBUG);
     $ua->default_header('Authorization' => $oauth_header );
     warn "Your oauth header is => Oauth : $oauth_query\n" if ($DEBUG);
  }

  my $response = $ua->request(POST $url, 
    'Content-type' => $content_type, 
    'Content' => $args,
  );
  unless ($response->is_success) 
  {
    $errcode = $response->code;
    $errstr  = $response->code . ': ' . $response->message;
    return undef;
  }
  
  $self->{response_content} = $response->content();
  my $data;
  
  my $ctype = $self->{parser}->ctype;
  if ($response->header('Content-Type') =~ m/$ctype/i)
  {
    # Parse the response into a Perl data structure.
    if ($self->{parser}->flavor eq 'rest')
    {
      # Maintain backwards compatibility.
      $self->{response_xml} = $self->{response_content};
    }
    $data = $self->{response_data} = $self->{parser}->parse($self->{response_content}, $force_array);
    
    # Check for errors.
    if ($data->{string})
    {
      $errcode = $data->{string};
      $errstr  = $data->{string} . ": " .$data->{description};
      print "\n", $self->{response_content}, "\n" if $DEBUG;
      return undef;
    }
  }
  else
  {
    print "Content-type is: ", $response->header('Content-Type'), "\n";
    $data = $self->{response_content};
  }

  return $data;
}

# Copied shamelessly from CGI::Minimal.
sub url_encode 
{
  my $s = shift;
  return '' unless defined($s);
  
  # Filter out any URL-unfriendly characters.
  $s =~ s/([^-_.a-zA-Z0-9])/"\%".unpack("H",$1).unpack("h",$1)/egs;
  
  return $s;
}

1;

__END__


=cut
