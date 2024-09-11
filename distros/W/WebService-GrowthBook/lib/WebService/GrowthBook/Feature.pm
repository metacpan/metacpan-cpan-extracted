package WebService::GrowthBook::Feature;
use strict;
use warnings;
no indirect;
use Object::Pad;
use WebService::GrowthBook::FeatureRule;

our $VERSION = '0.003'; ## VERSION

class WebService::GrowthBook::Feature{
    field $id :param :reader;
    field $default_value :param :reader;
    field $rules :param :reader //= undef;

    sub BUILDARGS{
        my ($class, %args) = @_;
        if($args{rules}){
            my $rules = $args{rules};
            my @rules_objects;
            for my $rule (@$rules){
                push @rules_objects, WebService::GrowthBook::FeatureRule->new(%$rule);
            }
            $args{rules} = \@rules_objects;
        }
        else{
            $args{rules} = [];
        }
        if(exists $args{defaultValue}){
            $args{default_value} = delete $args{defaultValue};
        }
        return %args;
    }
}

1;
