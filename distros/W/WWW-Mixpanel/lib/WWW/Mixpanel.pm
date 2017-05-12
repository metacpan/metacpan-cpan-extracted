package WWW::Mixpanel;

use strict;
use warnings;
use LWP::UserAgent;
use MIME::Base64;
use JSON;

BEGIN {
  $WWW::Mixpanel::VERSION = '0.07';
}

sub new {
  my ( $class, $token, $use_ssl, $api_key, $api_secret ) = @_;
  die "You must provide your API token." unless $token;

  my $ua = LWP::UserAgent->new;
  $ua->timeout(180);
  $ua->env_proxy;

  my $json = JSON->new->allow_blessed(1)->convert_blessed(1);

  bless { token                           => $token,
          use_ssl                         => $use_ssl,
          api_key                         => $api_key,
          api_secret                      => $api_secret,
          data_api_default_expire_seconds => 180,
          track_api                       => 'api.mixpanel.com/track/', # trailing slash required
          data_api                        => 'mixpanel.com/api/2.0/',
          people_api                      => 'api.mixpanel.com/engage/',
          json                            => $json,
          ua                              => $ua, }, $class;
}

sub people_set{
  my ( $self, $distinct_id, %params ) = @_;

  die "Distinct User Id required" unless $distinct_id;

  my $data = { '$set'  => \%params,
               '$distinct_id' => $distinct_id,
               '$ip' => 0,
               '$token' => $self->{token}
  };

  my $res =
    $self->{ua}->post( $self->{use_ssl}
      ? "https://$self->{people_api}"
      : "http://$self->{people_api}",
      { 'data' => encode_base64( $self->{json}->encode($data), '' ) } );

  if ( $res->is_success ) {
    if ( $res->content == 1 ) {
      return 1;
    }
    else {
      die "Failure from api: " . $res->content;
    }
  }
  else {
    die "Failed sending event: " . $self->_res($res);
  }
}

sub people_increment{
  my ( $self, $distinct_id, %params ) = @_;

  die "Distinct User Id required" unless $distinct_id;

  my $data = { '$add'  => \%params,
               '$distinct_id' => $distinct_id,
               '$ip' => 0,
               '$token' => $self->{token}
             };

  my $res =
    $self->{ua}->post( $self->{use_ssl}
                        ? "https://$self->{people_api}"
                        : "http://$self->{people_api}",
                        { 'data' => encode_base64( $self->{json}->encode($data), '' ) } );

  if ( $res->is_success ) {
    if ( $res->content == 1 ) {
      return 1;
    }
    else {
      die "Failure from api: " . $res->content;
    }
  }
  else {
    die "Failed sending event: " . $self->_res($res);
  }
}

sub people_append_transactions{
  my ( $self, $distinct_id, %params ) = @_;

  die "Distinct User Id required" unless $distinct_id;

  my $data = { '$append'  => {'$transactions' => \%params},
               '$distinct_id' => $distinct_id,
               '$ip' => 0,
               '$token' => $self->{token}
             };

  my $res =
    $self->{ua}->post( $self->{use_ssl}
                       ? "https://$self->{people_api}"
                       : "http://$self->{people_api}",
                       { 'data' => encode_base64( $self->{json}->encode($data), '' ) } );


}

sub people_track_charge{
  my ( $self, $distinct_id, $amount ) = @_;

  die "Distinct User Id required" unless $distinct_id;

  return $self->people_append_transactions( $distinct_id, '$time' => time(), '$amount' => $amount);
}


sub track {
  my ( $self, $event, %params ) = @_;

  die "You must provide an event name" unless $event;

  $params{time} ||= time();
  $params{token} = $self->{token};

  my $data = { event      => $event,
               properties => \%params, };

  my $res =
    $self->{ua}->post( $self->{use_ssl}
                       ? "https://$self->{track_api}"
                       : "http://$self->{track_api}",
                       { 'data' => encode_base64( $self->{json}->encode($data), '' ) } );

  if ( $res->is_success ) {
    if ( $res->content == 1 ) {
      return 1;
    }
    else {
      die "Failure from api: " . $res->content;
    }
  }
  else {
    die "Failed sending event: " . $self->_res($res);
  }
} # end track

sub data {
  my $self    = shift;
  my $methods = shift;
  my %params  = @_;

  $methods = [$methods] if !ref($methods);
  my $api_methods = join( '/', @$methods );

  $self->_data_params_to_json( $api_methods, \%params );

  $params{format} ||= 'json';
  $params{expire} = time() + $self->{data_api_default_expire_seconds}
    if !defined( $params{expire} );
  $params{api_key} = $self->{api_key} || die 'API Key must be specified for data requests';
  my $api_secret = $self->{api_secret} || die 'API Secret must be specified for data requests';

  my $sig = $self->_create_sig( $api_secret, \%params );
  $params{sig} = $sig;

  my $url =
    $self->{use_ssl}
    ? "https://$self->{data_api}"
    : "http://$self->{data_api}";
  $url .= $api_methods;

  # We have to hand-build the url because HTTP::REQUEST/HEADER was
  # changing underscores and capitalization, and Mixpanel is sensitive
  # about such things.
  my $ps = join( '&', map {"$_=$params{$_}"} sort keys %params );
  my $res = $self->{ua}->get( $url . '/?' . $ps );

  if ( $res->is_success ) {
    my $reso = $res->content;
    $reso = $self->{json}->decode($reso) if $params{format} eq 'json';
    return $reso;
  }
  else {
    die "Failed sending event: " . $self->_res($res);
  }
} # end data

# Calculate data request signature according to spec.
sub _create_sig {
  my $self       = shift;
  my $api_secret = shift;
  my $params     = shift;

  require Digest::MD5;
  my $pstr = join( '', map { $_ . '=' . $params->{$_} } sort keys %$params ) . $api_secret;
  return Digest::MD5::md5_hex($pstr);
}

sub _data_params_to_json {
  my $self   = shift;
  my $api    = shift;
  my $params = shift;

  # A few API calls require json encoded arrays, so transform those here.
  my $toj;
  if ( $api eq 'events' ) {
    $toj = 'event';
  }
  if ( $api eq 'events/properties' ) {
    $toj = 'values';
  }
  if ( $api eq 'arb_funnels' ) {
    $toj = 'events';
  }

  if ( $toj && defined( $params->{$toj} ) ) {
    $params->{$toj} = [ $params->{$toj} ] if !ref( $params->{$toj} );
    $params->{$toj} = $self->{json}->encode( $params->{$toj} );
  }

} # end _data_params_to_json

sub _res {
  my ( $self, $res ) = @_;

  if ( $res->code == 500 ) {
    return "Mixpanel service error. The service might be down.";
  }
  elsif ( $res->code == 400 ) {
    return "Bad Request Elements: " . $res->content;
  }
  else {
    return "Unknown error. " . $res->message;
  }
}

1;

__END__

=pod

=head1 NAME

WWW::Mixpanel

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use WWW::Mixpanel;
  my $mp = WWW::Mixpanel->new( '1827378adad782983249287292a', 1 );
  $mp->track('login', distinct_id => 'username', mp_name_tag => 'username', source => 'twitter');

or if you also want to access the data api

  my $mp = WWW::Mixpanel->new(<API TOKEN>,1,<API KEY>,<API SECRET>);
  $mp->track('login', distinct_id => 'username', mp_name_tag => 'username', source => 'twitter');
  my $enames = $mp->data( 'events/names', type => 'unique' );
  my $fdates = $mp->data( 'funnels/dates',
                 funnel => [qw/funnel1 funnel2/],
                 unit   => 'week' );

=head1 DESCRIPTION

The WWW::Mixpanel module is an implementation of the L<http://mixpanel.com> API which provides realtime online analytics. L<http://mixpanel.com> receives events from your application's perl code, javascript, email open and click tracking, and many more sources, and provides visualization and publishing of analytics.

Currently, this module mirrors the event tracking API (L<http://mixpanel.com/api/docs/specification>), and will be extended to include the powerful data access and platform parts of the api. B<FEATURE REQUESTS> are always welcome, as are patches.

This module is designed to die on failure, please use something like Try::Tiny.

=head1 NAME

WWW::Mixpanel

=head1 VERSION

version 0.07

=head1 NAME

WWW::Mixpanel

=head1 VERSION

version 0.07

=head1 METHODS

=head2 new( $token, [$use_ssl] )

Returns a new instance of this class. You must supply the API token for your mixpanel project. HTTP is used to connect unless you provide a true value for use_ssl.

=head2 track('<event name>', [time => timestamp, param => val, ...])

Send an event to the API with the given event name, which is a required parameter. If you do not include a time parameter, the value of time() is set for you automatically. Other parameters are optional, and are included as-is as parameters in the api.

This method returns 1 or dies with a message.

Per the Mixpanel API, a 1 return indicates the event reached the mixpanel.com API and was properly formatted. 1 does not indicate the event was actually written to your project, in cases such as bad API token. This is a limitation of the service.

You are strongly encouraged to use something like C<Try::Tiny> to wrap calls to this API.

Today, there is no way to set URL parameters such as ip=1, callback, img, redirect. You can supply ip as a parameter similar to distinct_id, to track users.

=head2 data('<path/path>', param => val, param => val ...)

Obtain data from mixpanel.com using the L<Data API|http://mixpanel.com/api/docs/guides/api/v2>.
The first parameter to the method identifies the path off the api root.

For example to access the C<events/top> functionality, found at L<http://mixpanel.com/api/2.0/events/top/>, you would pass the string C<events/top> to the data method.

Some parameters of the data api are of array type, for example C<events/retention> parameter C<event>. In every case where a parameter is of array type, you may supply the parameter as either an ARRAYREF or a single string.

Unless specified as a parameter, the default return format is json.
This method will then return the result of the api call as a decoded perl object.

If you specify format => 'csv', this method will return the csv return string unchanged.

This method will die on errors, including malformed parameters, indicated by bad return codes from the api. It dies with the text of the api reply directly, often a json string indicating which parameter was malformed.

I<To see all API methods at work, look into the module tests.>

=head2 people_set('distinct_id', param => val, param => val ...)

Sets people properties on a distinct_id

=head2 people_increment('distinct_id', param => val, param => val ...)

Increments people properties on a distinct_id

=head2 people_track_charge('distinct_id', charge_amount)

Tracks a revenue event for specific charge amount

=head1 TODO

=over 4

=item /track to accept array of events

Track will soon be able to accept many events, and will bulk-send them to mixpanel in one call if possible.

=item /platform support

The Platform API will be supported. Let me know if this is a feature you'd like to use.

=back

=head1 FEATURE REQUESTS

Please send feature requests to me via rt or github. Patches are always welcome.

=head1 BUGS

Do your thing on CPAN.

=head1 AFFILIATION

I am not affiliated with mixpanel, I just use and like the service.

=head1 AUTHOR

Tom Eliaz

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tom Eliaz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Tom Eliaz

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tom Eliaz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Tom Eliaz

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tom Eliaz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
