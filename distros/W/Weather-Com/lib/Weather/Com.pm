package Weather::Com;

use 5.006;
use strict;
use warnings;
use Carp;
use Weather::Com::Cached;
use Weather::Com::Location;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)/g;


#--------------------------------------------------------------------
# This is just a dummy package containing POD
#
# Weather::Com.pod has been removed and this package has been added
# to make Weather-Com work with CPAN shell.
# 
# Therefore, the whole tutorial went into this file.
# Weather::Com.pod is no longer maintained.
#--------------------------------------------------------------------


1;

=pod

=head1 NAME

Weather::Com - fetching weather information from I<weather.com>

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use Weather::Com::Finder;

  # you have to fill in your ids from weather.com here
  my $PartnerId  = 'somepartnerid';
  my $LicenseKey = 'mylicense';

  my %weatherargs = (
	'partner_id' => $PartnerId,
	'license'    => $LicenseKey,
	'language'   => 'de',
  );

  my $weather_finder = Weather::Com::Finder->new(%weatherargs);
  
  my @locations = $weather_finder->find('Heidelberg');
  
  foreach my $location (@locations) {
    print "Found weather for city: ", $location->name(), "\n";
    print "Current Conditions are ", 
      $location->current_conditions()->description(), "\n";
  }

=head1 DESCRIPTION

I<Weather::Com> provides three interfaces to access weather
information from I<weather.com>. 

Except from the main high level interface, there is also
a simple, very easy to use one called I<Weather::Com::Simple>.
And if you want, you can also use the low level
interface that is the basis for the two high level interfaces,
directly (I<Weather::Com::Cached> or even I<Weather::Com::Base>).

Please refer to the POD of these modules directly for detailed
information.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. Please have a look 
at the application programming guide of I<weather.com> 
L<http://www.weather.com/services/xmloap.html>

=head1 LOCALIZATION

Weather-Com uses I<Locale::Maketext> for the l10n. Foreach language there
has to be package I<Weather::Com::L10N::[langcode]> (e.g. I<Weather::Com::L10N::de>).

Localization is new with version 0.4 of Weather-Com. Therefore, there are not too
many languages supported, yet. If one wants to create such a language definition package
for a language that is not part of this module, please do the following:

=over 4

=item 1.

check my homepage to verify that the language package has not been created by someone
else, yet (L<http://www.schnuecker.org/index.php?weather-com>).

=item 2.

contact me to verify if anybody else already is already translating into this language

=item 3.

just do it and send me your new language package. It then will be first put onto my
website for download and then it will be part of the next release.

=back

=head2 Dynamic Language Support

With version 0.5 of Weather-Com I have introduced a new feature called 
I<dynamic language support>.

The language for all textual attributes that usually are translated in your default 
language you chose while creating your C<Weather::Com::Finder> instance can now
dynamically be changed on a I<per-method-call basis>.

Have a look at this example:

  #!/usr/bin/perl -w
  use Weather::Com::Finder;

  # you have to fill in your ids from weather.com here
  my $PartnerId  = 'somepartnerid';
  my $LicenseKey = 'mylicense';

  my %weatherargs = (
	'partner_id' => $PartnerId,
	'license'    => $LicenseKey,
	'language'   => 'en',
  );

  my $weather_finder = Weather::Com::Finder->new(%weatherargs);
  
  my @locations = $weather_finder->find('Heidelberg');
  
  foreach my $location (@locations) {
    print "Found weather for city: ", $location->name(), "\n";
    print "Current Conditions are ", 
      $location->current_conditions()->description(), "\n";
      
    # HERE WE USE DYNAMIC LANGUAGE SUPPORT
    print "That is in German: ",
      $location->current_conditions()->description('de'), "\n";
  }

As you can see in this example, you can provide a language tag to
a method that returns textual information.

If you want to find out if the I<dynamic language support> is already
implemented for a specific attribute of one Weather-Com class, have
a look at the corresponding packages POD.

=head1 TUTORIAL

The usual way to use the I<Weather::Com> module would be to instantiate
a I<Weather::Com::Finder> that allows you to search for a location
by a search string or postal code or whatever I<weather.com> may
understand.

The finder returns an arrayref or an array of locations (depending on 
how you call the C<find()> method). Each location is an object of
I<Weather::Com::Location>. 

The locations consist of location specific data, 
a I<Weather::Com::CurrentConditions> object, a I<Weather::Com::Forecast>
object and a I<Weather::Com::Units> object. 

=head2 Configuration parameters

You will need a configuration hash to instantiate a I<Weather::Com::Finder>
object. Except of the I<partner_id> and the I<license> all parameters are
optional and have sensible defaults. 

  use Weather::Com::Finder;

  my %config = (
  	partner_id => 'somepartnerid',	# mandatory
  	license    => 'somelicensekey'	# mandatory
  	language   => 'de',
  	units      => 's',
   	cache      => '/tmp/weather',
   	timeout    => 300,
   	debug      => 1,
  	proxy      => 'http://some.proxy.de:8080',
  	proxy_user => 'myaccount',
  	proxy_pass => 'myproxy_pass'
  );

The valid parameters are:

=over 4

=item partner_id => 'somepartnerid'

To be allowed to fetch weather information from I<weather.com> you need to
register (free of charge) to get a so called I<Partner Id> and a 
I<License Key>. 

=item license => 'somelicensekey'

See I<partner_id>.

=item language => 'somelanguagecode'

I<weather.com> returns some textual data to describe the weather
conditions, uv index, moon phase, wind direction, etc.

If one specifies a valid language as configuration parameter, this
textual descriptions are translated into that language. If one specifies
a language for that there's no translation, the objects will return the
english texts.

=item cache => '/any/path'

Maybe you want to define a special path to put the cache files into.
The cache directory defaults to ".".

=item units => s | m

This parameter defines whether to fetch information in metric (m) or 
US (s) format. 

Defaults to 'm'.

=item timeout => some integer (in seconds)

The timeout for I<LWP::UserAgent> to get an HTTP request done usually is set to
180s. If you need a longer timeout or for some reasons a shorter one you can
set this here.

Defaults to 180 seconds.

=item debug => 0 | 1

Set debugging on/off.

Defaults to 0 (off).

=item proxy => 'none' | 'http://some.proxy.de:8080'

Usually no proxy is used by the I<LWP::UserAgent> module used to communicate
with I<weather.com>. If you want to use an HTTP proxy you can specify one here.

=item proxy_user => undef | 'myuser'

If specified, this parameter is provided to the proxy for authentication
purposes.

Defaults to I<undef>.

=item proxy_pass => undef | 'mypassword'

If specified, this parameter is provided to the proxy for authentication
purposes.

Defaults to I<undef>.

=back 

=head2 Weather::Com::Finder

Usually one would start by searching for a location. This is done by
instantiating a I<Weather::Com::Finder> object providing all necessary
information about the I<weather.com> license, the proxy if one is needed,
etc.  

  my $finder = Weather::Com::Finder->new(%config);

Then you call the finders C<find()> method to search for locations whose
name or whose postal code matches against the searchstring. The finder then
returns an array (or arrayref) of I<Weather::Com::Location> objects.

  # if you want an array of locations:
  my @locations = $finder->find('Heidelberg');
  
  # or if you prefer an arrayref:
  my $locations = $finder->find('Heidelberg');

For further information please refer to L<Weather::Com::Finder>.

=head2 Weather::Com::Location

The I<Weather::Com::Location> object contains information about the location
itself (longitude, latitude, current local time, etc.), a I<Weather::Com::Units> 
object that contains all information about the units of messures currently used with
this location, and a I<Weather::Com::CurrentConditions> object containing the
current weather conditions of the location.

  foreach my $location (@locations) {
  	print "Found location with name: ", $location->name(), "\n";
  	print "The longitude of this location is: ", $location->longitude(), "\n";
  }

All information in the I<Weather::Com::Location> object is updated with each single
call of one of its methods corresponding to the caching rules implemented in
I<Weather::Com::Cached>.

For detailed information about the I<Weather::Com::Location> class please refer to
L<Weather::Com::Location>.

=head2 Weather::Com::Units

The units class provides all units of measure corresponding to the data of the
location object. You'll get an instance of this class by calling the C<units()>
method of your location object.

For detailed information about the I<Weather::Com::Units> class please refer to
L<Weather::Com::Units>.

=head2 Weather::Com::CurrentConditions

Each location has a I<Weather::Com::CurrentConditions> object accessible via
its C<current_conditions()> method.

  my $conditions = $location->current_conditions();
  print "Current temperature is ", $conditions->temperature(), "°C\n";
  print "but it feels like ", $conditions->windchill(), "°C!\n";

Anytime you call a method of your I<Weather::Com::CurrentConditions> object,
its data is refreshed automatically if needed according to the caching rules.

For detailed information about this class please refer to
L<Weather::Com::CurrentConditions>.

=head2 Weather::Com::Forecast

Each location has a I<Weather::Com::Forecast> object to access weather
forecasts. I<weather.com> provides up to 9 days of forecast - or 10 days
if one wants to count day 0 which is I<today> in most cases.

  my $forecast = $location->forecast();
  print "Max. temperature tomorrow will be ", $forecast->day(1)->high(), "°C\n";

Any time you call a method of your I<Weather::Com::Forecast> object, forecast data
is updated if necessary.

For detailed information about this class please refer to
L<Weather::Com::Forecast>.

=head2 Other classes

There are a some other classes that are used to represent groups of
weather data like wind (speed, direction, etc.), UV index, air pressure, etc.

Objects of these classes belong to objects of class I<Weather::Com::CurrentConditions> or
I<Weather::Com::Forecast> that will be introduced with the next release. These
objects data will only refresh when you call the corresponding method of the parent object.

For detailed information about these classes please refer to their own POD.

Classes available with this version are:

=head3 Weather::Com::AirPressure

Provides access to the barometric pressure data.

For detailed information about this class please refer to
L<Weather::Com::AirPressure>.

=head3 Weather::Com::UVIndex

Provides access to the uv index of the parent object.

For detailed information about this class please refer to
L<Weather::Com::UVIndex>.

=head3 Weather::Com::Wind

Provides access to wind speed, maximum gust, direction in degrees, etc.

=head1 EXTENSIONS

If you plan to extend these module, e.g. with some other caching mechanisms,
please contact me. Perhaps we can add your stuff to this module.

=head1 SEE ALSO

=head2 Detailed documentation of the main interface

L<Weather::Com::Finder>, L<Weather::Com::Location>, L<Weather::Com::Units>,
L<Weather::Com::CurrentConditions>, L<Weather::Com::AirPressure>,
L<Weather::Com::UVIndex>, L<Weather::Com::Wind>

=head2 Detailed documentation of the I<Simple> API

L<Weather::Com::Simple>

=head2 Detailed documentation of the low level interface

L<Weather::Com::Cached> and L<Weather::Com::Base>

=head1 BUGS/SUPPORT/PRE-RELEASES

If you want to report a bug, please use the CPAN bug reporting tool.

If you have any question, suggestion, feature request, etc. please use the
CPAN forum.

If you are looking for fixes, pre-releases, etc. have a look at my website
L<http://www.schnuecker.org/index.php?weather-com>.

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com> (L<http://www.weather.com/services/xmloap.html>)

=cut
