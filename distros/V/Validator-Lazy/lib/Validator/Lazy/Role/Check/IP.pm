package Validator::Lazy::Role::Check::IP;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::IP


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { ip => { IP => { v => 4, type => 'Public' } } } ); # empty, or list, or scalar with 2letters countrycode

    my $ok = $v->check( ip => '192.1.1.1' );  # ok is false
    say Dumper $v->errors;  # [ { code => 'IP_PUBLIC_TYPE_REQUIRED', field => 'ip', data => { } } ]


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "IP" type for Validator::Lazy config.
    Allows to check ip addresses.

    When called without param - performs simple check as any valid ip
    When param is passed - performs additional check as value-in-list

=head1 METHODS

=head2 C<check>

    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - hash, that can contain this optional keys:
        'version' or 'ver' or 'v' = v4 v6 4 6
        'type' = Public|Private|Reserved|Loopback|... as described in Net::IP package
        'mask' = 32,24,16,...

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
use Net::IP;


sub check {
    my ( $self, $value, $param ) = @_;

    return $value  unless $value;

    my $ip = Net::IP->new( $value );

    unless ( $ip ) {
        $self->add_error();
        return $value;
    }

    if ( my $err = $ip->error() ) {
        $self->add_error( { error_code => $err } );
        return $value;
    }
    # ver => [ 4, 6 ]
    my $v = $param->{version} || $param->{ver} || $param->{v};

    if ( $v ) {

        $v =~ s/^v//i;

        confess 'Bad version. ver = 4 or 6 allowed'  unless $v =~ /^[46]$/;

        if ( $ip->version ne $v ) {
            $self->add_error( 'IP_V' . $v . '_REQUIRED' );
            return $value;
        };
    };

    if ( my $tt = $param->{type} ) {

        my @t =
            ref $tt && ref $tt eq 'ARRAY' ? @$tt :
            ! ref $tt ? [ $tt ] :
            ();

        my $t_ok = scalar @t;
        $t_ok &&= /^[A-Z]+$/i for @t;
        confess 'Bad type. type = [Public|Private|Reserved|Loopback|...] allowed'  unless $t_ok;

        for my $t ( @t ) {
            # type => [ Public, Private, Reserved, Loopback,... ]
            if ( $ip->iptype ne uc($t) ) {
                $self->add_error( 'IP_' . uc($t) . '_TYPE_REQUIRED' );
                return $value;
            };
        };
    };

    # mask => 32/24/...
    if ( my $m = $param->{mask} ) {
        confess 'Bad mask. mask = dd allowed'  unless $m =~ /^\d{1,2}$/;

        if ( $ip->prefixlen ne $m ) {
            $self->add_error( 'MASK_ERROR', { required => $m } );
            return $value;
        };
    };

    return $value;
};

1;
