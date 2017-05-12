package Weather::Com::DayPart;

use 5.006;
use strict;
use Carp;
use Weather::Com::L10N;
use Weather::Com::Wind;
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
	$self->{TYPE}          = undef;
	$self->{CONDITIONS}    = 'N/A';
	$self->{HUMIDITY}      = 'N/A';
	$self->{ICON}          = undef;
	$self->{PRECIPITATION} = undef;
	$self->{WIND}          = undef;

	return $self;
}    # end new()

#------------------------------------------------------------------------
# update data
#------------------------------------------------------------------------
sub update {
	my $self = shift;
	my %daypart;

	if ( ref( $_[0] ) eq "HASH" ) {
		%daypart = %{ $_[0] };
	} else {
		%daypart = @_;
	}

	if ( $daypart{p} eq "d" ) {
		$self->{TYPE} = "day";
	} else {
		$self->{TYPE} = "night";
	}

	$self->{CONDITIONS}    = $daypart{t};
	$self->{HUMIDITY}      = $daypart{hmid};
	$self->{ICON}          = $daypart{icon};
	$self->{PRECIPITATION} = $daypart{ppcp};

	unless ( $self->{WIND} ) {
		$self->{WIND} = Weather::Com::Wind->new( $self->{ARGS} );
	}

	$self->wind()->update( $daypart{wind} );

	return 1;
}

#------------------------------------------------------------------------
# access data
#------------------------------------------------------------------------
sub type {
	my $self     = shift;
	my $language = shift;
	return $self->get_language_handle($language)->maketext( $self->{TYPE} );
}

sub conditions {
	my $self     = shift;
	my $language = shift;
	return $self->get_language_handle($language)
	  ->maketext( lc( $self->{CONDITIONS} ) );
}

sub humidity {
	my $self = shift;
	return $self->{HUMIDITY};
}

sub icon {
	my $self = shift;
	return $self->{ICON};
}

sub precipitation {
	my $self = shift;
	return $self->{PRECIPITATION};
}

sub wind {
	my $self = shift;
	return $self->{WIND};
}

1;

__END__

=pod

=head1 NAME

Weather::Com::DayPart - class representing daytime or night part of a forecast

=head1 SYNOPSIS

  [...]
    
  my @locations = $weather_finder->find('Heidelberg');

  my $forecast = $locations[0]->forecast();
  my $tomorrow_night = $forecast->day(1)->night();

  print "Forecast for tomorrow night:\n";
  print " - conditions will be ", $tomorrow_night->conditions(), "\n";  
  print " - humidity will be ", $tomorrow_night->humidity(), "\%\n";
  print " - wind speed will be ", $tomorrow_night->wind()->speed(), "km/h\n";  

=head1 DESCRIPTION

Via I<Weather::Com::DayPart> objects one can access the daytime or night
part of a I<Weather::Com::DayForecast>.

This class will B<not> be updated automatically with each call to one
of its methods. You need to call a method of your I<Weather::Com::Forecast>
object to get updated objects.

=head1 CONSTRUCTOR

You usually would not construct an object of this class yourself. 
This is implicitely done when you call the C<day()> or 
C<night()> method of a I<Weather::Com::DayForecast> object.

=head1 METHODS

=head2 type([$language])

Will return I<day> or I<night>.

This attribute is I<dynamic language enabled>.

=head2 conditions([$language])

Will return a textual description of the forecasted conditions.

This attribute is I<dynamic language enabled>.

=head2 humidity()

Will return the humidity.

=head2 icon()

Will return the icon number of the icon describing the forecasted
weather.

=head2 precipitation()

Will return the percentage chance of precipitation.

=head2 wind()

Will return a I<Weather::Com::Wind> object.

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

