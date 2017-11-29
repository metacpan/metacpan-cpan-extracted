package Validator::Lazy::Role::Check::Case;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::Case


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { case => { Case => 'all_first_upper' } } ); # upper lower first_upper all_first_upper

    my( $ok,$data ) = $v->check( case => 'john smith' );

    say $data->{case}; # John Smith


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "Case" type for Validator::Lazy config.
    Allows to change case for checked data scalars.
    Do not performs any validations.


=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - scalar. can be one of  [ upper, lower, first_upper, all_first_upper ]
    $value - your value to check, that should be converted as demanded by $param

    param value means:

        upper - all letters in value will be converted to upper case
        lower - all letters in value will be converted to lower case
        first_upper - just the first letter will be converted to upper case
        all_first_upper - first letter of each word in the $value will be converted to upper case


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


sub check {
    my ( $self, $value, $param ) = @_;

    return $value  unless $value;

    $param //= 'upper';

    return {
        upper            => uc( $value ),
        lower            => lc( $value ),
        first_upper      => _fuc(  $value ),
        all_first_upper  => _afuc( $value ),
    }->{ $param };
};


sub _fuc {
    my $value = shift;

    $value = lc $value;
    $value =~ s/^(.)/uc($1)/eg;

    return $value;
}


sub _afuc {
    my $value = shift;

    $value = lc $value;
    $value = _fuc( $value );
    $value =~ s/(?<=\W)(.)/uc($1)/eg;

    return $value;
}


1;
