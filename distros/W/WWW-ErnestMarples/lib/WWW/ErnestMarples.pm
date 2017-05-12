package WWW::ErnestMarples;

use warnings;
use strict;

use Carp;
use HTML::Tiny;
use LWP::UserAgent;

=head1 NAME

WWW::ErnestMarples - Interface to the ernestmarples.com UK postcode lookup API

=head1 VERSION

This document describes WWW::ErnestMarples version 0.01

=cut

our $VERSION = '0.01';

use constant SERVICE => 'http://ernestmarples.com/';

=head1 SYNOPSIS

  use WWW::ErnestMarples;

  my $em = WWW::ErnestMarples->new;
  my ( $lat, $lon ) = $em->lookup('CA9 3NT');
  
=head1 INTERFACE 

=head2 C<< new >>

Create a new C<WWW::ErnestMarples>. Accepts named arguments. The only
argument currently supported is C<service> which gives the base URL of
the lookup service. Defaults to C<http://ernestmarples.com/>.

  my $em = WWW::ErnestMarples->new( 
    service => 'http://localhost/emtest.cgi' 
  );

For normal use pass no args:

  my $em = WWW::ErnestMarples->new;

=cut

sub new {
  my $class = shift;
  croak "Expected a number of key => value pairs" if @_ % 1;
  my %args    = @_;
  my $service = delete $args{service};
  $service = $class->SERVICE unless defined $service;
  croak "Unknown options: ", join ', ', sort keys %args if keys %args;
  return bless { service => $service }, $class;
}

=head2 C<lookup>

Look up a UK postcode. The return value is a list containing latitude,
longitude of the postcode.

  my ( $lat, $lon ) = $em->lookup( $my_postcode );

=cut

sub lookup {
  my ( $self, $postcode ) = @_;

  my $resp
   = $self->_ua->get( $self->{service} . '?'
     . HTML::Tiny->new->query_encode( { p => $postcode, f => 'csv' } )
   );

  croak $resp->status_line if $resp->is_error;
  croak "Bad response from $self->{service}; is that a valid postcode?"
   unless $resp->content_type =~ m{^text/csv\b};
  chomp( my $content = $resp->content );
  my ( $pc, $lat, $lon ) = split /,/, $content;
  croak "Bad response from $self->{service}; could not parse response"
   unless defined $lon
     && $lat =~ /^-?\d+(?:\.\d+)?$/
     && $lon =~ /^-?\d+(?:\.\d+)?$/;
  return $lat, $lon;
}

sub _ua {
  my $self = shift;
  return $self->{_ua} ||= do {
    my $ua = LWP::UserAgent->new;
    $ua->agent( sprintf( '%s %s', __PACKAGE__, $VERSION ) );
    $ua;
  };
}

1;
__END__

=head1 CAVEATS

From L<http://ernestmarples.com/>:

  Important: Given the inherent unreliability of using a service like
  this, it's probably sensible to let us know you're using it so we can
  hang on to your email and let you know if anything important happens.
  Hopefully the Royal Mail will be nice, and license us to use the
  postcode database. Then you'll be able to rely on us and this service
  will become a seamless and transparent part of the web's
  infrastructure, like it ought to be.

Visit the site for more information.

=head1 CONFIGURATION AND ENVIRONMENT
  
WWW::ErnestMarples requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<HTML::Tiny>, L<LWP::UserAgent>, L<Test::More>.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-www-ernestmarples@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong  C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
