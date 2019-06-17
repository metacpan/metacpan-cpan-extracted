package VoIPms;

use 5.024001;
use strict;
use warnings;

use URI::Escape;
use WWW::Mechanize;
use JSON::XS;

sub new {
    my $type = shift;
    my %params = @_;
    if (!defined $params{api_username} || !defined $params{api_password}) {
        die "'new' requires your API username and password as the first and second argument";
    }
    if (!defined $params{mech}) {
        $params{mech} = WWW::Mechanize->new(autocheck => 1, cookie_jar => {}, agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; MDDRJS; rv:11.0) like Gecko');
    }
    my $self = { api_username => "$params{api_username}", api_password => "$params{api_password}", mechanize => $params{mech}, location => 'https://voip.ms/api/v1/rest.php' };
    bless $self;
}

sub response {

    my $self = shift;
    my %params = @_;

    my $get = $self->{location} .
        '?api_username=' . uri_escape($self->{api_username}) .
        '&api_password=' . uri_escape($self->{api_password});
    foreach my $key (keys(%params)) {
        $get .= '&' . $key . '=' . uri_escape($params{$key});
    }

    my $response = $self->{mechanize}->get($get)->content;

    my $json = JSON::XS->new;
    return $json->decode($response);

}

our @ISA = qw(Exporter);

our @EXPORT = qw( new response );

our $VERSION = '0.01';

1;

__END__

=head1 NAME

VoIPms - API wrapper for VoIP.ms

=head1 SYNOPSIS

  use VoIPms;

  my $voipms = VoIPms->new( 
    'api_username' => $api_username,
    'api_password' => $api_password,
    // You can optionally defined your own WWW::Mechanize object
  );

  # Response can be fetched with a hash, or individual key/value pairs
  $res = $voipms->response( %url_attrs );
  $res = $voipms->response( 'method' => 'methodName', 'key2' => 'value2' );

  eg.
  $res = $voipms->response( 'method' => 'getSMS', 'did' => '1234567890' );

  # All responses will be returned as a hash reference, including a 'status'
  # which will have the value 'success' if the call worked.
  if ($res->{status} ne 'success') {
    die $res->{status};
  }

=head1 DESCRIPTION

This module provides all of the documented methods from the VoIP.ms
API, as listed here: https://www.voip.ms/m/apidocs.php

Responses from VoIP.ms are provided as JSON but are decoded and
returned as pure Perl.

=head2 EXPORT

None.

=head1 HISTORY

=over 8

=item 0.01

Initial release supporting all VoIP.ms public API methods. 2019-06-16

=back

=head1 SEE ALSO

Official Documentation

The official VoIP.ms API documentation, again, with more thourough
explanations of all methods:

https://www.voip.ms/m/apidocs.php

VoIPms::Errors

All responses will have a "status" method which should be 'success'
if the call worked. The additional module VoIPms::Errors.pm is
available to provide the long description of the short error code 
returned.

Examples

Some discussion of the author's use of the module here:

https://john.me.tz/projects/article.php?topic=VoIPms

=head1 AUTHOR

John Mertz <perl@john.me.tz>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by John Mertz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
