package WebService::Hydra::Exception::FeatureUnavailable;
use strict;
use warnings;
use Object::Pad;

our $VERSION = '0.001'; ## VERSION

class WebService::Hydra::Exception::FeatureUnavailable :isa(WebService::Hydra::Exception) {

    sub BUILDARGS {
        my ($class, %args) = @_;

        $args{message}  //= 'The feature is currently unavailable';
        $args{category} //= 'client';

        return %args;
    }
}

1;
