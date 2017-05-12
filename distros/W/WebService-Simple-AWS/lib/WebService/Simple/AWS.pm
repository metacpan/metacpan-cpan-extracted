package WebService::Simple::AWS;
use strict;
use warnings;
use base qw( WebService::Simple );
use Digest::SHA qw(hmac_sha256_base64);
use URI::Escape qw(uri_escape_utf8);
use Carp;

our $VERSION = '0.02';

sub request_url {
    my $self   = shift;
    my %args   = @_;
    my $uri    = URI->new( $args{url} );
    my $params = $args{params};
    $params->{AWSAccessKeyId} = delete $params->{id}
      || Carp::croak("Aceess Key Id is requiered!");
    my $secret = delete $params->{secret}
      || Carp::croak("Aceess Key Secret is requiered!");
    $params->{Timestamp} = timestamp();
    $params->{SignatureMethod} = 'HmacSHA256';
    my $query = join '&',
        map { $_ . '=' . uri_escape_utf8( $params->{$_}, "^A-Za-z0-9\-_.~" ) }
            sort keys %$params;
    my $tosign = join "\n", 'GET', $uri->host, $uri->path, $query;
    my $signature = hmac_sha256_base64( $tosign, $secret );
    $signature .= '=' while length($signature) % 4;
    $params->{Signature} = $signature;
    $uri->query_form(%$params);
    return $uri;
}

sub timestamp {
    my $t = shift;
    $t = time unless defined $t;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      gmtime($t);
    return sprintf(
        "%4i-%02i-%02iT%02i:%02i:%02iZ",
        ( $year + 1900 ),
        ( $mon + 1 ),
        $mday, $hour, $min, $sec
    );
}

1;

__END__

=head1 NAME

WebService::Simple::AWS - Simple Interface to Amazon Web Service using WebService::Simple

=head1 SYNOPSIS

  use WebService::Simple::AWS;

  my $service = WebService::Simple::AWS->new(
      base_url => 'http://webservices.amazon.com/onca/xml',
      params   => {
          Version => '2009-03-31',
          Service => 'AWSECommerceService',
          id      => $ENV{'AWS_ACCESS_KEY_ID'},
          secret  => $ENV{'AWS_ACCESS_KEY_SECRET'},
      },
  );

  my $res = $service->get(
      {
          Operation     => 'ItemLookup',
          ItemId        => '0596000278',       # Larry's book
          ResponseGroup => 'ItemAttributes',
      }
  );
  my $ref = $res->parse_response();
  print "$ref->{Items}{Item}{ItemAttributes}{Title}\n";

=head1 DESCRIPTION

WebService::Simple::AWS is Simple Interface to Amazon Web Service using WebService::Simple.
Add "Signature" and "Timestamp" parameters if accessing to API.
Currently this API supports only "Signature Version 2".

See L<eg/product_advertising.pl>.

=head1 AUTHOR

Yusuke Wada  C<< <yusuke@kamawada.com> >>

=head1 SEE ALSO

L<WebSercie::Simple>

http://docs.amazonwebservices.com/AWSECommerceService/latest/DG/index.html?rest-signature.html

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
