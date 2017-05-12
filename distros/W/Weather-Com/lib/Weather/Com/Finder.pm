package Weather::Com::Finder;

use 5.006;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Weather::Com::Cached;
use Weather::Com::Location;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)/g;

#------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------
sub new {
	my $proto      = shift;
	my $class      = ref($proto) || $proto;
	my $self       = {};
	my %parameters = ();

	# parameters provided by new method
	if ( ref( $_[0] ) eq "HASH" ) {
		%parameters = %{ $_[0] };
	} else {
		%parameters = @_;
	}

	# god, bless the object
	$self = bless( $self, $class );

	# Weather::Com::Cached object for searching
	my %weatherargs = ();
	
	# define proxy args
	$weatherargs{proxy} = $parameters{proxy} if ( $parameters{proxy} );
	$weatherargs{proxy_user} = $parameters{proxy_user}
	  if ( $parameters{proxy_user} );
	$weatherargs{proxy_pass} = $parameters{proxy_pass}    
	  if ( $parameters{proxy_pass} );
	  
	# other weather arguments...
	$weatherargs{units}   = $parameters{units}   if ( $parameters{units} );
	$weatherargs{debug}   = $parameters{debug}   if ( $parameters{debug} );
	$weatherargs{cache}   = $parameters{cache}   if ( $parameters{cache} );
	$weatherargs{timeout} = $parameters{timeout} if ( $parameters{timeout} );
	$weatherargs{partner_id} = $parameters{partner_id}
	  if ( $parameters{partner_id} );
	$weatherargs{license} = $parameters{license} if ( $parameters{license} );
	$weatherargs{language} = $parameters{language} if ( $parameters{language} );	

	# initialize weather object
	$self->{ARGS}    = \%weatherargs;
	$self->{WEATHER} = Weather::Com::Cached->new(%weatherargs);

	return $self;
}    # end new()

#------------------------------------------------------------------------
# find weather
#------------------------------------------------------------------------
sub find {
	my $self      = shift;
	my $locString = shift;

	# search locations
	my $loc_weather = $self->{WEATHER}->search($locString);
	unless ($loc_weather) {
		$self->_debug("No location found using '$locString' for search!");
		return 0;
	}

	# create a Weather::Com::Location for each location found
	my @locations = ();
	foreach ( keys %{$loc_weather} ) {
		my %weatherargs = %{ $self->{ARGS} };
		$weatherargs{location_id} = $_;
		$weatherargs{location_name} = $loc_weather->{$_};
		
		my $location = Weather::Com::Location->new(%weatherargs);
		push( @locations, $location );
	}

	$self->_debug("Location Objects: " . Dumper(\@locations));

	# return an array if called in list context or a scalar
	# if called in void or scalar context
	
	unless(@locations) {
		return undef;
	} elsif ( wantarray() ) {
		return @locations;
	} else {
		return \@locations;
	}
}

#------------------------------------------------------------------------
# other internals
#------------------------------------------------------------------------
sub _debug {
	my $self   = shift;
	my $notice = shift;
	if ( $self->{ARGS}->{debug} ) {
		carp ref($self) . " DEBUG NOTE: $notice\n";
		return 1;
	}
	return 0;
}

1;

__END__

=pod

=head1 NAME

Weather::Com::Finder - finder class to search for I<weather.com> location's

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use Weather::Com::Finder;

  # you have to fill in your ids from weather.com here
  my $PartnerId  = 'somepartnerid';
  my $LicenseKey = 'mylicense';

  my %weatherargs = (
	'partner_id' => $PartnerId,
	'license'    => $LicenseKey,
  );

  my $finder = Weather::Com::Finder->new(%weatherargs);
  
  # if you want an array of locations:
  my @locations = $finder->find('Heidelberg');
  
  # or if you prefer an arrayref:
  my $locations = $finder->find('Heidelberg');
  
  foreach my $location (@locations) {
    print "Found weather for city: ", $location->name(), "\n";
    print "Current Conditions are ", 
      $location->current_conditions()->description(), "\n";
  }

=head1 DESCRIPTION

The usual way to use the I<Weather::Com> module would be to instantiate
a I<Weather::Com::Finder> that allows you to search for a location
by providing a search string or postal code or any other search string
that I<weather.com> understands.

The finder returns an arrayref or an array of locations (depending on 
how you call the C<find()> method). Each location is an object of
I<Weather::Com::Location>. 

=head1 CONSTRUCTOR

=head2 new(hash or hashref)

The constructor takes a configuration hash or hashref as described in
the I<Weather::Com> POD. Please refer to that documentation for further 
details.

=head1 METHODS

=head2 find(search string)

Once you've instantiated a finder object, you can perform C<find()> calls 
to search for locations in the I<weather.com> database.

The C<find()> method returns an array of I<Weather::Com::Location> objects
if you call it in list context, else an arrayref.

Returns I<undef> if no matching location could be found.

=head1 SEE ALSO

See also documentation of L<Weather::Com> and L<Weather::Com::Location>.

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com> (http://www.weather.com/services/xmloap.html)

=cut

