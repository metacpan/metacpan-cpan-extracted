package WebService::Hydra::Exception::InternalServerError;
use strict;
use warnings;
use Object::Pad;

our $VERSION = '0.002'; ## VERSION

class WebService::Hydra::Exception::InternalServerError :isa(WebService::Hydra::Exception) {

    sub BUILDARGS {
        my ($class, %args) = @_;

        $args{message}  //= 'Internal server error';
        $args{category} //= 'server';

        return %args;
    }
}

1;
