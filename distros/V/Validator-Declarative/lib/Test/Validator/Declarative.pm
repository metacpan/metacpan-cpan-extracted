#!/usr/bin/env perl

use strict;
use warnings;

package Test::Validator::Declarative;
{
  $Test::Validator::Declarative::VERSION = '1.20130722.2105';
}

# ABSTRACT: Tests for declarative parameters validation

use Exporter;
use Test::More;
use Test::Exception;
use Data::Dumper;
use Validator::Declarative;

our @ISA       = qw/ Exporter /;
our @EXPORT_OK = qw/ check_type_validation check_converter_validation /;

sub check_type_validation {
    my %param = @_;

    # for lives_ok + is_deeply + throws_ok + message for each error
    plan tests => 4 + 1 + scalar( @{ $param{bad} } );

    my ( $type, $aliased_type, $values, @result, $type_name, $stringified_type );

    $type = $param{type};
    $aliased_type = $param{aliased_to} || '';

    ($type_name) =    # there should be exactly one k/v pair
          ref($type) eq 'HASH'  ? keys(%$type)
        : ref($type) eq 'ARRAY' ? $type->[0]
        :                         $type;

    $stringified_type = _struct_to_str($type);

    #
    # check type validation pass
    #
    $values = $param{good};
    lives_ok {
        @result = Validator::Declarative::validate( [undef] => [ "param_${type_name}_0" => [ 'optional', $type ] ] );
    }
    "type 'optional,$stringified_type' lives on undef";
    is_deeply( \@result, [undef], "type 'optional,$stringified_type' returns expected result" );

    lives_ok {
        @result = Validator::Declarative::validate(
            $values => [ map { sprintf( "param_${type_name}_%02d", $_ ) => $type, } 1 .. scalar @$values ] );
    }
    "type $stringified_type lives on correct parameters";
    is_deeply( \@result, $values, "type $stringified_type returns expected result" );

    #
    # check type validation fail
    #
    $values = $param{bad};
    throws_ok {
        Validator::Declarative::validate(
            $values => [ map { sprintf( "param_${type_name}_%02d", $_ ) => $type, } 1 .. scalar @$values ] );
    }
    'Error::Simple', "type $stringified_type throws on incorrect parameters";

    my $error_text = "$@";
    for ( 1 .. scalar @$values ) {
        my $param = sprintf( "param_${type_name}_%02d", $_ );
        my $regexp = sprintf( "%s: .* does not satisfy %s", $param, uc( $aliased_type || $type_name ) );
        like $error_text, qr/^$regexp/m, "message about $param";
    }

}

sub check_converter_validation {
    my %param = @_;

    # for lives_ok + is_deeply + throws_ok + message for each error
    plan tests => 2 * values %{ $param{result} };

    my ( $type, $aliased_type, @result, $type_name, $stringified_type );

    $type = $param{type};
    $aliased_type = $param{aliased_to} || '';

    ($type_name) =    # there should be exactly one k/v pair
          ref($type) eq 'HASH'  ? keys(%$type)
        : ref($type) eq 'ARRAY' ? $type->[0]
        :                         $type;

    $stringified_type = _struct_to_str($type);

    #
    # check type validation pass
    #
    while ( my ( $result, $values ) = each %{ $param{result} } ) {
        if ( $ENV{DEBUG} || $ENV{TEST_DEBUG} || $ENV{DEBUG_TEST} ) {
            diag( 'Processing values:  ' . _struct_to_str($values) );
            diag( 'Expected result(s): ' . _struct_to_str($result) );
        }

        $values = [$values] if ref($values) ne 'ARRAY';

        lives_ok {
            @result =
                Validator::Declarative::validate(
                $values => [ map { sprintf( "param_${type_name}_%02d", $_ ) => $type } 1 .. scalar @$values ] );
        }
        "converter $stringified_type lives on correct parameters for $result";

        is_deeply(
            \@result, [ ($result) x scalar(@$values) ],
            "converter $stringified_type returns as expected for $result"
        );
    }
}

sub _struct_to_str {
    my ( $struct, $maxdepth, $use_deparse ) = @_;

    $maxdepth    ||= 3;
    $use_deparse ||= 0;

    local $Data::Dumper::Deparse   = $use_deparse;
    local $Data::Dumper::Indent    = 0;
    local $Data::Dumper::Maxdepth  = $maxdepth;
    local $Data::Dumper::Quotekeys = 1;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Useqq     = 0;

    return Data::Dumper::Dumper($struct);
}


1;    # End of Test::Validator::Declarative


__END__
=pod

=head1 NAME

Test::Validator::Declarative - Tests for declarative parameters validation

=head1 VERSION

version 1.20130722.2105

=head1 SYNOPSIS

    # t/converters/assume_true.t
    use strict;
    use warnings;

    use Test::Validator::Declarative qw/ check_converter_validation /;

    check_converter_validation(
        type   => 'assume_true',
        result => {
            1 => [
                ## all TRUEs
                'T', 'TRUE', 'Y', 'YES',
                't', 'true', 'y', 'yes',
                1,
                '',               # empty string
                'some string',    # arbitrary string
                10,               # arbitrary number
                'NOT',            # mistype
                sub { return 'TRUE' },    # coderef
            ],
            0 => [
                ## all FALSEs
                'F', 'FALSE', 'N', 'NO',
                'f', 'false', 'n', 'no',
                0,
            ],
        },
    );

=head1 DESCRIPTION

Simple helpers to write tests for your own types and converters.

=head1 METHODS

=head2 check_type_validation( %params )

Hash %params can accept following keys:

=head3 type

Type definition to be checked - just type name, or something more complex.

=head3 good

Reference to array of values that should pass verification.

=head3 bad

Reference to array of values that should fail verification.

=head2 check_converter_validation( %params )

Hash %params can accept following keys:

=head3 type

Converter definition to be checked - just converter name, or something more
complex.

=head3 result

Reference to hash of result/values that will be passed thru converter. Values
can be represented as single value or as arrayref to set of values (where all
of them should issue same result after conversion).

=head1 EXAMPLES

For more examples, see sources of test suite.

=head1 AUTHOR

Oleg Kostyuk, C<< <cub at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to Github
L<https://github.com/cub-uanic/Validator-Declarative>

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Oleg Kostyuk.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

