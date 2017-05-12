package Weather::Com::Wind;

use 5.006;
use strict;
use warnings;
use Weather::Com::L10N;
use Weather::Com::Base qw/convert_winddirection/;
use base 'Weather::Com::Object';

our $VERSION = sprintf "%d.%03d", q$Revision: 1.10 $ =~ /(\d+)/g;

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
	$self->{SPEED}       = -1;
	$self->{GUST}        = -1;
	$self->{DIR_DEGREES} = -1;
	$self->{DIR_TXT}     = 'N/A';
	return $self;
}    # end new()

#------------------------------------------------------------------------
# update wind data
#------------------------------------------------------------------------
sub update {
	my $self = shift;
	my %wind;

	if ( ref( $_[0] ) eq "HASH" ) {
		%wind = %{ $_[0] };
	} else {
		%wind = @_;
	}

	# handle non existent wind data
	unless ( $wind{s} ) {
		$self->{SPEED}       = -1;
		$self->{GUST}        = -1;
		$self->{DIR_DEGREES} = -1;
		$self->{DIR_TXT}     = 'N/A';
	} elsif ( lc( $wind{s} ) eq "calm" ) {

		# special rules apply if speed is non-numeric
		$self->{SPEED}       = 0;
		$self->{GUST}        = 0;
		$self->{DIR_DEGREES} = -1;
		$self->{DIR_TXT}     = 'N/A';
	} else {

		# else update object data
		$self->{SPEED}       = $wind{s};
		$self->{GUST}        = $wind{gust};
		$self->{DIR_DEGREES} = $wind{d};
		$self->{DIR_TXT}     = $wind{t};
	}

}

#------------------------------------------------------------------------
# accessor methods
#------------------------------------------------------------------------
sub speed {
	my $self = shift;
	return $self->{SPEED};
}

sub maximum_gust {
	my $self = shift;
	return $self->{GUST};
}

sub direction_degrees {
	my $self = shift;
	return $self->{DIR_DEGREES};
}

sub direction_short {
	my $self     = shift;
	my $language = shift;

	return $self->get_language_handle($language)->maketext( $self->{DIR_TXT} );
}

sub direction_long {
	my $self     = shift;
	my $language = shift;

	my $dir = convert_winddirection( $self->{DIR_TXT} );
	return $self->get_language_handle($language)->maketext($dir);
}

1;

__END__

=pod

=head1 NAME

Weather::Com::Wind - class containing wind data

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

  my $currconditions = $locations[0]->current_conditions();

  print "Wind comes from ", $currconditions->wind()->direction_long(), "\n";
  print "and its speed is", $currconditions->wind()->speed(), "\n";  

=head1 DESCRIPTION

Via I<Weather::Com::Wind> one can access speed and direction (in degrees,
short and long textual description) of the wind. Wind is usually an object
belonging to current conditions or to a forecast (not implemented yet).

This class will B<not> be updated automatically with each call to one
of its methods. You need to call the C<wind()> method of the parent
object again to update your object.

=head1 CONSTRUCTOR

You usually would not construct an object of this class yourself. 
This is implicitely done when you call the C<wind()> method of one
current conditions or forecast object.

=head1 METHODS

=head2 speed()

Returns the wind speed.

=head2 direction_degrees()

Returns the direction of the wind in degrees.

=head2 direction_short([$language])

Returns the direction of the wind as wind mnemonic (N, NW, E, etc.).

These directions are being translated if you specified a language in the
parameters you provided to your I<Weather::Com::Finder>.

This attribute is I<dynamic language enabled>.

=head2 direction_long([$language])

Returns the direction of the wind as long textual description
(North, East, Southwest, etc.).

These directions are being translated if you specified a language in the
parameters you provided to your I<Weather::Com::Finder>.

This attribute is I<dynamic language enabled>.

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

