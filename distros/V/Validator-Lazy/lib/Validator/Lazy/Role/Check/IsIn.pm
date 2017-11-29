package Validator::Lazy::Role::Check::IsIn;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::IsIn

=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { isin => { IsIn => [ your list of allowed values ] } } );

    my $ok = $v->check( isin => 'your value' );
    say Dumper $v->errors;  # [ { code => 'ISIN_ERROR', field => 'isin', data => { required => [ your list of allowed values ] } } ]


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "IsIn" type for Validator::Lazy config.
    Allows to check value's existance in list from config.


=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - list of allowed for field values.
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

sub check {
    my ( $self, $value, $param ) = @_;

    return $value  unless $value && $param;

    $param = [ $param ]  unless ref $param;
    my @set = @$param;

    unless ( grep /^$value$/sm, @set ) {
        $self->add_error( { required => \@set } );

        return $value;
    }

    return $value;
};

1;
