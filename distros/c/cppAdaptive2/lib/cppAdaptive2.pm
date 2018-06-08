package cppAdaptive2 v2.0.2;

use strict;
use warnings;

use cppAdaptive2::Inline(
    CPP => <<'CPP',
#undef seed
#undef do_open
#undef do_close
#undef open
#undef read
#undef write
#undef close
#undef bind
#undef seekdir
#undef setbuf
#undef wait
#undef PP

#include "cppAdaptive.cpp"

AV* _update(char* obsVector, char* futVector, char* betaVector, int n_observed) {
    string obsVector1(obsVector);
    string futVector1(futVector);
    string betaVector1(betaVector);

    cppAdaptive(obsVector1, futVector1, betaVector1, n_observed);

    AV* av = newAV();
    sv_2mortal((SV*)av);

    av_push( av, newSVpv(betaVector1.c_str(), betaVector1.size()) );
    av_push( av, newSVpv(futVector1.c_str(), futVector1.size()) );

    return av;
}
CPP
    inc               => '-I../../../../src',
    ccflags           => '-std=c++11',
    clean_after_build => 0,
    clean_build_area  => 0,
);

sub update {
    my ( $obsVector, $futVector, $betaVector, $n_observed ) = @_;

    return @{ _update( $obsVector, $futVector, $betaVector, $n_observed ) };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

cppAdaptive2 - cppAdaptive2 XS

=head1 SYNOPSIS

    use cppAdaptive2;

    my ( $obsVector, $futVector, $betaVector, $n_observed ) = (    #
        '313312221112123223322132223313312131221123212113221111213232',
        '323133332131332223321221232122221331123313333213311113231233333322133312331123322211232222212312131221133121232212232111233332223221131132112121332212123211313111211',
        '-0.26425,0.648666,-0.0565359,-0.373203,-0.107654,0.228433,-0.339707,0.663967,0.0600106,0.0828479',
        4,
    );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
