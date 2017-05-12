#!/usr/bin/perl
# $Revision: 1.7 $
use strict;
use warnings;
use Weather::Com::Finder;

# autoflush
$| = 1;

# have a cvs driven version...
our $VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /(\d+)/g;

# you have to fill in your ids from weather.com here
my $PartnerId  = '';
my $LicenseKey = '';

# you can preset units of messures here
# (m for metric (default), s for us)
my $units    = 'm';
my $language = 'de';

# if you need a proxy... maybe with authentication
my $Proxy      = '';
my $Proxy_User = '';
my $Proxy_Pass = '';

# debugging on/off
my $debugmode = 0;
if ( $ARGV[0] && ( $ARGV[0] eq "-d" ) ) {
	warn "Debug mode turned on.\n";
	$debugmode = 1;
}

my %weatherargs = (
					'partner_id' => $PartnerId,
					'license'    => $LicenseKey,
					'units'      => $units,
					'debug'      => $debugmode,
					'proxy'      => $Proxy,
					'proxy_user' => $Proxy_User,
					'proxy_pass' => $Proxy_Pass,
					'language'   => $language,
);

# This is a global var for dynamic language test
# it can be set from within the program like
# 'set language de_DE'
my $dyn_lang = undef;    # dynamic language, to be changed

# my weather finder instance
my $weather_finder = Weather::Com::Finder->new(%weatherargs);

# print greeting
print "\nWelcome to Uncle Tom's weather station, extended edition...\n";
print "This is V$VERSION\n";
print "\nPlease enter a location name to look for, e.g\n";
print "'Heidelberg' or 'Seattle, WA', or 'Munich, Germany'\n\n";
print "Additional commands are:\n";
print "  'end'                     to quit this program\n";
print "  'set language <lang_tag>' to dynamically change the language\n";
print "  'language'                to get the current languages tag\n";
print "  'reset language'          to change back to your default language\n\n";

# define prompt
my $prompt = '$> ';
print $prompt;

while ( chomp( my $input = <STDIN> ) ) {

	# don't want any empty input
	unless ( $input =~ /\S+/ ) {
		print $prompt;
		next;
	}

	# handle dynamic language
	if ( $input =~ /^set language (.+)$/ ) {
		$dyn_lang = $1;
		print $prompt;
		next;
	}
	if ( $input =~ /^reset language$/ ) {
		$dyn_lang = undef;
		print $prompt;
		next;
	}
	if ( $input =~ /^language$/ ) {
		print $dyn_lang || $language, "\n";
		print $prompt;
		next;
	}

	# and if the user wants to exit...
	last if ( $input =~ /^end|quit|exit|:q$/ );

	# search for matching locations
	my $locations = $weather_finder->find($input);

	# if $weather_finder->find() returned 0, we haven't found anything...
	unless ($locations) {
		print "No weather found for location '$input'\n";
		print $prompt;
		next;
	}

	# if we found anything we'll print it out...
	print "\nFound weather data for " . @{$locations} . " locations:\n\n";

	# define all units of measure (we can use the units of the first location
	# because they should all be equal...)
	my $uodist   = $locations->[0]->units()->distance();
	my $uoprecip = $locations->[0]->units()->precipitation();
	my $uopress  = $locations->[0]->units()->pressure();
	my $uotemp   = $locations->[0]->units()->temperature();
	my $uospeed  = $locations->[0]->units()->speed();

	foreach my $location ( @{$locations} ) {

		# print a nice heading underlined by '===='
		my $heading = "This is the data for " . $location->name() . "\n";
		print $heading;
		print "=" x length($heading), "\n";

		# print location data
		print " * this city is located at: ", $location->latitude(), "deg N, ",
		  $location->longitude(), "deg E\n";
		print " * local time is ", $location->localtime()->time(), "\n";
		print " * sunrise will be/has been at ", $location->sunrise()->time(),
		  "\n";
		print " * sunset (am/pm) will be/has been at ",
		  $location->sunset()->time_ampm(), "\n";
		print " * timezone is GMT + ", $location->timezone(), "hour(s)\n";

		# current conditions
		print "\nCurrent Conditions (last update ",
		  $location->current_conditions()->last_updated()->time(), " on ",
		  $location->current_conditions()->last_updated()
		  ->formatted('dd.mm.yyyy'), "):\n";
		print " * current conditions are ",
		  $location->current_conditions()->description($dyn_lang), ".\n";
		print " * visibilty is about ",
		  $location->current_conditions()->visibility(), " $uodist.\n";
		print " * and the temperature is ",
		  $location->current_conditions()->temperature(), "deg $uotemp.\n";
		print " * the current windchill is ",
		  $location->current_conditions()->windchill(), "deg $uotemp.\n";
		print " * the humidity is ",
		  $location->current_conditions()->humidity(), "\%.\n";
		print " * the dewpoint is ",
		  $location->current_conditions()->dewpoint(), "deg $uotemp.\n";

		# all about wind
		print " * wind speed is ",
		  $location->current_conditions()->wind()->speed(), " $uospeed.\n";
		print " * wind comes from ",
		  $location->current_conditions()->wind()->direction_long($dyn_lang),
		  ".\n";
		print "   ... in short ",
		  $location->current_conditions()->wind()->direction_short($dyn_lang),
		  ".\n";
		print "   ... in degrees ",
		  $location->current_conditions()->wind()->direction_degrees(), ".\n";
		print "   ... max. gust ",
		  $location->current_conditions()->wind()->maximum_gust(),
		  " $uospeed.\n";

		# all about uv index
		print " * uv index is ",
		  $location->current_conditions()->uv_index()->index(), ".\n";
		print "   ... that is ",
		  $location->current_conditions()->uv_index()->description($dyn_lang),
		  ".\n";

		# all about barometric pressure
		print " * air pressure is ",
		  $location->current_conditions()->pressure()->pressure(),
		  " $uopress.\n";
		print "   ... tendency ",
		  $location->current_conditions()->pressure()->tendency(), ".\n";

		# moon...
		print " * moon phase is ",
		  $location->current_conditions()->moon()->description($dyn_lang), "\n";

		# forecasts
		my $forecast = $location->forecast();
		my $today    = $forecast->day(0);

		print "Today:\n";
		print "... day of week: ", $today->date()->weekday(), ", ",
		  $today->date()->date(), "\n";
		if ( $today->high() ) {
			print "... max temp:    ", $today->high(), "\n";
		}
		print "... min temp:    ", $today->low(), "\n";
		print "... sunrise:     ", $today->sunrise()->time(), "\n";
		print "... sunset:      ", $today->sunset()->time(),  "\n";

		print "Daytime data:\n";
		if ( $today->day() ) {
			print "... conditions:     ", $today->day()->conditions($dyn_lang),
			  "\n";
			print "... humidity:       ", $today->day()->humidity(),      "\n";
			print "... precipitation:  ", $today->day()->precipitation(), "\n";
			print "... wind speed:     ", $today->day()->wind()->speed(), "\n";
			print "... max gust:       ", $today->day()->wind()->maximum_gust(),
			  "\n";
			print "... wind dir: ",
			  $today->day()->wind()->direction_long($dyn_lang), "\n";
			print "... wind dir: ", $today->day()->wind()->direction_degrees(),
			  "\n";
		}
		print "Nightly data:\n";
		print "... conditions:     ", $today->night()->conditions($dyn_lang),
		  "\n";
		print "... humidity:       ", $today->night()->humidity(),      "\n";
		print "... precipitation:  ", $today->night()->precipitation(), "\n";
		print "... wind speed:     ", $today->night()->wind()->speed(), "\n";
		print "... max gust:       ", $today->night()->wind()->maximum_gust(),
		  "\n";
		print "... wind dir: ",
		  $today->night()->wind()->direction_long($dyn_lang), "\n";
		print "... wind dir: ", $today->night()->wind()->direction_degrees(),
		  "\n";

		foreach my $day ( $forecast->all() ) {
			print "Have forecast for ", $day->date()->weekday(), ", ",
			  $day->date()->date(), "\n";
			print "Max Temp is ", $day->high(), "\n";
			print "Min Temp is ", $day->low(),  "\n";
			print "Percent chance of precipitation at night: ",
			  $day->night()->precipitation(), "\%\n";
			print "\n";
		}

		print "\n";
	}

	# last but not least print the next prompt
	print $prompt;
}

__END__

=pod

=head1 NAME

weather_ext.pl - Sample script to show the usage of the OO API of I<Weather::Com>

=head1 SYNOPSIS

  #> ./weather_ext.pl [-d]
  
  Welcome to Uncle Tom's weather station, extended edition...
  This is V1.006

  Please enter a location name to look for, e.g
  'Heidelberg' or 'Seattle, WA', or 'Munich, Germany'

  Additional commands are:
    'end'                     to quit this program
    'set language <lang_tag>' to dynamically change the language
    'language'                to get the current languages tag
    'reset language'          to change back to your default language
  
  $>

=head1 DESCRIPTION

**IMPORTANT** You first have to register at I<weather.com> to get a
partner id and a license key for free. Please visit their web site
L<http://www.weather.com/services/xmloap.html>. Then edit this script
and fill in the data into the corresponding variables at the top of 
the script.

The sample script I<weather.pl> asks you for a location name - either 
a city or a 'city, region' or 'city, country' combination. It then uses 
the I<Weather::Com> OO API to get location information, current weather
conditions and 9 days of weahter forecast for this location(s).

If no location matching your input is found, a "no locations found" 
message is printed out.

Else, the number of locations found is printed followed by nicely
formatted weather data for each location.

The command line parameter '-d' enables debugging mode (which is
enabling debugging within all used packages.

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Thomas Schnuecker

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
