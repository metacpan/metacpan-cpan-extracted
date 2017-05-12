package URL::Encode;

use strict;
use warnings;

BEGIN {
    our $VERSION   = '0.03';
    our @EXPORT_OK = qw[ url_encode
                         url_encode_utf8
                         url_decode
                         url_decode_utf8
                         url_params_each
                         url_params_flat
                         url_params_mixed
                         url_params_multi ];

    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    my $use_pp = $ENV{URL_ENCODE_PP};

    if (!$use_pp) {
        eval { 
            require URL::Encode::XS; URL::Encode::XS->import('0.03');
        };
        $use_pp = !!$@;
    }

    if ($use_pp) {
        require URL::Encode::PP;
        URL::Encode::PP->import(@EXPORT_OK);
    }
    else {
        URL::Encode::XS->import(@EXPORT_OK);
    }

    require Exporter;
    *import = \&Exporter::import;
}

1;

