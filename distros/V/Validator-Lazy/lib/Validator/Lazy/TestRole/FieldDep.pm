package Validator::Lazy::TestRole::FieldDep;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::TestRole::FieldDep


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( );

    my $ok = $v->check( Test => 'xxxxx' );


=head1 DESCRIPTION

    An example of external role definition.


=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );


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

sub before_check {
    my ( $self, $value ) = @_;

    # For the Form roles $value is a HashRef!
    # $value->{field_name}

    return $value;
};

sub check {
    my ( $self, $value ) = @_;

    $self->add_error( );
    $self->add_warning( );

    return $value;
};

sub after_check {
    my ( $self, $value ) = @_;

    return $value;
};

1;
