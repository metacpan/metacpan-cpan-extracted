#!perl

use strict;
use warnings;
use Weather::Fetch;

my $w = new Weather::Fetch("F", "60608", "EN", "US", "chicago");
my $xml = $w->getXml;

sub get_weather {
	my ($type) = @_;
	my $temp = $w->getWeather($xml, $type);
	return $temp;
}

sub get_icon {
	my $str;

	if($_[0] =~ /Sunny/i || $_[0] =~ /Mostly Sunny/i || $_[0] =~ /Partly Sunny/i || $_[0] =~ /Intermittent Clouds/i || $_ [0]=~ /Hazy Sunshine/i || 
		$_[0] =~ /Hazy Sunshine/i || $_[0] =~ /Hot/i) 
	{ 
		$str = "";
	}
	elsif($_[0] =~ /Mostly Cloudy/i || $_[0] =~ /Cloudy/i || $_[0] =~ /Dreary (Overcast)/i || $_[0] =~ /Fog/i) 
	{ 
		$str = "";
	}
	elsif( $_[0] =~ /Showers/i || $_[0] =~ /Mostly Cloudy w\/ Showers/i || $_[0] =~ /Partly Sunny w\/ Showers/i || $_[0] =~ /T-Storms/i || 
		$_[0] =~ /Mostly Cloudy w\/ T-Storms/i || $_[0] =~ /Partly Sunny w\/ T-Storms/i || $_[0] =~ /Rain/i)
	{
		$str = "";
	}
	elsif( $_[0] =~ /Windy/i)
	{
		$str = "";
	} 
	elsif($_[0] =~ /Flurries/i || $_[0] =~ /Mostly Cloudy w\/ Flurries/i || $_[0] =~ /Partly Sunny w\/ Flurries/i || $_[0] =~ /Snow/i || 
		$_[0] =~ /Mostly Cloudy w\/ Snow/i || $_[0] =~ /Ice/i || $_[0] =~ /Sleet/i || $_[0] =~ /Freezing Rain/i || $_[0] =~ /Rain and Snow/i || 
		$_[0] =~ /Cold/i)
	{
		$str = "";
	}
	elsif($_[0] =~ /Clear/i || $_[0] =~ /Mostly Clear/i || $_[0] =~ /Partly Cloudy/i || $_[0] =~ /Intermittent Clouds/ || 
		$_[0] =~ /Hazy Moonlight/i || $_[0] =~ /Mostly Cloudy/i || $_[0] =~ /Partly Cloudy w\/ Showers/i || $_[0] =~ /Mostly Cloudy w\/ Showers/i || 
		$_[0] =~ /Partly Cloudy w\/ T-Storms/i || $_[0] =~ /Mostly Cloudy w\/ Flurries/i || $_[0] =~ /Mostly Cloudy w\/ Snow/i)
	{
		$str = "";
	} 
	else 
	{
		$str = "";
	}

	return $str;
}

my $con = get_weather("condition");
my $temp = get_weather("temp");

print get_icon($con) . " " . $temp . "\n";

exit 0;

=head1 NAME

weather.pl - prints weather

=head1 DESCRIPTION

A simple Weather script which usually prints Current weather. 
This distribution is the first time the author has created one.

=head1 SYNOPSIS

  $ weather.pl
  Sunny 14C

=head1 AUTHOR

Brad Heffernan

=head1 LICENSE

FreeBSD

=head1 INSTALLATION

Using C<cpan>:

    $ cpan Weather::Fetch

Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

=cut