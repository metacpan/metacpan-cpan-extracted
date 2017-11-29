package Validator::Lazy::Role::Check::MinMax;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::MinMax


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { minmax => { MinMax => { min => 2, max => 4, type => 'Str' } } } );
    my $v = Validator::Lazy->new( { minmax => { MinMax => [ $min, $max, $type                 ] } } );

    my $ok = $v->check( minmax => 'xxxxx' );  # ok is false
    say Dumper $v->errors;  # [ { code => 'TOO_BIG', field => 'minmax', data => { min => 2, max => 4 } } ]


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "MinMax" type for Validator::Lazy config.
    Allows to check value for predefined range (from-to-valuetype).


=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - is a list = [ minvalue, maxvalue, valuetype ]
    OR
    $param - is a hash = { min => minvalue, max => maxvalue, type => Str or Int ]

    $value - your value to check


=head1 SUPPORT AND DOCUMENTATION

    After installing, you can find documentation for this module with the perldoc command.

    perldoc Validator::Lazy

    You can also look for information at:

        RT, CPAN's request tracker (report bugs here)
            http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-Lazy

        AnnoCPAN, Annotated CPAN documentation
            http://annocpan.org/dist/Validator-Lazy

        CPAN Ratings
            http://cpanratings.perl.org/d/Validator-Lazy

        Search CPAN
            http://search.cpan.org/dist/Validator-Lazy/


=head1 AUTHOR

ANTONC <antonc@cpan.org>

=head1 LICENSE

    This program is free software; you can redistribute it and/or modify it
    under the terms of the the Artistic License (2.0). You may obtain a
    copy of the full license at:

    L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

use v5.14.0;
use utf8;
use Modern::Perl;
use Moose::Role;

# min => ?, max => ?, type => ?

sub before_check {
    my ( $self, $value ) = @_;

    return $value  unless defined $value;

    chomp $value;
    $value =~ s/(^\s+|\s+$)//ag;

    return $value;
};

sub check {
    my ( $self, $value, $param ) = @_;

    return $value  unless defined $value && $param;

    if ( $param && ref $param eq 'ARRAY' ) {
        $param = {
            min  => $param->[0],
            max  => $param->[1],
            type => $param->[2],
        };
    };

    my $type = $param->{type} || 'Str';
    # $type ||= $value =~ /^\-?\d+(\.\d)?/ ? 'Int' : 'Str';

    my ( $min, $max ) = ( @$param{ qw/ min max / } );

    if ( $type eq 'Int' ) {
        $min //= 0;
        $max //= 1000;
        $self->add_error( 'TOO_SMALL', { min => $min, max => $max } )  if $value < $min;
        $self->add_error( 'TOO_BIG',   { min => $min, max => $max } )  if $value > $max;
    }
    elsif ( $type eq 'Str' ) {
        $min //= 0;
        $max //= 64;
        $self->add_error( 'TOO_SMALL', { min => $min, max => $max } )  if length( $value ) < $min;
        $self->add_error( 'TOO_BIG',   { min => $min, max => $max } )  if length( $value ) > $max;
    }
    else {
        confess 'Unknown type. Avaliable values are: Str,Int' unless $type && $type =~ /^(Int|Str)$/;
    };

    return $value;
};

1;
