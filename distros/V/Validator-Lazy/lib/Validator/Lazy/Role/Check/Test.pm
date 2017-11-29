package Validator::Lazy::Role::Check::Test;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::Test


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( );

    my $ok = $v->check( Test => 'xxxxx' );


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "Test" type for Validator::Lazy config.
    It is not useful package for you. It's just an example,
    what we can do with lazy validator and some help for core-testing as well.


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

    $self->add_error(   { x_err  => 'err data'  } );
    $self->add_warning( { x_warn => 'warn data' } );

    return $value + 5;
};

sub check {
    my ( $self, $value ) = @_;

    $self->add_error(   'CHECK_TEST_ERR_CODE' => { x_chk_err  => 'err check data'  } );
    $self->add_warning( 'CHECK_TEST_WRN_CODE' => { x_chk_warn => 'warn check data' } );

    return $value + 50;
};

sub after_check {
    my ( $self, $value ) = @_;

    $self->add_error(   'AFTER_TEST_ERR_CODE' );
    $self->add_warning( 'AFTER_TEST_WRN_CODE' );

    return $value + 500;
};

1;
