use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::ProxyMethods;
    use Validation::Class;
    package main;

    my $class = "TestClass::ProxyMethods";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    my @meths = (qw(
        class
        clear_queue
        error
        error_count
        error_fields
        errors
        errors_to_string
        get_errors
        get_fields
        get_hash
        get_params
        get_values
        fields
        filtering
        ignore_failure
        ignore_unknown
        param
        params
        plugin
        queue
        report_failure
        report_unknown
        reset_errors
        reset_fields
        reset_params
        set_errors
        set_fields
        set_params
        stash
    ),
    # wrapped
    qw(
        validate
        validates
        validate_method
        method_validates
        validate_profile
        profile_validates
    ));

    for my $m (@meths) {

        ok $self->can($m),
          "$class can access the prototype method $m directly by proxy"

    }

}

done_testing;
