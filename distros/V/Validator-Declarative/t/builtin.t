#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Validator::Declarative;

my $result;

#
# generic exceptions
#
throws_ok { Validator::Declarative::validate( 1, 1, 1 ) } 'Error::Simple', 'throws on invalid first parameter';
like $@, qr/invalid.*params/, 'message about invalid first parameter';

throws_ok { Validator::Declarative::validate( [1], 1, 1 ) } 'Error::Simple', 'throws on invalid second parameter';
like $@, qr/invalid.*rules/, 'message about invalid second parameter';

throws_ok { Validator::Declarative::validate( [1], [1] ) } 'Error::Simple', 'throws on params/rules count mismatch';
like $@, qr/params.*count.*rules/, 'message about incorrect count params <=> rules';

throws_ok { Validator::Declarative::validate( [1], [ 1, 1 ], 1 ) } 'Error::Simple', 'throws on extra parameter';
like $@, qr/extra.*param/, 'message about extra parameter';

#
# parameter-specific exceptions
#
throws_ok {
    Validator::Declarative::validate( [1], [ id => { list_of => 'id', default => 1 } ] );
}
'Error::Simple', 'throws on hash rule with more than one key/value pair';
like $@, qr/^id: .*hashref.*should.*have.*exactly.*one.*pair/, 'message about extra key/value pairs';

throws_ok {
    Validator::Declarative::validate( [1], [ id => sub { die "should not be called" } ] );
}
'Error::Simple', 'throws on reference to not hash or array';
like $@, qr/^id: .*reference.*to.*CODE/, 'message about bad reference';

throws_ok {
    Validator::Declarative::validate( [1], [ id => 'non_existent_rule' ] );
}
'Error::Simple', 'throws on unknown rule';
like $@, qr/^id: .*rule.*not.*registered/, 'message about not registered rule';

throws_ok {
    Validator::Declarative::validate( [1], [ id => [ [ id => rule => with => many => 'params' ] ] ] );
}
'Error::Simple', 'throws on rule with more than one parameter';
like $@, qr/^id: .*not.*more.*one.*param/, 'message about rule with more than one parameter';

#
# built-in constraints
#
throws_ok {
    Validator::Declarative::validate( [1], [ id => [ 'required', 'optional' ] ] );
}
'Error::Simple', 'throws when both required and optional are specified';
like $@, qr/^id: .*both.*required.*optional/, 'message about both required and optional are specified';

throws_ok {
    Validator::Declarative::validate( [undef], [ id => ['required'] ] );
}
'Error::Simple', 'throws on missing explicit required parameter';
like $@, qr/^id: .*parameter.*required/, 'message about missing explicit required parameter';

throws_ok {
    Validator::Declarative::validate( [undef], [ id => ['any'] ] );
}
'Error::Simple', 'throws on missing implicit required parameter';
like $@, qr/^id: .*parameter.*required/, 'message about missing implicit required parameter';

#
# built-in converter
#
throws_ok {
    Validator::Declarative::validate( [undef], [ id => { default => 100 } ] );
}
'Error::Simple', 'throws when default is used without optional';
unlike $@, qr/^id: .*default.*without.*optional/, 'should not get message about default is used without optional';
like $@, qr/^id: .*parameter.*required/, 'instead should get message about missing implicit required parameter';

throws_ok {
    Validator::Declarative::validate( [200], [ id => { default => 100 } ] );
}
'Error::Simple', 'throws when default is used without optional';
unlike $@, qr/^id: .*parameter.*required/,        'should not get message about missing implicit required parameter';
like $@,   qr/^id: .*default.*without.*optional/, 'instead should get message about default is used without optional';

lives_ok {
    $result = undef;
    ($result) = Validator::Declarative::validate( [undef], [ id => [ 'optional', { default => 100 } ] ] );
}
'lives ok when both default and optional are used';
is( $result, 100, 'default works as expected on undef' );

lives_ok {
    $result = undef;
    ($result) = Validator::Declarative::validate( [200], [ id => [ 'optional', { default => 100 } ] ] );
}
'lives ok when both default and optional are used';
is( $result, 200, 'default works as expected on non-undef' );

#
# built-in types
#
lives_ok {
    $result = undef;
    ($result) = Validator::Declarative::validate( [100], [ id => ['optional'] ] );
}
'lives ok when no type specified';
is( $result, 100, 'implicit "any" does not affect input' );

lives_ok {
    $result = undef;
    ($result) = Validator::Declarative::validate( [100], [ id => ['any'] ] );
}
'lives ok when "any" type specified';
is( $result, 100, 'explicit "any" does not affect input' );

lives_ok {
    $result = undef;
    ($result) = Validator::Declarative::validate( [100], [ id => ['string'] ] );
}
'lives ok when "string" type specified';
is( $result, 100, 'explicit "string" does not affect input' );

#
# register additional constraints
#
lives_ok {
    Validator::Declarative::register_constraint(
        always_fail => sub { return Validator::Declarative::_validate_fail(@_); },
        always_pass => sub { return Validator::Declarative::_validate_pass(@_); },
        pass_100    => sub { my ($input) = @_; return $input if $input == 100; },
    );
}
'can register custom constraints';
## TODO check that custom constraints can be used

#
# register additional converters
#
lives_ok {
    Validator::Declarative::register_converter(
        default_300      => sub { my ($input) = @_; return 300 unless $input; },
        empty_by_default => sub { my ($input) = @_; return ''  unless defined($input); },
    );
}
'can register custom converters';

#
# register additional types
#
lives_ok {
    Validator::Declarative::register_type(
        celsius => sub {
            my ($input) = @_;
            throw Error::Simple('does not looks like temperature in Celsius') unless $input =~ m/^\d*(\.\d*)c$/i;
        },
        fahrenheit => sub {
            my ($input) = @_;
            throw Error::Simple('does not looks like temperature in Fahrenheit') unless $input =~ m/^\d*(\.\d*)f$/i;
        },
        like => sub {
            my ( $input, $param ) = @_;
            throw Error::Simple('does not match given pattern') unless $input =~ m/$param/;
        },
        between => sub {
            my ( $input, $param ) = @_;
            my $min = $param->[0];
            my $max = $param->[1];
            ( $min, $max ) = ( $max, $min ) if $min > $max;
            throw Error::Simple('outside of range') if $input < $min || $max < $input;
        },
    );
}
'can register custom converters';

done_testing();

