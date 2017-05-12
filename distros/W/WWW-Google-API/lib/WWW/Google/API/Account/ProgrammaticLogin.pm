package WWW::Google::API::Account::ProgrammaticLogin;

use strict;
use warnings;

use base qw(WWW::Google::API::Account);

sub authenticate {
  my $self = shift;
  my $conn = shift;

  my $auth_token = undef;
  my $client_login_uri = 'https://www.google.com/accounts/clientlogin';

  $self->ua->default_header( 'content-type' => 'application/x-www-form-urlencoded' );

  my $response = $self->ua->post( $client_login_uri,
                                   { accountType => 'hosted_or_google',
                                     Email       => $conn->{api_user},
                                     Passwd      => $conn->{api_pass},
                                     service     => $conn->{service},
                                    }
                                );
                                
  if ( $response->is_success ) {
    my $content = $response->content;
    my @content = split("\n", $content);
    for ( @content ) {
      $auth_token = $1 if /^Auth=(.*)$/;
    }
  } else {
    die $response->status_line;
  } 

  return $auth_token;
}

1;
