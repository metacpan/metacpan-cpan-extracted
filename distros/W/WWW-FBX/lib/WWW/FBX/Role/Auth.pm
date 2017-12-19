package WWW::FBX::Role::Auth;
use 5.014001;
use Moose::Role;
use Digest::HMAC_SHA1 qw/ hmac_sha1_hex /;

has [ qw/app_token track_id/ ] => ( isa => 'Str', is => 'rw', default => '');

sub BUILD {
  my $self=shift;
  my $au_sts;
  my $challenge;
  my $res;

  #Do not perform connection automatically
  return if $self->noauth;

  #Get API version if we're called first
  $self->api_version;
  
  unless ( $self->app_token and $self->track_id ) {
    #Request token 
    $res = $self->req_auth ( {   app_id => $self->app_id, 
                               app_name => $self->app_name, 
                            app_version => $self->app_version,
                            device_name => $self->device_name } );
     $self->track_id( $res->{track_id} );
     $self->app_token( $res->{app_token} ); 
  }

  #Check auth status or wait for physical granting on the device
  $res = $self->auth_progress( $self->track_id );
  while( ( $au_sts = $res->{status} ) eq "pending" ) { 
    $challenge = $res->{challenge};
    print "Please Confirm on the FB - Merci d'autoriser sur la FB\n";
    $res = $self->auth_progress( $self->track_id );
    sleep 1;
  }

  die "Authorization not granted($au_sts)" unless $au_sts eq "granted";

  $challenge = $self->login->{challenge} unless ($challenge);

  $res = $self->open_session( {
      app_id =>  $self->app_id, 
      app_version => $self->app_version, 
      password => hmac_sha1_hex( $challenge, $self->app_token ),
  } );
  
  $self->ua->default_header('X-Fbx-App-Auth' => $res->{session_token});

}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::FBX::Role::Auth - Provides authentication mechanism.

=head1 SYNOPSIS

    use WWW::FBX::Role::Auth;

=head1 DESCRIPTION

WWW::FBX::Role::Auth is FBX Authenticator role.

=head1 LICENSE

Copyright (C) Laurent Kislaire.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Laurent Kislaire E<lt>teebeenator@gmail.comE<gt>

=cut

