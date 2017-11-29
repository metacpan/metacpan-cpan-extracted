package Validator::Lazy::Role::Check::CountryCode;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::CountryCode


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { cc => { CountryCode =>   'US'         } } ); # empty, or list, or scalar with 2letters countrycode
    my $v = Validator::Lazy->new( { cc => { CountryCode => [ 'US'       ] } } ); # empty, or list, or scalar with 2letters countrycode
    my $v = Validator::Lazy->new( { cc => { CountryCode => [ 'DE', 'US' ] } } ); # empty, or list, or scalar with 2letters countrycode

    my $ok = $v->check( cc => 'ES' );  # ok is false
    say Dumper $v->errors;  # [ { code => 'COUNTRYCODE_ERROR', field => 'cc', data => { required => [ 'DE', 'US' ] } } ]


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "CountryCode" type for Validator::Lazy config.
    Allows to check 2letters country code.

    When called without param - performs simple check for any country code
    When param is passed - performs additional check as value-in-list

=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - scalar or list. can contain any 2-letters country code(s)
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
use Locale::Codes;


sub check {
    my ( $self, $value, $param ) = @_;

    return $value  unless $value;

    my @allowed_cc =
        $param
            ? ref $param && ref $param eq 'ARRAY'
                ? @$param
                : ref $param
                    ? ()
                    : $param
            : ();

    chomp $value;

    my $l = Locale::Codes->new( "country" );
    $l->show_errors(0);

    eval{
        $value =~ /^[A-Z]{2}$/
        &&
        $l->code2name( $value )
    }
    or do {
        $self->add_error( scalar @allowed_cc ? { required => \@allowed_cc } : () );
        return $value;
    };

    if ( @allowed_cc ) {
        unless ( scalar grep /^$value$/, @allowed_cc ) {
            $self->add_error( { required => \@allowed_cc } );
        };
    };

    return $value;
};

1;
