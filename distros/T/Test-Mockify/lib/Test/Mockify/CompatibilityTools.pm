package Test::Mockify::CompatibilityTools;
use base qw ( Exporter );
use strict;
use warnings;
use Test::Mockify::Matcher qw (SupportedTypes);
use Test::Mockify::TypeTests qw ( IsString );

our @EXPORT_OK = qw (
    MigrateOldMatchers
);
#---------------------------------------------------------------------------------------------------
sub MigrateOldMatchers {
    my ( $Parameters ) = @_;
    $Parameters = IntAndFloat2Number( $Parameters );
    $Parameters = MigrateMatcherFormat( $Parameters );
    return $Parameters;
}
#---------------------------------------------------------------------------------------------------
sub MigrateMatcherFormat {
    my ( $Parameters ) = @_;

    foreach my $Parameter (@{$Parameters}){
        if( ref($Parameter) eq 'HASH'){
            if($Parameter->{'Type'} ~~ SupportedTypes()){
                return $Parameter;
            }
            my @ParameterKeys = keys %$Parameter;
            my @ParameterValues = values %$Parameter;
            $Parameter = {
                    'Type' => $ParameterKeys[0],
                    'Value' => $ParameterValues[0],
            };
        } else {
            if(IsString($Parameter) && $Parameter ~~ SupportedTypes()){
                $Parameter = {
                    'Type' => $Parameter,
                    'Value' => undef,
                };
            }else{
                die("Found unsupported type, '$Parameter'. Use Test::Mockify:Matcher to define nice parameter types.");
            }
        }
    }

    return $Parameters;
}
#---------------------------------------------------------------------------------------------------
sub IntAndFloat2Number {
    my ( $aParameterTypes ) = @_;

    my @NewParams;
    for(my $i = 0; $i < scalar @{$aParameterTypes}; $i++){
        if(ref($aParameterTypes->[$i]) eq 'HASH'){
            my $ExpectedValue;
            if($aParameterTypes->[$i]->{'int'}){
                $ExpectedValue = {'number' => $aParameterTypes->[$i]->{'int'}};
            }elsif($aParameterTypes->[$i]->{'float'}){
                $ExpectedValue = {'number' => $aParameterTypes->[$i]->{'float'}};
            }else{
                $ExpectedValue = $aParameterTypes->[$i];
            }
            $NewParams[$i] = $ExpectedValue;
        }else{
            if( $aParameterTypes->[$i] ~~ ['int', 'float']){
                $NewParams[$i] = 'number';
            } else{
                $NewParams[$i] = $aParameterTypes->[$i];
            }
        }
    }
    return \@NewParams;
}
1;