package VK::App;

use strict;
use warnings;
use LWP;
use LWP::Protocol::https;
use JSON;

our $VERSION = 0.12;

sub new {
  my ($class, %args) = @_;
  die "USAGE:\nVK::App->new(api_id => ... login => ... password => ...)\n",
  "VK::App->new(api_id => ... cookie_file => ...)\n" unless _valid_new_args(\%args);
 
  my $self;
  $self->{api_id}      = $args{api_id}       if exists $args{api_id};
  $self->{login}       = $args{login}        if exists $args{login};
  $self->{password}    = $args{password}     if exists $args{password};
  $self->{cookie_file} = $args{cookie_file}  if exists $args{cookie_file};
  (exists $args{scope})?($self->{scope} = $args{scope}):($self->{scope} = 'friends,photos,audio,video,wall,groups,messages,offline');
  (exists $args{format})?($self->{format} = $args{format}):($self->{format} = 'Perl');
  (exists $args{cookie_file})?($self->{ua} = _create_ua($args{cookie_file})):($self->{ua} = _create_ua());
  
  bless $self, $class;
 
  die 'ERROR: login failed' unless($self->_login());
  die 'ERROR: authorize app failed' unless($self->_authorize_app());

  $self->{ua}->cookie_jar()->save($self->{cookie_file}) if (exists $self->{cookie_file});

  return $self;
}

sub _login {
  my $self = shift;
  my $lpage = $self->{ua}->get('http://vk.com/login.php');
  return 0 unless ($lpage->is_success); # network problem?
  my $action = $1 if $lpage->content =~ /action=\"(.+?)\"/;
  return 1 unless $action; # log in already? go to the next step
  my $res = $self->{ua}->post($action, {
  #my $res = $self->{ua}->post('https://login.vk.com/?act=login', {
      email => $self->{login},
      pass => $self->{password},
    });
  return 0 if $res->status_line ne "302 Found";
  return 0 if $res->header('location') !~ /__q_hash/;
  $res = $self->{ua}->get($res->header('location'));
  return 0 unless $res->is_success;
  return $res->message;
}

sub _authorize_app {
  my $self = shift;
  push @{ $self->{ua}->requests_redirectable }, 'POST';
  my %authorize;
  $authorize{request} = 'http://oauth.vk.com/authorize?'.
  'client_id='.$self->{api_id}.
  '&scope='.$self->{scope}.
  '&redirect_uri=http://api.vk.com/blank.html'.
  '&display=wap'.
  '&response_type=token';
  my $res = $self->{ua}->post($authorize{request}); 
  return 0 unless $res->is_success;
  my $contect = $res->decoded_content;
  $authorize{approve} = $1 if $contect =~ /action=\"(.+)\"/;
  if (exists $authorize{approve}) {
    $res = $self->{ua}->post($authorize{approve});
    return 0 unless $res->is_success;
  }
  if ($res->request()->uri() =~ /access_token=(.+)&expires_in=0&user_id=(\d+)/) {
    $self->{access_token} = $1;
    $self->{uid} = $2;
  }
  return $res->message;
}

sub _create_ua {
  my $ua = LWP::UserAgent->new(agent => "VK::App $VERSION");
  #push @{ $ua->requests_redirectable }, 'POST';
  #$ua->ssl_opts(verify_hostname => 0);
  ($_[0])?($ua->cookie_jar( {file=>$_[0],autosave => 1} )):($ua->cookie_jar( { } ));
  return $ua;
}

sub _clean_cookie {
  my $self = shift;
  $self->{ua}->cookie_jar()->clear();
  return 1;
}

sub _valid_new_args {
  my $args = shift;
  return 0 unless ref($args) eq 'HASH';
  if (!$args->{api_id} || 
     ((!$args->{login} || !$args->{password}) && !$args->{cookie_file}) ) {
       return 0;
  }
  return 1;
}

sub ua {
  my $self = shift;
  die "Can't get UserAgent object" unless exists $self->{ua};
  return $self->{ua};
}

sub access_token {
  my $self = shift;
  die "Can't get access token" unless exists $self->{access_token};
  return $self->{access_token};
}

sub uid {
  my $self = shift;
  die "Can't get user id" unless exists $self->{uid};
  return $self->{uid};
}

sub request {
  my $self   = shift;
  my $method = shift;
  $method .= '.xml' if $self->{format} eq "XML";
  my $params = shift || {};
  my $url = 'https://api.vk.com/method/'.$method;
  my $res = $self->{ua}->post($url, { %$params, access_token => $self->{access_token} });
  return 0 unless $res->is_success;
  my $content = $res->content;
  return $content if ($self->{format} eq "XML");
  return $content if ($self->{format} eq "JSON");
  return decode_json($content);
}

1;

__END__

#################### DOCUMENTATION ####################

=head1 NAME

VK::App - Creation of a client application for vk.com

=head1 SYNOPSIS

    ### Application object creation ###
    #1. Authorizing by login and password
    use VK::App;
    my $vk = VK::App->new(
            # Your email or mobile phone to vk.com    
            login => 'login',
            # Your password to vk.com
            password => 'password',
            # The api_id of application
            api_id => 'api_id',
            # Name of the file to restore cookies from and save cookies to
            #(this parameter is optional in this case)
            cookie_file => '/home/user/.vk.com.cookie',
    );

    #2. Authorizing by cookie file
    use VK::App;
    my $vk = VK::App->new(
            # Name of the file to restore cookies from and save cookies to
            cookie_file => '/home/user/.vk.com.cookie',
            # The api_id of application
            api_id => 'api_id',
    );

    #3. Set additional options
    use VK::App;
    my $vk = VK::App->new(
            # Name of the file to restore cookies from and save cookies to
            cookie_file => '/home/user/.vk.com.cookie',
            # The api_id of application
            api_id => 'api_id',
            # Set application access rights
            scope => 'friends,photos,audio,video,wall,groups,messages,offline',
            # Data format that will receive as a result of requests 'JSON', 'XML' or 'Perl'.
            # Perl object by default.
            format => 'Perl',
    );
            
    ### Requests examples ###

    #1. Get user id by name
    my $user = $vk->request('getProfiles',{uid=>'genaev',fields=>'uid'});
    my $uid = $user->{response}->[0]->{uid};

    #2. Get a list of tracks by uid
    my $tracks = $vk->request('audio.get',{uid=>$uid});
    my $url = $tracks->{response}->[0]->{url}; # get url of the first track


=head1 DESCRIPTION

B<VK::App> - Module for creation of client applications based on OAuth 2.0, receiving access rights and sending requests to API vk.com. First, you need to get B<api_id> application that will work with the API of vk.com. You can register your application at L<http://vk.com/apps.php?act=add> or use B<api_id> of the existing application.

This package also includes B<scripts/vmd.pl> script, that shows how to use the module.

=head1 METHODS

=head2 C<new>

Creates and returns an VK::App object. Takes a list containing key-value pairs.

=over 4

=item * Required Arguments

=over 4

=item * api_id

The api_id of application. You can register your application at L<https://vk.com/editapp?act=create> or use B<api_id> of the existing application.

=item * login

Your email or mobile phone to vk.com

=item * password

Your password to vk.com

=item * cookie_file

Name of the file to restore cookies from and save cookies to. B<Notice that instead of a login and password, you can only use the file cookie_file!>

=back

=item * Other Important Arguments

=over 4

=item * scope

Set application access rights. List of available access rights L<http://vk.com/dev/permissions>. 'friends,photos,audio,video,wall,groups,messages,offline' by default.

=item * format

Data format that will receive as a result of requests 'JSON', 'XML' or 'Perl'. Perl object by default.

=back

=back

=head2 C<request>

Send requests and return response.

    my $response = $vk->request($METHOD_NAME,$PARAMETERS);

API method description available at L<http://vk.com/dev/methods>

=head2 C<ua>

Returns LWP::UserAgent object. This can be useful for downloading music, videos or photos from vk.com. See B<scripts/vmd.pl> script that is included in the package.

=head2 C<uid>

Returns UID of the current user.

=head2 C<access_token>

Returns access_token. access_token - access key received as a result of successful application authorization.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VK::App

If you have any questions or suggestions please contact me by email.

=head1 AUTHOR

Misha Genaev, <mag at cpan.org> (L<http://genaev.com/>)

=head1 COPYRIGHT

Copyright 2012-2014 by Misha Genaev

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

