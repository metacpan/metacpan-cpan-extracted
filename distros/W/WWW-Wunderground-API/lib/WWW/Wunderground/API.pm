package WWW::Wunderground::API;

use 5.006;
use Moo;
use URI;
use JSON::MaybeXS;
use LWP::Simple;
use XML::Simple;
use Hash::AsObject;

=head1 NAME

WWW::Wunderground::API - Use Weather Underground's JSON/XML API

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

has location => (is=>'rw', required=>1);
has api_key => (is=>'ro', default=>sub { $ENV{WUNDERGROUND_API}||$ENV{WUNDERGROUND_KEY} });
has api_type => (is=>'rw', lazy=>1, default=>sub { $_[0]->api_key ? 'json' : 'xml' });
has cache => (is=>'ro', lazy=>1, default=>sub { WWW::Wunderground::API::BadCache->new });
has auto_api => (is=>'ro', default=> sub {0} );
has raw => (is=>'rw', default=>sub{''});
has lang => (is=>'rw', default=>'EN');
has data => (is=>'rw', lazy=>1, default=>sub{ Hash::AsObject->new } );

sub json {
  my $self = shift;
  return $self->api_type eq 'json' ? $self->raw : undef;
}

sub xml {
  my $self = shift;
  return $self->api_type eq 'xml' ? $self->raw : undef;
}


sub update {
  my $self = shift;
  if ($self->api_key) {
    $self->api_call('conditions');
  } else {
    my $legacy_url = 'http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query='.$self->location;
    my $xml;
    unless($xml = $self->cache->get($legacy_url)) {
      $xml = get($legacy_url);
      $self->cache->set($legacy_url,$xml);
    }
    if ($xml) {
      $self->raw($xml);
      $self->data(Hash::AsObject->new({conditions=>XMLin($xml)}));
    }
  }
}

sub _guess_key {
  my $self = shift;
  my ($struc,$action) = @_;

  #try to guess result structure key
  return $action if defined($struc->{$action});
  foreach my $key (keys %$struc) {
    next if $key=~ /(response|features|version|termsofservice)/i;
    return $key;
  }
}

sub api_call {
  my $self = shift;
  my $action = shift;

  my %params;

  if (scalar(@_) == 1) {
    if (ref($_[0])) {
      (%params) = %{$_[0]};
    } else {
      $params{location} = $_[0];
    }
  } elsif (scalar(@_) > 1) {
    (%params) = @_;
  }
  my $location = delete $params{location} || $self->location;
  my $format = delete $params{format}
    || ($action=~/(radar|satellite)/
      ? 'gif'
      : $self->api_type);

  if ($self->api_key) {
    my $base = 'http://api.wunderground.com/api';
    my $url = URI->new(join('/', $base,$self->api_key,$action,'lang:'.uc($self->lang),'q',$location).".$format");
    $url->query_form(%params);

    my $result;
    my $url_string = $url->as_string();
    unless ($result = $self->cache->get($url_string)) {
      $result = get($url_string);
      $self->cache->set($url_string,$result);
    }

    $self->raw($result);

    if ($format !~ /(json|xml)/) {
      $self->data->{$action} = $self->raw();
      return $self->raw();
    }

    my $struc = $format eq 'json'
      ? decode_json($self->raw)
      : XMLin($self->raw);


    my $action_key = $self->_guess_key($struc,$action);

    $struc = $struc->{$action_key} if $action_key;
    $self->data->{$action} = $struc;

    return
      ref($struc) eq "HASH" ?
        Hash::AsObject->new($struc) :
        $struc;
  } else {
    warn "Only basic weather conditions are supported using the deprecated keyless interface";
    warn "please visit http://www.wunderground.com/weather/api to obtain your own API key";
  }
}


around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  if (@_ == 1 and !ref($_[0])) {
    return $class->$orig( location=>$_[0] );
  } else {
    return $class->$orig(@_);
  }
};

sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ /::(\w+)$/;
  my $val = $self->data->$key;

  unless ($val) {
    $self->update if ($self->auto_api and !$self->data->conditions);
    $val = $self->data->conditions->$key if $self->data->conditions;
  }

  if (defined($val)) {
    return $val;
  } else {
    return $self->api_call($key,@_) if $self->auto_api;
    warn "$key is not defined. Is it a valid key, and is data actually loading?";
    warn "If you're trying to autoload an endpoint, set auto_api to something truthy";
    return undef;
  }
}

sub DESTROY {}

__PACKAGE__->meta->make_immutable;


#The following exists purely as an example for others of what not to do.
#Use a L<Cache::Cache> or L<CHI> Cache. Really.
package WWW::Wunderground::API::BadCache;
use Moo;

has store=>(is=>'rw', lazy=>1, default=>sub{{}});

sub get {
  my $self = shift;
  my ($key) = @_;
  if (exists($self->store->{$key})) {
    return $self->store->{$key};
  }
  return undef;
}

sub set {
  my $self = shift;
  my ($key, $val) = @_;
  $self->store->{$key} = $val;
  return $val;
}


=head1 SYNOPSIS

Connects to the Weather Underground JSON/XML service and parses the response data
into something usable.

The entire response is available in L<Hash::AsObject> form, so
any data that comes from the server is accessible.
Print a dump of L</"data()"> to see all of the tasty data bits available.

    use WWW::Wunderground::API;

    # location
    my $wun = new WWW::Wunderground::API('Fairfax, VA');

    # or zipcode
    my $wun = new WWW::Wunderground::API('22030');

    # or airport identifier
    my $wun = new WWW::Wunderground::API('KIAD');

    # exercise several options

    my $wun = new WWW::Wunderground::API(
      location => '22152',
      api_key => 'my wunderground api key',
      auto_api => 1,
      lang => 'FR',
      cache => Cache::FileCache->new({ namespace=>'wundercache', default_expires_in=>2400 }) #A cache is probably a good idea.
    );


    # Check the wunderground docs for details, but here are just a few examples

    # the following $t1-$t6 are all equivalent:
    $wun->location(22152);

    $t1 = $wun->api_call('conditions')->temp_f
    $t2 = $wun->api_call('conditions', 22152)->temp_f
    $t3 = $wun->api_call('conditions', {location=>22152})->temp_f
    $t4 = $wun->api_call('conditions', location=>22152)->temp_f
    $t5 = $wun->conditions->temp_f
    $t6 = $wun->temp_f

    # simple current conditions
    print 'The temperature is: '.$wun->conditions->temp_f."\n";
    print 'The rest of the world calls that: '.$wun->conditions->temp_c."\n";

    # radar/satellite imagery
    my $sat_gif = $wun->satellite; #image calls default to 300x300 gif
    my $rad_png = $wun->radar( format=>'png', width=>500, height=>500 ); #or pass parameters to be specific
    my $rad_animation = $wun->animatedsatellite(); #animations are always gif

    # almanac / forecast / more.
    print 'Record high temperature year: '.$wun->almanac->temp_high->recordyear."\n";
    print "Sunrise at:".$wun->astronomy->sunrise->hour.':'.$wun->astronomy->sunrise->minute."\n";
    print "Simple forecast:".$wun->forecast->simpleforecast->forecastday->[0]{conditions}."\n";
    print "Text forecast:".$wun->forecast->txt_forecast->forecastday->[0]{fcttext}."\n";
    print "Long range forecast:".$wun->forecast10day->txt_forecast->forecastday->[9]{fcttext}."\n";
    print "Chance of rain three hours from now:".$wun->hourly->[3]{pop}."%\n";
    print "Nearest airport:".$wun->geolookup->nearby_weather_stations->airport->{station}[0]{icao}."\n";

    # Conditions is autoloaded into the root of the object
    print "Temp_f:".$wun->temp_f."\n";

=head1 METHODS/ACCESSORS

=head2 update()

Included for backward compatibility only.
Refetches conditions data from the server. It will be removed in a future release.
If you specify an api_key then this is equivalent of ->api_call('conditions') and is subject to the same cache

=head2 location()

Set the location. For example:

    my $wun = new WWW::Wunderground::API('22030');
    my $ffx_temp = $wun->conditions->temp_f;

    $wun->location('KJFK');
    my $ny_temp = $wun->conditions->temp_f;

    $wun->location('San Diego, CA');
    my $socal_temp = $wun->conditions->temp_f;

Valid locations can be derived from others by calling the geolookup endpoint, but you probably already know where you are.


=head2 auto_api

set auto_api to something truthy to have the module automatically make API calls without the use of api_call()


=head2 api_call( api_name, <location> )

Set api_name to any location-based wunderground api call (almanac,conditions,forecast,history...).

Location is optional and defaults to L</"location()">. Can be any valid location (eg 22152,'KIAD','q/CA/SanFrancisco',...)

    #Almanac data for 90210
    $wun->api_call('almanac','90210');

    #If auto_api=>1 the following is equivalent
    $wun->location(90120);
    $wun->almanac;

    #10 day forecast for New York
    $wun->api_call('forecast10day'','KJFK');


=head2 lang()

Set/Get current language for the next API call.
The default language is 'EN'. See the wunderground API doc for a list of available languages.

=head2 raw()

Returns raw text result from the most recent API call. This will be either xml or json depending on api_type.
You can also set this to whatever json/xml you'd like, though I can't imagine why you'd want to.

=head2 cache()

Specify a cache object. Needs only to satisfy get(key) and set(key,value) interface.
Any L<Cache::Cache> or L<CHI> cache should work.

=head2 xml()

*Deprecated* - use L</"raw()"> instead.

Returns raw xml result from wunderground server where applicable


=head2 json()

*Deprecated* - use L</"raw()"> instead.

Returns raw json result from wunderground server where applicable

=head2 data()

Contains all weather data from server parsed into convenient L<Hash::AsObject> form;

=head2 api_key()

Required for JSON api access. Defaults to $ENV{WUNDERGROUND_API}

=head2 api_type()

Defaults to json. If no api_key is specified it will be set to xml and only basic weather conditions will be available.

=head1 AUTHOR

John Lifsey, C<< <nebulous at crashed.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-wunderground-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Wunderground-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SOURCE

Better yet, fork on github and send me a pull request:
L<https://github.com/nebulous/WWW-Wunderground-API>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Wunderground::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Wunderground-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Wunderground-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Wunderground-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Wunderground-API/>

=back

=head1 SEEALSO

If you'd like to scrape from Weather Underground rather than have to use the API, see L<Weather::Underground>.
WWW::Wunderground::API only supports current conditions without an API key.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 John Lifsey.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable;
1; # End of WWW::Wunderground::API
