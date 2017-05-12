package Weather::Com::DayForecast;

use 5.006;
use strict;
use warnings;
use Weather::Com::L10N;
use Weather::Com::DayPart;
use Weather::Com::DateTime;
use base 'Weather::Com::Object';

our $VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)/g;

#------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %parameters;

	# parameters provided by new method
	if ( ref( $_[0] ) eq "HASH" ) {
		%parameters = %{ $_[0] };
	} else {
		%parameters = @_;
	}

	my $self = $class->SUPER::new( \%parameters );

	# getting first weather information
	$self->{DATE}    = undef;
	$self->{HIGH}    = 'N/A';
	$self->{LOW}     = 'N/A';
	$self->{SUNRISE} = undef;
	$self->{SUNSET}  = undef;
	$self->{DAY}     = undef;
	$self->{NIGHT}   = undef;

	return $self;
}    # end new()

#------------------------------------------------------------------------
# update data
#------------------------------------------------------------------------
sub update {
	my $self = shift;
	my %day;

	if ( ref( $_[0] ) eq "HASH" ) {
		%day = %{ $_[0] };
	} else {
		%day = @_;
	}

	# update date and time data
	unless ( $self->date() ) {
		$self->{DATE}    = Weather::Com::DateTime->new( $day{zone} );
		$self->{SUNRISE} = Weather::Com::DateTime->new( $day{zone} );
		$self->{SUNSET}  = Weather::Com::DateTime->new( $day{zone} );
	}

	$self->date()->set_date( $day{dt} );
	$self->sunrise()->set_time( $day{sunr} );
	$self->sunset()->set_time( $day{suns} );

	# update weather data
	# if $day{hi} eq "N/A" then there is no daytime forecast
	unless ( $day{hi} eq 'N/A' ) {
		$self->{HIGH} = $day{hi};
	} else {
		$self->{HIGH} = 'N/A';
	}
	$self->{LOW} = $day{low};

	foreach my $daypart ( @{ $day{part} } ) {
		if ( $daypart->{p} eq 'd' ) {

			# if $day{hi} eq "N/A" then there is no daytime forecast
			if ( $day{hi} ne 'N/A' ) {
				unless ( $self->{DAY} ) {    
					$self->{DAY} = Weather::Com::DayPart->new( $self->{ARGS} );
				}
				$self->day()->update($daypart);
			}
		} else {
			unless ( $self->{NIGHT} ) {
				$self->{NIGHT} = Weather::Com::DayPart->new( $self->{ARGS} );
			}
			$self->night()->update($daypart);
		}
	}
}

#------------------------------------------------------------------------
# access data
#------------------------------------------------------------------------
sub date {
	my $self = shift;
	return $self->{DATE};
}

sub high {
	my $self = shift;
	return $self->{HIGH};
}

sub low {
	my $self = shift;
	return $self->{LOW};
}

sub sunrise {
	my $self = shift;
	return $self->{SUNRISE};
}

sub sunset {
	my $self = shift;
	return $self->{SUNSET};
}

sub day {
	my $self = shift;
	return $self->{DAY};
}

sub night {
	my $self = shift;
	return $self->{NIGHT};
}

1;

__END__

=pod

=head1 NAME

Weather::Com::DayForecast - class representing a forecast for one day

=head1 SYNOPSIS

  [...]
    
  my @locations = $weather_finder->find('Heidelberg');

  my $forecast = $locations[0]->forecast();
  my $tomorrow = $forecast->day(1);

  print "Forecast for tomorrow:\n";
  print " - tomorrow it's the ", $tomorrow->date()->date(), "\n";  
  print " - sunrise will be at ", $tomorrow->sunrise()->time(), "\n";  
  print " - maximum temperature will be ", $tomorrow->high(), "\n";  

=head1 DESCRIPTION

Via I<Weather::Com::DayForecast> objects one can access the weather
forecast for one specific day.

This class will B<not> be updated automatically with each call to one
of its methods. You need to call a method of your I<Weather::Com::Forecast>
object to get updated objects.

=head1 CONSTRUCTOR

You usually would not construct an object of this class yourself. 
This is implicitely done when you call the C<day(number of day)> or 
the C<all()> method of a I<Weather::Com::Forecast> object.

=head1 METHODS

=head2 date()

Returns a I<Weather::Com::DateTime> object containing the date the
forecast is for.

=head2 high()

Returns the maximum temperature that will be reached at daytime.

For day 0 (today), this will be 'N/A' when it's after noon...

B<There is a bug> in I<weather.com>'s date and time mathematics:
If you are asking for a location's forecast day 0 and it's
short after midnight, day 0 will be "yesterday" and you'll
get both, yesterday's daytime forecast and night forecast!

I have not investigated this issue further, yet. If
anyone has, please inform me!

=head2 low()

Returns the minimum temperature that will be reached at night.

=head2 sunrise()

Returns a I<Weather::Com::DateTime> object containing the time of
sunrise.

=head2 sunset()

Returns a I<Weather::Com::DateTime> object containing the time of
sunset.

=head2 day()

Returns a I<Weather::Com::DayPart> object with all data belonging
to the daytime.

For day 0 (today), this will be C<undef> when it's after noon...

B<There is a bug> in I<weather.com>'s date and time mathematics:
If you are asking for a location's forecast day 0 and it's
short after midnight, day 0 will be "yesterday" and you'll
get both, yesterday's daytime forecast and night forecast!

I have not investigated this issue further, yet. If
anyone has, please inform me!

=head2 night()

Returns a I<Weather::Com::DayPart> object with all data belonging
to the night.

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com> (L<http://www.weather.com/services/xmloap.html>)!

=cut

