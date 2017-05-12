package WWW::Google::API;

use strict;
use warnings;

=head1 NAME

WWW::Google::API - Perl client to the Google API C<< <http://code.google.com/apis/> >>

=head1 VERSION

version 0.003

  $Id$

=head1 SYNOPSIS

A base Google API client.

You probably want one of the subclasses of this module L<WWW::Google::API::Base>

=cut

our $VERSION = '0.003';

use base qw(Class::Accessor);

use LWP::UserAgent;


__PACKAGE__->mk_accessors(qw(ua token auth_client));

=head1 METHODS

=head2 new

Create a new client. 

=cut 

sub new {
  my $class       = shift;
  my $service     = shift;
  my $connection  = shift;
  my $lwp_cnf     = shift;
  
  
  my $auth_class = 'WWW::Google::API::Account::'.$connection->{auth_type};
  eval "require $auth_class" or die $@;
  
  my $self = { ua => LWP::UserAgent->new( agent => 'WWW::Google::API',
                                            %$lwp_cnf                 ) };
             
  bless($self, $class);

  $self->ua->default_header( 'X-Google-Key' => $connection->{api_key} );
  
  $self->auth_client("$auth_class"->new($self->ua));
  
  $self->token( $self->auth_client->authenticate( ( { service => $service, 
                                                      %$connection         
                                                    },
                                                  )    
                                                ) 
              );
  $self->ua->default_header( 'Authorization' => "GoogleLogin auth=" . $self->token );
  
  return $self;
}

=head2 do

Execute some action with the client. 

=cut

sub do {
  my $self    = shift;
  my $request = shift;

  my $response = $self->ua->request($request);

  if ($response->is_success) {
    return $response;
  } else {
    die $response;
  }
}

=head1 AUTHOR

John Cappiello, C<< <jcap@cpan.org> >>

=head1 BUGS

L<http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Google-API>

=head1 COPYRIGHT

Copyright 2006-2007 John Cappiello, all rights reserved.

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
