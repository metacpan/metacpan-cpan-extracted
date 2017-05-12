#!/usr/bin/env perl
use strict;
use warnings;

package Validator::Declarative::Rules::ParametrizedType;
{
  $Validator::Declarative::Rules::ParametrizedType::VERSION = '1.20130722.2105';
}

# ABSTRACT: Declarative parameters validation - default simple types rules

use Error qw/ :try /;
use Scalar::Util qw/ blessed looks_like_number /;
require Validator::Declarative;

#
# INTERNALS
#

sub _validate_min {
    my ( $input, $param ) = @_;
    no warnings;
    throw Error::Simple('does not satisfy MIN')
        if !looks_like_number($input) || !looks_like_number($param) || $input < $param;
}

sub _validate_max {
    my ( $input, $param ) = @_;
    no warnings;
    throw Error::Simple('does not satisfy MAX')
        if !looks_like_number($input) || !looks_like_number($param) || $input > $param;
}

sub _validate_ref {
    my ( $input, $param ) = @_;
    throw Error::Simple('does not satisfy REF') if !ref($input);
    return if !$param;
    $param = [$param] if ref($param) ne 'ARRAY';
    ref($input) eq $_ && return for @$param;
    throw Error::Simple('does not satisfy REF');
}

sub _validate_class {
    my ( $input, $param ) = @_;
    throw Error::Simple('does not satisfy CLASS') if !blessed($input);
    return if !$param;
    $param = [$param] if ref($param) ne 'ARRAY';
    $input->isa($_) && return for @$param;
    throw Error::Simple('does not satisfy CLASS');
}

sub _validate_can {
    my ( $input, $param ) = @_;
    throw Error::Simple('does not satisfy CAN') if !blessed($input) || !$param;
    $param = [$param] if ref($param) ne 'ARRAY';
    $input->can($_) || throw Error::Simple('does not satisfy CAN') for @$param;
    return;
}

sub _validate_can_any {
    my ( $input, $param ) = @_;
    throw Error::Simple('does not satisfy CAN_ANY') if !blessed($input) || !$param;
    $param = [$param] if ref($param) ne 'ARRAY';
    $input->can($_) && return for @$param;
    throw Error::Simple('does not satisfy CAN_ANY');
}

sub _validate_any_of {
    my ( $input, $param ) = @_;
    throw Error::Simple('does not satisfy ANY_OF') if !$param;
    $param = [$param] if ref($param) ne 'ARRAY';
    _smart_match( $input, $_ ) && return for @$param;
    throw Error::Simple('does not satisfy ANY_OF');
}

sub _validate_list_of {
    my ( $input, $param ) = @_;
    ## TBD in next release
}

sub _validate_hash_of {
    my ( $input, $param ) = @_;
    ## TBD in next release
}

sub _validate_hash {
    my ( $input, $param ) = @_;
    ## TBD in next release
}

sub _validate_date {
    my ( $input, $param ) = @_;
    ## TBD in next release
}

# this is limited subset of smart-match operator (~~) from Perl 5.10+
sub _smart_match {
    my ( $x, $y ) = @_;
    looks_like_number($x) && looks_like_number($y) && return $x == $y;
    ref($y) eq 'CODE' && return $y->($x);
    ref($y) eq 'Regexp' && return $x =~ m/$y/;
    return $x eq $y;
}

sub _register_default_parametrized_types {
    Validator::Declarative::register_type(
        ## simple parametrized types
        min      => \&_validate_min,
        max      => \&_validate_max,
        ref      => \&_validate_ref,
        class    => \&_validate_class,
        ducktype => \&_validate_can,
        can      => \&_validate_can,
        can_any  => \&_validate_can_any,
        any_of   => \&_validate_any_of,
        enum     => \&_validate_any_of,
        ## complex/recursive parametrized types
        list_of => \&Validator::Declarative::_validate_pass,
        hash_of => \&Validator::Declarative::_validate_pass,
        hash    => \&Validator::Declarative::_validate_pass,
        date    => \&Validator::Declarative::_validate_pass,
    );
}

_register_default_parametrized_types();


1;    # End of Validator::Declarative::Rules::ParametrizedType


__END__
=pod

=head1 NAME

Validator::Declarative::Rules::ParametrizedType - Declarative parameters validation - default simple types rules

=head1 VERSION

version 1.20130722.2105

=head1 DESCRIPTION

Internally used by Validator::Declarative.

=head1 METHODS

There is no public methods.

=head1 SEE ALSO

L<Validator::Declarative>

=head1 AUTHOR

Oleg Kostyuk, C<< <cub at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/cub-uanic/Validator-Declarative>

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Oleg Kostyuk.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

