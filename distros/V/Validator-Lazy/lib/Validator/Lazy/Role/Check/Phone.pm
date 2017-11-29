package Validator::Lazy::Role::Check::Phone;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::Phone


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { phone => { Phone => { mobile|not_mobile => 1/0, cc|country => [] } } } );
    my $v = Validator::Lazy->new( { phone => { Phone => [ mobile|not_mobile|your_country_code(s)     ] } } );

    my $ok = $v->check( phone => 'xxxxx' );  # ok is false
    say Dumper $v->errors;  # [ { code => 'PHONE_BAD_FORMAT', field => 'phone', data => { } } ]

    my $v = Validator::Lazy->new( { phone => { Phone => { mobile => 1, cc => [ 'US', 'CA' ] } } } );
    my $v = Validator::Lazy->new( { phone => [ 'mobile', 'US', 'CA' ] } );

=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "Phone" type for Validator::Lazy config.
    Allows to check value as Phone number.


=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - is a list = [ mobile|not_mobile|2chars_values_traits_as_allowed_country_codes ]
    OR
    $param - is a hash = { mobile => 1, not_mobile => 1, cc => ['list or string'] ]

    all params are optional
    in case, whel all params are omitted, then simple phone check will be done.

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

use Number::Phone;


use constant {
    BAD_FORMAT   => 'PHONE_BAD_FORMAT',
    BAD_NUMBER   => 'PHONE_BAD_NUMBER',
    MOBILE       => 'PHONE_IS_MOBILE',
    NOT_MOBILE   => 'PHONE_IS_NOT_MOBILE',
    BAD_COUNTRY  => 'PHONE_WRONG_COUNTRY',
};


sub before_check {
    my ( $self, $value ) = @_;

    if ( $value ) {
        $value =~ s/(^\s+|\s+$)//aaig;
    }

    return $value;
};

sub check {
    my ( $self, $value, $param ) = @_;

    # not required
    return $value  unless $value;

    if( $value !~ /^\+?[1-9][0-9]{0,2}[. ]?\(?[0-9]{2,3}\)?\s*[0-9 -]{3,9}$/ ) {
        $self->add_error( BAD_FORMAT );
        return $value;
    }

    my $phone = Number::Phone->new( $value );

    unless ( $phone  &&  $phone->is_valid ) {
        $self->add_error( BAD_NUMBER );
        return $value;
    };

    my @param_keys = ref $param eq 'ARRAY' ? @$param : keys %$param;


    if ( grep /^mobile$/, @param_keys  and  !$phone->is_mobile ) {
        $self->add_error( NOT_MOBILE );
        return $value;
    };

    if ( grep /^not_mobile$/, @param_keys  and  $phone->is_mobile ) {
        $self->add_error( MOBILE );
        return $value;
    };

    my @cc = grep /^.{2}$/, @param_keys;

    if ( ref $param eq 'HASH' ) {

        for ( qw/ cc country / ) {
            next  unless $param->{$_};
            $param->{$_} = [ $param->{$_} ]  unless ref $param->{$_};

            push @cc, @{ $param->{$_} };
        }
    }

    return $value  unless @cc;

    unless ( grep { $_ eq $phone->country } @cc ) {
        $self->add_error( BAD_COUNTRY, { required => \@cc, current => $phone->country } );
        return $value;
    };

    return $value;
};

1;
