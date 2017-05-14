package Test::Mockify::TypeTests;
use strict;
use warnings;
use Scalar::Util qw ( blessed );
use base qw( Exporter );
our @EXPORT_OK = qw (
        IsInteger
        IsFloat
        IsString
        IsArrayReference
        IsHashReference
        IsObjectReference
        IsCodeReference
    );

#------------------------------------------------------------------------
sub IsInteger {
    my ( $Value ) = @_;

    my $IsInteger = 0;
    my $Sign = '[-+]?'; # + or - or nothing
	if( defined $Value ){
	    if($Value =~ /^$Sign\d+$/ ) {
	        $IsInteger = 1;
		}
    }

    return $IsInteger;
}
#------------------------------------------------------------------------
sub IsFloat {
    my ( $Value ) = @_;

    my $IsFloat = 0;

    my $OptionalSign = '[-+]?';
    my $NumberOptions = '(?=\d|\.\d)\d*(\.\d*)?';
    my $OptionalExponent = '([eE][-+]?\d+)?';
    my $FloatRegex = sprintf('%s%s%s', $OptionalSign, $NumberOptions, $OptionalExponent);

	
    if ( $Value && $Value =~ /^$FloatRegex$/ ){
        $IsFloat = 1;
    }

    return $IsFloat;
}
#------------------------------------------------------------------------
sub IsString {
    my ( $Value ) = @_;

    my $IsString = 0;

    if ( defined $Value ){ 
        if( $Value =~ /[\w\s]/ || $Value eq ''){
            $IsString = 1;
        }
        # exclude all "types"
        my $ValueType = ref( $Value );
        if( defined $ValueType && $ValueType ne '' )  {
            $IsString = 0;
        }
    }

    return $IsString;
}
#------------------------------------------------------------------------
sub IsArrayReference {
    my ( $aValue ) = @_;

    my $IsArray = 0;

    if ( ref($aValue) eq 'ARRAY' ) {
        $IsArray = 1;
    }

    return $IsArray;
}
#------------------------------------------------------------------------
sub IsHashReference {
    my ( $hValue ) = @_;

    my $IsHash = 0;

    if ( ref($hValue) eq 'HASH' ) {
        $IsHash = 1;
    }

    return $IsHash;
}
#------------------------------------------------------------------------
sub IsCodeReference {
    my ( $hValue ) = @_;

    my $IsCode = 0;

    if ( ref($hValue) eq 'CODE' ) {
        $IsCode = 1;
    }

    return $IsCode;
}
#------------------------------------------------------------------------
sub IsObjectReference {
    my ( $Value ) = @_;

    my $IsObject = 0;

    if( blessed( $Value ) ) {
        $IsObject = 1;
    }

    return $IsObject;
}

1;
