package WebService::Hydra::Exception::InvalidIdToken;
use strict;
use warnings;
use Object::Pad;

our $VERSION = '0.004'; ## VERSION

class WebService::Hydra::Exception::InvalidIdToken :isa(WebService::Hydra::Exception) {

    sub BUILDARGS {
        my ($class, %args) = @_;

        $args{message}  //= 'Invalid token';
        $args{category} //= 'client';

        return %args;
    }
}

1;
