# WWW:Auth
#
# Copyright (c) 2002 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


package WWW::Auth;
use base 'WWW::Auth::Base';


use strict;
use WWW::Auth::Base;
use WWW::Auth::Config;
use CGI qw(:standard);
use CGI::Cookie;
use LWP::UserAgent;
use HTTP::Request;
use MD5;
use vars qw($VERSION);

$VERSION = '1.01';


sub _init {
  my $self   = shift;
  my %params = @_;

  $self->{_cgi}  = CGI->new ();

  $self->{_domain}       = $params{Domain}
                           || WWW::Auth::Config->doimain;

  $self->{_cgi_header}   = $params{CGIHeader} || 1;
  $self->{_login_param}  = $params{LoginParam}
                           || WWW::Auth::Config->login_param  || 'Login';
  $self->{_logout_param} = $params{LogoutParam}
                           || WWW::Auth::Config->logout_param || 'Logout';
  $self->{_uid_param}    = $params{UIDParam}
                           || WWW::Auth::Config->uid_param    || 'uid';
  $self->{_pwd_param}    = $params{PwdParam}
                           || WWW::Auth::Config->pwd_param   || 'pwd';

  $self->{_logout_url}   = $params{LogoutURL}
                           || WWW::Auth::Config->logour_url
    || return $self->error ('No Logout URL specified.');

  $self->{_secure}       = $params{Secure}
                           || WWW::Auth::Config->secure || 0;

  $self->{_auth}         = $params{Auth}
                           || WWW::Auth::Config->auth (%params)
    || return $self->error (WWW::Auth::Config->error);

  $self->{_serverkey_src} = $params{ServerKeySrc}
                            || WWW::Auth::Config->serverkey_src
    || return $self->error ('No Server Key Source specified.');

  $self->{_template}	= $params{Template}
                          || WWW::Auth::Config->template
    || return $self->error (WWW::Auth::Config->error);
  $self->{_login_template} = $params{LoginTemplate}
                          || WWW::Auth::Config->login_template
    || return $self->error ('No Login Template specified.');
  $self->{_logout_template} = $params{LogoutTemplate}
                          || WWW::Auth::Config->logout_template
    || return $self->error ('No Logout Template specified.');
  $self->{_secure_template} = $params{SecureTemplate}
                          || WWW::Auth::Config->secure_template
    || return $self->error ('No Secure Template specified.');

  $self->{_ticket_name} = $params{TicketName}
                          || WWW::Auth::Config->ticket_name  || 'Ticket';

  return 1;
}

sub get_serverkey {
  my $self = shift;

  my $ua = LWP::UserAgent->new ();
  my $request = HTTP::Request->new (GET => $self->{_serverkey_src});
  my $response = $ua->request ($request);

  return $response->content;
}

sub login {
  my $self = shift;
  my %params = @_;

  my $login_param  = $params{LoginParam}  || $self->{_login_param};
  my $logout_param = $params{LogoutParam} || $self->{_logout_param};
  my $uid_param    = $params{UIDParam}    || $self->{_uid_param};
  my $pwd_param    = $params{PwdParam}    || $self->{_pwd_param};
  my $domain       = $params{Domain}      || $self->{_domain};
  my $logout_url   = $params{LogoutURL}   || $self->{_logout_url};
  my $secure       = $params{Secure}      || $self->{_secure};

  my $msg;

  # Redirect to secure page.
  if ($secure && $ENV{HTTPS} ne 'on') {
    my $http_host   = $ENV{HTTP_HOST};
    my $request_uri = $ENV{REQUEST_URI};
    print $self->{_cgi}->header (
            -refresh	=> "1; URL=https://$http_host$request_uri"
          );
    $self->{_template}->process ($self->{_secure_template},
      {http_host	=> $http_host,
       redirect_url	=> $request_uri});
    exit;
  }

  # Logout.
  if ($self->{_cgi}->param ($logout_param)) {
    # Create a new empty ticket.
    my $ticket = $self->make_ticket ($self->{_ticket_name}, $domain);
    if ($ticket) {
       print $self->{_cgi}->header (
               -cookie  => $ticket,
               -refresh => "1; URL=$logout_url"
             );
       $self->{_template}->process ($self->{_logout_template},
         {http		=> $ENV{HTTPS} eq 'on' ? 'https' : 'http',
          http_host	=> $ENV{HTTP_HOST},
          redirect_url	=> $logout_url});
       exit;
    }

  # Log in for the first time.
  } elsif ($self->{_cgi}->param ($login_param)) {
    # Get the user id and password entered.
    my $uid = $self->{_cgi}->param ($uid_param);
    my $pwd = $self->{_cgi}->param ($pwd_param);

    # Return an error if username and password not given.
    if (! $uid || ! $pwd) {
      $msg = 'Enter your username and password.';

    # Authenticate.
    } else {
      my $result;
      ($result, $msg) = $self->{_auth}->auth ($uid, $pwd, %params);
      if ($result) {
        # Create a new ticket.
        my $serverkey = $self->get_serverkey ();
        my $ticket = $self->make_ticket ($self->{_ticket_name},
                                         $domain, $uid, $serverkey);
        if ($ticket) {
           # Create uri to redirect to.
           my $request_uri = $self->{_cgi}->param ('request_uri');

           # XXX Send post params.
#           my $params;
#           foreach my $param ('mode', 'action') {
#             if (defined $self->{_cgi}->param ($param) &&
#                 $request_uri !~ /[?|&]$param=/) {
#               $params .= defined $params ? '&' : '?';
#               $params .= "$param=" . $self->{_cgi}->param ($param);
#             }
#           }
#           $request_uri .= $params if defined $params;
           
           print $self->{_cgi}->header (
                   -cookie      => $ticket,
                   -refresh     => "1; URL=$request_uri"
                 );
           $self->{_template}->process ($self->{_login_template},
             {http		=> $ENV{HTTPS} eq 'on' ? 'https' : 'http',
              http_host		=> $ENV{HTTP_HOST},
              redirect_url	=> $request_uri});
           exit;
        } else {
          $msg = 'Could not make ticket';
        }
      }
    }
  } else {
    # If there is a ticket, verify it.
    my %ticket = $self->{_cgi}->cookie ($self->{_ticket_name});

    if (%ticket && ($ticket{uid} !~ /^\s*$/)) {
      my $serverkey = $self->get_serverkey ();
      my $result;
      ($result, $msg) = $self->verify_ticket (\%ticket, $serverkey);
      if ($result) {
        # Update time on ticket.
        my $new_ticket = $self->make_ticket ($self->{_ticket_name},
                                             $domain, $ticket{uid}, 
                                             $serverkey);
        if ($new_ticket) {
           print $self->{_cgi}->header (
                   -cookie      => $new_ticket
                 );
           return (1);
        } else {
          $msg = 'Could not make ticket';
        }
      }
    }
  }

  print $self->{_cgi}->header if $self->{_cgiheader};

  return (0, $msg);
}

sub authenticate {
  my $self = shift;
  my ($uid, $pwd, $params) = @_;

  if (! defined $params->{Users} ||
      (defined $params->{Users} &&
       $params->{Users}->{$uid})) {
    my $success = 0;
    if ($params->{Auth} eq 'FTP') {
      use Net::FTP;
      my $ftp = Net::FTP->new ($params->{FTPHost});
      $success = $ftp->login ($uid, $pwd);
      $ftp->quit ();

    } else {
      my ($upwd) = $self->{db}->select (Fields  => 'pwd',
                                        Table   => 'users',
                                        Where   => "uid='$uid'");
      if ($upwd =~ /^\s*$/ ||
          $upwd ne crypt ($pwd, $upwd)) {
        $success = 0;
      } else {
        $success = 1;
      }
    }

    if ($success) {
      return (1);
    } else {
      return (0, 'Username/Password incorrect');
    }
  } else {
    return (0, 'Access denied.');
  }
}

sub make_ticket {
  my $self = shift;
  my ($ticket_name, $domain, $uid, $pwd) = @_;

  $ticket_name = 'Ticket' if ! defined $ticket_name;

  if (defined $uid) {
    my $ip_addr = $ENV{REMOTE_ADDR};
    my $expires = 60 * 30;
    my $time    = time;

    my $hash    = MD5->hexhash ($pwd .
                    MD5->hexhash (join (':', $pwd, $ip_addr, $time, $expires,
                                             $uid)));
    my %cookie = (-name		=> $ticket_name,
                  -value	=> {'ip_addr'	=> $ip_addr,
                                   'time'	=> $time,
                                   'uid'	=> $uid,
                                   'hash'	=> $hash,
                                   'expires'	=> $expires});
    $cookie{-domain} = $domain if defined $domain;
    return $self->{_cgi}->cookie (%cookie);
  } else {
    my %cookie = (-name		=> $ticket_name,
                  -value	=> {uid => ''});
    $cookie{-domain} = $domain if defined $domain;
    return $self->{_cgi}->cookie (%cookie);
  }
}

sub verify_ticket {
  my $self = shift;
  my ($ticket, $pwd) = @_;

  # Check if all the fields are present.
  unless ($ticket->{uid}     &&
          $ticket->{time}    &&
          $ticket->{hash}    &&
          $ticket->{expires}) {
    return (0, 'Malformed ticket');
  }
  # Check if IP address matches.
  if ($ticket->{ip_addr} ne $ENV{REMOTE_ADDR}) {
    return (0, 'IP address mismatch');
  }
  # Check if ticket has expires.
  if (time - $ticket->{time} > $ticket->{expires}) {
    return (0, 'Session has expired');
  }

  my $newhash = MD5->hexhash ($pwd .
                  MD5->hexhash (join (':', $pwd, $ticket->{ip_addr},
                                           $ticket->{time}, $ticket->{expires},
                                           $ticket->{uid})));
  if ($newhash ne $ticket->{hash}) {
    return (0, 'Ticket mismatch');
  }

  # Store uid.
  $self->{uid} = $ticket->{uid};

  return (1);
}

sub uid {
  my $self = shift;

  return $self->{uid};
}


1;
