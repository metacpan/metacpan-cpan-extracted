package Weather::Com::Cached;

use 5.006;
use strict;
use warnings;
use Storable qw(lock_store lock_retrieve);
use Data::Dumper;
use Weather::Com::Base;
use base "Weather::Com::Base";

our $VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /(\d+)/g;

#------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# getting the parameters from @_
	my %parameters = ();
	if ( ref( $_[0] ) eq "HASH" ) {
		%parameters = %{ $_[0] };
	} else {
		%parameters = @_;
	}

	# creating the SUPER instance
	my $self = $class->SUPER::new( \%parameters );

	# where to put the cache files?
	if ( $parameters{cache} ) {
		$self->{PATH} = $parameters{cache};
	} else {
		$self->{PATH} = ".";
	}

	# check if cache is writable
	unless ( -w $self->{PATH} ) {
		die ref($self)
		  . ": path to cache not writable: "
		  . $self->{PATH} . "!\n";
	}

	# parameter cache
	$self->{PARAMS} = undef;

	bless( $self, $class );

	return $self;
}

#------------------------------------------------------------------------
# searching for location codes
# Weather::Com::Cached will not search on the web for location codes
# that are cached in "locations.dat"
#------------------------------------------------------------------------
sub search {
	my $self      = shift;
	my $place     = shift;
	my $locations = undef;

	# set error and die if no place provided
	unless ($place) {
		die ref($self), ": ERROR Please provide a location to search for!\n";
	}

	# 1st, look for locations in cache
	my $locations_cached = undef;
	my $loccachefile     = $self->{PATH} . "/locations.dat";
	if ( -f $loccachefile ) {
		$locations_cached = lock_retrieve($loccachefile);
		if ( $locations_cached->{ lc($place) } ) {
			$self->_debug("Found locations in location cache.");
			$locations = $locations_cached->{ lc($place) };
		} else {
			$self->_debug("No direct match found in cache.");
		}
	}

	# 2nd, if nothing has been found, search the Web and store data
	unless ( keys %{$locations} ) {
		$locations = $self->SUPER::search($place);
		if ($locations) {
			$self->_debug("Found locations on the web.");
			$self->_debug("Writing locations to cache.");

			# first save the direct search result
			$locations_cached->{ lc($place) } = $locations;

			# then store for each result the name => key hash
			foreach my $location ( keys %{$locations} ) {
				my $name = $locations->{$location};
				$locations_cached->{ lc($name) } = { $location => $name };
			}

			# then store in cache file
			unless ( lock_store( $locations_cached, $loccachefile ) ) {
				die ref($self),
				  ": ERROR I/O problem while storing locations cachefile!";
			}
		} elsif ($locations_cached) {

			# if neither the cache nor the weather.com server did return
			# an exact match, try a regexp search over the cache.
			$self->_debug("No direct match in cache or on the web.");
			$self->_debug("Trying regexp search.");
			$locations = {};
			foreach my $location ( keys %{$locations_cached} ) {
				if ( $location =~ /$place/i ) {
					$self->_debug(
								"MATCH: '$place' matches location '$location'");
					%{$locations} = (
									  %{$locations},
									  %{
										  $locations_cached->{ lc($location) }
										}
					);
				}
			}
		}

	}

	return $locations;
}

#------------------------------------------------------------------------
# getting data from weather.com
#------------------------------------------------------------------------
sub get_weather {
	my $self  = shift;
	my $locid = shift;

	$self->_debug("Trying to get data for $locid");

	unless ($locid) {
		die ref($self), ": Please provide a location id!\n";
	}

	# try to load an existing cache file
	my $cachefile    = $self->{PATH} . "/" . $self->{UNITS} . "_$locid.dat";
	my $weathercache = {};
	if ( -f $cachefile ) {
		$weathercache = lock_retrieve($cachefile);
	} else {
		$self->_debug("No cache file found.");
	}

	# find out which data is wanted by the modules user and
	# which parts of that are in the cache or must be
	# loaded from the web
	if ($weathercache) {

		$self->_debug("Cache file found.");

		# save parameters to be able to reset them at the end of
		# this method...
		$self->_store_params();

		# load uncached or old requested data
		if ( $self->{PARAMS}->{CC} ) {
			if ( $weathercache->{cc}
				 && !$self->_older_than( 30, $weathercache->{cc}->{cached} ) )
			{
				$self->{CC} = 0;
				$self->_debug("Turning off 'cc' update. Cache is good enough.");
			}
		}

		if ( $self->{PARAMS}->{FORECAST} ) {
			if ( $weathercache->{dayf} ) {
				my $no_forecastdays;    # number of days to be forecasted
				if ( ref( $weathercache->{dayf}->{day} ) eq "HASH" ) {
					$no_forecastdays = 1;
				} else {
					$no_forecastdays = $#{ $weathercache->{dayf}->{day} } + 1;
				}

				if ( ( $self->{PARAMS}->{FORECAST} == $no_forecastdays )
					 && !$self->_older_than( 120,
											 $weathercache->{dayf}->{cached} ) )
				{
					$self->{FORECAST} = 0;
					$self->_debug(
						"Turning off 'forecast' update. Cache is good enough.");
				}
			}
		}
	}

	$self->_debug("Params for cache conditions: ".Dumper($self->{PARAMS}));

	# only update weathercache if a current conditions update or a
	# forecast update is necessary or the location data is older than
	# 15 minutes.
	if (    $self->{CC}
		 or $self->{FORECAST}
		 or !$weathercache
		 or $self->_older_than( 15, $weathercache->{loc}->{cached} ) )
	{
		$self->_debug("All conditions met. Fetching weather from web.");

		my $weather = $self->SUPER::get_weather($locid);
		foreach ( keys %{$weather} ) {
			$weathercache->{$_} = $weather->{$_};
			if ( ref( $weather->{$_} ) ) {    
				$weathercache->{$_}->{cached} = $self->_cache_time();
			}
		}

		# save data to cache file
		unless (
				lock_store(
							$weathercache,
							$self->{PATH} . "/" . $self->{UNITS} . "_$locid.dat"
				)
		  )
		{
			die ref($self), ": ERROR I/O problem while storing cachefile!";
		}
	}

	$self->_reset_params();
	$self->_debug( Dumper($weathercache) );

	return $weathercache;
}

#------------------------------------------------------------------------
# store and reset search parameters
#------------------------------------------------------------------------
sub _store_params {
	my $self = shift;
	my %params = (
				   'PROXY'       => $self->{PROXY},
				   'TIMEOUT'     => $self->{TIMEOUT},
				   'DEBUG'       => $self->{DEBUG},
				   'PARTNER_ID'  => $self->{PARTNER_ID},
				   'LICENSE_KEY' => $self->{LICENSE_KEY},
				   'UNITS'       => $self->{UNITS},
				   'CC'          => $self->{CC},
				   'FORECAST'    => $self->{FORECAST},
				   'LINKS'       => $self->{LINKS},
	);

	$self->{PARAMS} = \%params;

	return 1;
}

sub _reset_params {
	my $self = shift;

	$self->{PROXY}       = $self->{PARAMS}->{PROXY};
	$self->{TIMEOUT}     = $self->{PARAMS}->{TIMEOUT};
	$self->{DEBUG}       = $self->{PARAMS}->{DEBUG};
	$self->{PARTNER_ID}  = $self->{PARAMS}->{PARTNER_ID};
	$self->{LICENSE_KEY} = $self->{PARAMS}->{LICENSE_KEY};
	$self->{UNITS}       = $self->{PARAMS}->{UNITS};
	$self->{CC}          = $self->{PARAMS}->{CC};
	$self->{FORECAST}    = $self->{PARAMS}->{FORECAST};
	$self->{LINKS}       = $self->{PARAMS}->{LINKS};

	return 1;
}

sub _older_than {
	my $self              = shift;
	my $caching_timeframe = shift;
	my $cached            = shift || 0;
	my $now               = $self->_cache_time();

	if ( $cached < ( $now - $caching_timeframe * 60 ) ) {
		return 1;
	} else {
		return 0;
	}
}

# this method encapsulates the time() method to be able to test
# with Test::MockObject and setting a fixed time
sub _cache_time {
	my $self = shift;
	return time();
}

1;

__END__

=pod

=head1 NAME

Weather::Com::Cached - Perl extension for getting weather information from I<weather.com>

=head1 SYNOPSIS

  use Data::Dumper;
  use Weather::Com::Cached;
  
  # define parameters for weather search
  my %params = (
		'cache'      => '/tmp/weathercache',
		'current'    => 1,
		'forecast'   => 3,
		'links'      => 1,
		'units'      => 's',
		'proxy'      => 'http://proxy.sonstwo.de',
		'timeout'    => 250,
		'debug'      => 1,
		'partner_id' => 'somepartnerid',
		'license'    => '12345678',
  );
  
  # instantiate a new weather.com object
  my $cached_weather = Weather::Com::Cached->new(%params);
  
  # search for locations called 'Heidelberg'
  my $locations = $cached_weather->search('Heidelberg')
  	or die "No location found!\n";
  
  # and then get the weather for each location found
  foreach (keys %{$locations}) {
	my $weather = $cached_weather->get_weather($_);
	print Dumper($weather);
  }

=head1 DESCRIPTION

I<Weather::Com::Cached> is a Perl module that provides low level OO interface
to gather all weather information that is provided by I<weather.com>. 

Please refer to L<Weather::Com> for the high level interfaces.

This module implements the caching business rules that apply to all
applications programmed against the I<xoap> API of I<weather.com>.
Except from the I<cache> parameter to be used while instantiating a new
object instance, this module has the same API than I<Weather::Com::Base>.
It's only a simple caching wrapper around it.

The caching mechanism for location searches is very simple. We assume
that location codes on I<weather.com> will never change. Therefore,
a search string that has been successfully used once to search for
locations will never cause another search on the web. Each location
search results will be stored in the file C<locations.dat>. If you
want to refresh your locations cache, simply delete this file.

Although it's really simple, the module uses I<Storable> methods 
I<lock_store> and I<lock_retrieve> to implement shared locking for 
reading cache files and exclusive locking for writing to chache files. 
By this way the same cache files should be able to be used by several
application instances using I<Weather::Com::Cached>.

You'll need to register at I<weather.com> to to get a free partner id
and a license key to be used within all applications that you want to
write against I<weather.com>'s I<xoap> interface. 

L<http://www.weather.com/services/xmloap.html>

=head1 CHANGES

The location caching mechanism has been extended with version 0.4. Up to
V0.4 searches were stored this way:

  $locations_cache = {
  		'New York' => {
                         'USNY1000' => 'New York/La Guardia Arpt, NY',
                         'USNY0998' => 'New York/Central Park, NY',
                         'USNY0999' => 'New York/JFK Intl Arpt, NY',
                         'USNY0996' => 'New York, NY'
  		},
  }

This has changed the way it does not only store a

  search_string => locations

hash. The cache now also stores a hash for B<each> location name found:

  $locations_cache => {
  	'new york' => {
  		'USNY1000' => 'New York/La Guardia Arpt, NY',
  		'USNY0998' => 'New York/Central Park, NY',
  		'USNY0999' => 'New York/JFK Intl Arpt, NY',
  		'USNY0996' => 'New York, NY'
  	},
  	'new york/central park, ny' => {
  		'USNY0998' => 'New York/Central Park, NY'
  	},
  	'new york/la guardia arpt, ny' => {
  		'USNY1000' => 'New York/La Guardia Arpt, NY'
  	},
  	'new york, ny' => {
  		'USNY0996' => 'New York, NY'
  	},
  	'new york/jfk intl arpt, ny' => {
  		'USNY0999' => 'New York/JFK Intl Arpt, NY'
  	},
  }

The new mechanism has the following advantages:

=over 4

=item 1.

The new chaching mechanism is B<case insensitive>

=item 2.

This caching mechanism is a workaround one problem with I<weather.com>'s
XOAP API. 

Their server does not understand any search string with a '/' in
it - no matter wether the '/' is URL encoded or not!

This way, if you have searched for I<New York> once, you'll then also 
get a result for direct calls to I<New York/Jfk Intl Arpt, NY>.

=item 3.

The new mechanism also allows searches for I<slashed> substrings. A search
for I<York/Central> will return the I<New York/Central Park, NY> location
and if you simply search I<York>, you'll get anything containing I<York>.
No matter if it's in the cache or not. 

Only if you specify B<exactly> the name of a location in the cache, only
this location is shown.

=back

=head1 CONSTRUCTOR

=head2 new(hash or hashref)

This constructor takes the same hash or hashref as I<Weather::Com::Base>
does. Please refer to that documentation for further details.

Except from the I<Weather::Com::Base>'s parameters this constructor 
takes a parameter I<cache> which defines the path to a directory into 
which all cache files will be put. 

The cache directory defaults to '.'.

=head1 METHODS

=head2 search(search string)

The C<search()> method has the same interface as the one of
I<Weather::Com::Base>. The difference is made by the caching.

The search is performed in the following order:

=over 4

=item 1.

If there's a direct match in the locations cache, return the
locations from the cache.

=item 2.

If not, if there's a direct match on the web, return the
locations found on the web and write the search result to
the cache.

=item 3.

If not, try a regexp search over all cached search strings and
location names. This will return each location that matches the
search string.

=back

The rest is all the same as for I<Weather::Com::Base>.

=head1 SEE ALSO

See also documentation of L<Weather::Com> and L<Weather::Com::Base>.

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com>!

L<http://www.weather.com/services/xmloap.html>

=cut
