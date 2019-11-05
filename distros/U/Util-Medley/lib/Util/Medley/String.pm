package Util::Medley::String;
$Util::Medley::String::VERSION = '0.007';
use Modern::Perl;
use Moose;
use Method::Signatures;
use namespace::autoclean;

use Data::Printer alias => 'pdump';
use String::Util 'nocontent';

=head1 NAME

Util::Medley::String - utility methods for working with strings

=head1 VERSION

version 0.007

=cut

#########################################################################################

=pod

use base 'Exporter';
our @EXPORT      = qw();                      # Symbols to autoexport (:DEFAULT tag)
our @EXPORT_OK   = qw(is_blank trim undef2str);    # Symbols to export on request
our %EXPORT_TAGS = (                          # Define names for sets of symbols
    all => \@EXPORT_OK,
);

=cut

#########################################################################################

=head1 METHODS

=head2 camelize

Converts a string to camelcase.

=head3 usage

  camelize(<string>)
  
=cut

method camelize (Str $str) {

	my @a = split( /[:_-]+/, $str );
	my @b = lc shift @a;
	push @b, map { ucfirst lc $_ } @a;

	return join '', @b;
}

method isBlank (Str $str) {

	if ( nocontent($str) ) {
		return 1;
	}

	return 0;
}

method pascalize (Str $str) {

	my @a = split( /[:_-]+/, $str );
	my @b;
	push @b, map { ucfirst lc $_ } @a;

	return join '', @b;
}

method snakeize (Str $str) {

    $str =~ s/:+/_/g;
    $str =~ s/ +/_/g;

    my @a = split( /_/, $str );
    my @b;
    foreach my $a (@a) {
        if ( $a eq '' ) {
            push @b, '';
        }
        else {
            push @b, split( /(?=[A-Z])/, $a );
        }
    }

    return lc join( '_', @b );
}

method titleize (Str $str) {

	return $self->pascalize($str);	
}


=head1 trim

This exists because I am tired of hunting down the correct cpan module.

=cut

method trim (Str $str) {

	return String::Util::trim($str);
}

method undefToString (Str|Undef  $val, 
                  	  Str  		 $string = '' ) {

	if ( !defined $val ) {
		return $string;
	}

	return $val;
}

1;
