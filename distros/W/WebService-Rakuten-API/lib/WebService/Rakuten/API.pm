package WebService::Rakuten::API;
use 5.008005;
use strict;
use warnings;
use LWP::UserAgent;
use Mouse;
use JSON;
use URI;
our $VERSION = "0.06";
use WebService::Rakuten::API::Provider::Travel;
use WebService::Rakuten::API::Provider::Ichiba;
use WebService::Rakuten::API::Provider::Recipe;
use WebService::Rakuten::API::Provider;
use Mouse;
use Furl;

has appid => (
 is => 'rw',
 isa => 'Str',
);

has provider => (
 is =>'ro',
 isa => 'WebService::Rakuten::API::Provider',
 lazy_build => 1,
);

sub _build_provider{
 my $self = shift;
 return WebService::Rakuten::API::Provider->new(
   furl => Furl->new(
     agent => 'WebService::Rakuten::API(Perl)',
     timeout => 10,
   ),
   appid => $self->appid,
 );
}

sub response{
 my($self)= @_;
 my $ua = LWP::UserAgent->new;
}

sub travel{
  my $self = shift;
 $self->provider->dispatch('travel',@_);
}

sub ichiba{
 my $self = shift;
 $self->provider->dispatch('ichiba',@_);
}

sub books{
 my $self = shift;
 $self->provider->dispatch('books',@_);
}

sub recipe{
 my $self =shift;
 $self->provider->dispatch('recipe',@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Rakuten::API - It's a Rakuten WebService API.

=head1 SYNOPSIS

  use WebService::Rakuten::API;

  my $rakuten = WebService::Rakuten::API->new(
       appid => __YOURAPI__
  );
   
  my $items = $rakuten->ichiba({keyword => '遊戯王',format => 'json'});

  print $items->{Items}->[0]->{Item}->{itemName};  

=head1 DESCRIPTION

WebService::Rakuten::API is API that is descripting RakutenWebServiceAPI.

=head1 LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sue7ga E<lt>sue77ga@gmail.comE<gt>

=cut

