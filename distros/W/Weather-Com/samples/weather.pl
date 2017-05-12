#!/usr/bin/perl -w
# $Revision: 1.12 $
use strict;
use Weather::Com::Simple;

$| = 1;

# have a cvs driven version...
our $VERSION = sprintf "%d.%03d", q$Revision: 1.12 $ =~ /(\d+)/g;

# you have to fill in your ids from weather.com here
my $PartnerId  = '';
my $LicenseKey = '';

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
					'debug'      => $debugmode,
					'proxy'      => $Proxy,
					'proxy_user' => $Proxy_User,
					'proxy_pass' => $Proxy_Pass,
);

# print greeting
print "\nWelcome to Uncle Tom's weather station...\n";
print "This is V$VERSION\n";
print "\nPlease enter a location name to look for, e.g\n";
print "'Heidelberg' or 'Seattle, WA', or 'Munich, Germany'\n\n";

# define prompt
my $prompt = '$> ';
print $prompt;

while ( chomp( my $input = <STDIN> ) ) {

	# don't want any empty input
	unless ( $input =~ /\S+/ ) {
		print $prompt;
		next;
	}

	# and if the user wants to exit...
	last if ( $input =~ /^end|quit|exit$/ );

	# add place to config hash and get weather
	$weatherargs{'place'}      = $input;

	my $ws      = Weather::Com::Simple->new(%weatherargs);
	my $weather = $ws->get_weather();

	# if $ws->get_weather() returned 'undef', we haven't found anything...
	unless ($weather) {
		print "No weather found for location '$input'\n";
		print $prompt;
		next;
	}

	# if we found anything we'll print it out...
	# Weather::Simple allways returns an arrayref. maybe we found more
	# than 1 location's weather
	print "\nFound weather data for "
	  . ( $#{$weather} + 1 )
	  . " locations:\n\n";
	foreach my $location_weather ( @{$weather} ) {

		# print a nice heading underlined by '===='
		my $heading =
		  "These are the current conditions for "
		  . $location_weather->{place} . "\n";
		print $heading;
		print "=" x length($heading), "\n";

		# print weather data we're interested in
		print " * current conditions are ", $location_weather->{conditions},
		  "\n";
		print " * the current temperature is ",
		  $location_weather->{temperature_celsius}, " degrees celsius\n";
		print " * the current windchill is ",
		  $location_weather->{windchill_celsius}, " degrees celsius\n";
		print " * wind is ",         $location_weather->{wind},     "\n";
		print " * humidity is ",     $location_weather->{humidity}, "%\n";
		print " * air pressure is ", $location_weather->{pressure}, "\n";
		print "   => this data has been updated on ",
		  $location_weather->{updated}, "\n\n";
	}

	# last but not least print the next prompt
	print $prompt;
}

__END__

=pod

=head1 NAME

weather.pl - Sample script to show the usage of the I<Weather::Com::Simple>
module

=head1 SYNOPSIS

  #> ./weather.pl [-d]
  
  Welcome to Uncle Tom's weather station...
  
  Please enter a location name to look for, e.g
  'Heidelberg' or 'Seattle, WA', or 'Munich, Germany'
  
  Type 'end' to exit.
  
  $>

=head1 DESCRIPTION

**IMPORTANT** You first have to register at I<weather.com> to get a
partner id and a license key for free. Please visit their web site
L<http://www.weather.com/services/xmloap.html>. Then edit this script
and fill in the data into the corresponding variables at the top of 
the script.

The sample script I<weather.pl> asks you for a location name - either 
a city or a 'city, region' or 'city, country' combination. It then uses 
the I<Weather::Com::Simple> module to get the current weather conditions 
for this location(s).

If no location matching your input is found, a "no locations found" 
message is printed out.

Else, the number of locations found is printed followed by nicely
formatted weather data for each location.

The command line parameter '-d' enables debugging mode (which is
enabling debugging within all used packages (Weather::Com::Simple,
Weather::Com::Cached, Weather::Com::Base).

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Thomas Schnuecker

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
