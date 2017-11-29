package Validator::Lazy::Role::Check::Email;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::Email


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( { email => { Email => $param } } ); # $param is hash, or can be ommitted

    my $ok = $v->check( email => 'info@info.com' );  # ok is true, $v->errors is empty list

    my $ok = $v->check( email => 'xxxxxxx' );  # ok is false, $v->errors is empty list
    say Dumper $v->errors;  # [ { code => 'EMAIL_ERROR', field => 'email', data => {} ]


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "Email" type for Validator::Lazy config.
    Allows to check value as an Email.

    When called without param - performs simple check by default

=head1 METHODS

=head2 C<check>
    Called from inside if Validator::Lazy->check process

    Temporary overrides internal Validator::Lazy::check method like this:

    $validator->check( $value, $param );

    $param - scalar or list. can contain any 2-letters country code(s)
    $value - your value to check


    $param is HASH, that contains this values by default ( if it is not passed ):
        -tldcheck     => 1,
        -fudge        => 1,
        -fqdn         => 1,
        -allow_ip     => 0,
        -mxcheck      => 0,
        -local_rules  => 0,

    You can pass any of this params. In this case all params, passed by you, will override default ones.
    Detailed description of params you can find in Email::Valid ( https://metacpan.org/pod/Email::Valid )


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
use Email::Valid;

sub check {
    my ( $self, $value, $param ) = @_;

    return $value  unless $value;

    my %param = (
        -tldcheck     => 1,
        -fudge        => 1,
        -fqdn         => 1,
        -allow_ip     => 0,
        -mxcheck      => 0,
        -local_rules  => 0,
        %{ $param // {} },
    );

    my $address = eval{
        Email::Valid->address( -address => $value, %param );
    };

    if ( $@ ) {
        $self->add_error( { die_reason => $@ } );
        return $value;
    };

    unless ( $address ) {
        # rfc822 localpart local_rules fqdn mxcheck tldcheck
        my $code = $Email::Valid::Details;
        $self->add_error( { error_code => $code } );
    }

    return $value;
};

1;
