package WebService::Hydra::Exception::InvalidConsentChallenge;
use strict;
use warnings;
use Object::Pad;

our $VERSION = '0.004'; ## VERSION

class WebService::Hydra::Exception::InvalidConsentChallenge :isa(WebService::Hydra::Exception) {
    field $redirect_to :param :reader = undef;

    sub BUILDARGS {
        my ($class, %args) = @_;

        $args{message}  //= 'Invalid Consent Challenge';
        $args{category} //= 'client';

        return %args;
    }
}

1;
