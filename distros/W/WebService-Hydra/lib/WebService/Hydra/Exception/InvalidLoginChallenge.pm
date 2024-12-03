package WebService::Hydra::Exception::InvalidLoginChallenge;
use strict;
use warnings;
use Object::Pad;

our $VERSION = '0.004'; ## VERSION

class WebService::Hydra::Exception::InvalidLoginChallenge :isa(WebService::Hydra::Exception) {
    field $redirect_to :param :reader = undef;

    sub BUILDARGS {
        my ($class, %args) = @_;

        $args{message}  //= 'Invalid Login Challenge';
        $args{category} //= 'client';

        return %args;
    }
}

1;
