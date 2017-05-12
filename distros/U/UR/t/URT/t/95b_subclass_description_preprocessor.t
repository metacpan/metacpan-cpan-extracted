#!/usr/bin/env perl

use strict;
use warnings;

use above 'UR';
use Test::More tests => 2;
use Test::Exception;

subtest 'duplicate/synonym key error' => sub {
    plan tests => 1;

    class BaseError {
        is => 'UR::Object',
        subclass_description_preprocessor => 'BaseError::_preprocess',
        subclassify_by => 'subclass_name',
    };

    sub BaseError::_preprocess {
        my ($class, $desc) = @_;
        my $count_prop = $desc->{has}{count};
        $desc->{has}{extra_property} = {
            is => 'Number',
            data_type => 'Number',
            property_name => 'extra_property',
            class_name => $count_prop->{class_name},
        };
        return $desc;
    }

    throws_ok { class DerivedError {
                    is => 'BaseError',
                    has => [
                        count => {
                            is => 'Number',
                        },
                    ],
                } }
        qr/synonyms for data_type/,
        'Exception when preprocessing introduces a synonym key error';
};

subtest 'preprocessor is called after attribute normalization' => sub {
    plan tests => 3;

    class AttrNormBase {
        subclass_description_preprocessor => 'AttrNormBase::_preprocess',
    };

    sub AttrNormBase::_preprocess {
        my($class, $desc) = @_;
        is($class, 'AttrNormBase', '$class arg to preprocessor');
        is($desc->{has}->{the_attr}->{data_type}, 'SomeTestType', 'Attribute "data_type" comes from "is" in class definition');
        return $desc;
    }

    ok(UR::Object::Type->define(
            class_name => 'AttrNormChild',
            is => 'AttrNormBase',
            has => [
                the_attr => { is => 'SomeTestType' },
            ],
        ),
        'Define class');
};

