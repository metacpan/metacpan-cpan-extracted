package Weather::Com::Units;

use 5.006;
use strict;
use warnings;
use Class::Struct;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)/g;

#------------------------------------------------------------------------
# Weather::Com::Units consists almost only of pure data and no
# significant logic has to be build in. Therefore, we simply use a
# Class::Struct subclass.
#------------------------------------------------------------------------
struct(
		distance      => '$',
		precipitation => '$',
		pressure      => '$',
		speed         => '$',
		temperature   => '$',
);

#------------------------------------------------------------------------
# update wind data
#------------------------------------------------------------------------
sub update {
	my $self = shift;
	my %units;

	if ( ref( $_[0] ) eq "HASH" ) {
		%units = %{ $_[0] };
	} else {
		%units = @_;
	}

	# update data
	$self->distance( $units{ud} );
	$self->precipitation( $units{ur} );
	$self->pressure( $units{up} );
	$self->speed( $units{us} );
	$self->temperature( $units{ut} );

	return 1;
}

1;

__END__

=pod

=head1 NAME

Weather::Com::Units - class representing units of measure

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

  my $weather_finder = Weather::Com::Finder->new(%weatherargs);
  
  my @locations = $weather_finder->find('Heidelberg');

  print "Speed is messured in ", $locations[0]->units()->speed();
  print " for this location.\n";  

=head1 DESCRIPTION

Via I<Weather::Com::Units> one can access the units of measure that
correspond to the numeric values used in its parent location object.

This class will B<not> be updated automatically with each call to one
of its methods. You need to call the C<units()> method of the parent
object again to update your object.

=head1 CONSTRUCTOR

You usually would not construct an object of this class yourself. 
This is implicitely done when you call the C<units()> method of one
location object.

=head1 METHODS

=head2 distance()

Returns the unit of distance used.

=head2 precipitation()

Returns the unit of precipitation used.

=head2 pressure()

Returns the unit of barometric pressure used.

=head2 speed()

Returns the unit of speed used.

=head2 temperature()

Returns the unit of temperature used.

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

