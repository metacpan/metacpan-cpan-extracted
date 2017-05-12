package WebService::Heartrails::Express;

use 5.008005;
use Mouse;
use WebService::Heartrails::Express::Provider;

our $VERSION = "0.01";

has provider => (
   is => 'ro',
   isa => 'WebService::Heartrails::Express::Provider',
   lazy_build => 1,
);

has areas => (
   is => 'rw',
   isa => 'ArrayRef',
   lazy_build => 1
);

has prefs => (
   is => 'rw',
   isa => 'ArrayRef',
   lazy_build => 1
);

sub line{
  my $self = shift;
  $self->provider->dispatch('line',@_);
}

sub station{
  my $self = shift;
  $self->provider->dispatch('station',@_);
}

sub near{
  my $self = shift;
  $self->provider->dispatch('near',@_);
}

use Furl;

sub _build_provider{
  my $self = shift;
  return WebService::Heartrails::Express::Provider->new(
       furl => Furl->new(
          agent  => 'WebService::Heartrails::Express(Perl)',
         timeout => 10,
       ),
  );
}

use constant AREA_ENDPOINT => 'http://express.heartrails.com/api/json?method=getAreas';
use constant PREF_ENDPOINT => 'http://express.heartrails.com/api/json?method=getPrefectures';

sub _build_areas{
 my $self = shift;
 my $response = $self->provider->furl->get(AREA_ENDPOINT);
 my $content = JSON::decode_json($response->{content});
 return $content->{response}->{area};
}

sub _build_prefs{
 my $self = shift;
 my $response = $self->provider->furl->get(PREF_ENDPOINT);
 my $content = JSON::decode_json($response->{content});
 return $content->{response}->{prefecture};
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf-8

=head1 NAME

WebService::Heartrails::Express - API client for Heartrails Express API

=head1 SYNOPSIS

 use WebService::Heartrails::Express;

 my $express = new WebService::Heartrails::Express();
   
 # Get line names by area
  
  my $area_only = $express->line({area => '関東'});
  
 # Get line names by prefecture
  
  my $pref_only = $express->line({prefecture => '神奈川県'});

 # Get line names by area and prefecture 

  my $pref_and_area = $express->line({area => '関東',prefecture => '千葉県'});

 # Get station information by line
   
  my $lineonly = $express->station({line => 'JR山手線'});
 
 # Get station information by name

  my $nameonly = $express->station({name => '新宿'});

 # Get station information by name and line
 
  my $name_and_line = $express->station({line => 'JR山手線',name => '新宿'});

 # Get near station information by latitude and longtitude

  my $near = $express->near({x => '135.0',y => '35.0'});


=head1 DESCRIPTION

WebService::Heartrails::Express is the API client for Heartrails express API.

Please refer L<http://express.heartrails.com/api.html>,L<http://nlftp.mlit.go.jp/ksj/other/yakkan.html>,L<http://www.heartrails.com/company/terms.html>,L<http://www.heartrails.com/company/disclaimer.html>
if you want to get imformation about Heartrails Express API.


=head1 LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sue7ga E<lt>sue77ga@gmail.comE<gt>

=cut

