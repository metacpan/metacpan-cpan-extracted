package Weather::Com::AirPressure;

use 5.006;
use strict;
use warnings;
use Weather::Com::L10N;
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
	$self->{PRESSURE} = -1;
	$self->{TENDENCY} = 'unknown';

	return $self;
}    # end new()

#------------------------------------------------------------------------
# update barometric data
#------------------------------------------------------------------------
sub update {
	my $self = shift;
	my %bar;

	if ( ref( $_[0] ) eq "HASH" ) {
		%bar = %{ $_[0] };
	} else {
		%bar = @_;
	}

	unless ( $bar{r} ) {
		$self->{PRESSURE} = -1;
	} else {
		$self->{PRESSURE} = lc( $bar{r} );
	}
	unless ( $bar{d} ) {
		$self->{TENDENCY} = "unknown";
	} else {
		$self->{TENDENCY} = lc( $bar{d} );
	}

	return 1;
}

#------------------------------------------------------------------------
# access moon data
#------------------------------------------------------------------------
sub pressure {
	my $self = shift;
	return $self->{PRESSURE};
}

sub tendency {
	my $self     = shift;
	my $language = shift;

	return $self->get_language_handle($language)->maketext(lc($self->{TENDENCY}) );
}

1;

__END__

=pod

=head1 NAME

Weather::Com::AirPressure - class containing barometric pressure data

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

  my $currconditions = $locations[0]->current_conditions();

  print "Barometric pressure is ", 
    $currconditions->pressure()->pressure(), "\n";
  print "and it's ", $currconditions->pressure()->tendency(), "\n";  

=head1 DESCRIPTION

Via I<Weather::Com::AirPressure> one can access the barometric
pressure and its tendency.

This class will B<not> be updated automatically with each call to one
of its methods. You need to call the C<pressure()> method of the parent
object again to update your object.

=head1 CONSTRUCTOR

You usually would not construct an object of this class yourself. 
This is implicitely done when you call the C<pressure()> method 
of one current conditions or forecast object.

=head1 METHODS

=head2 pressure()

Returns the barometric pressure.

=head2 tendency([$language])

Returns the tendency of the barometric pressure.

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

