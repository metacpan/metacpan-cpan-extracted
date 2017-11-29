package Validator::Lazy::Role::Check::Form;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check::Form


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( Form => [ simple list of field names ] ); # empty, or list, or scalar with 2letters countrycode

    BUT! Form validation is a more complicaded construction than simple scalars, so we should use more advansed configuration,
    so we may use YAML or something like it as a config.

    Some examples:

        my $v = Validator::Lazy->new( 'string without \n interprets as a file name. extention will interprets as a file format' );
        my $v = Validator::Lazy->new( 'string WITH \n's interprets as YAML' );
        my $v = Validator::Lazy->new( { HASH interprets as a ready for work config } );

    my $ok = $v->check( { form => { Form => { hash of field-name => value pairs to check } } } );

    say Dumper $v->errors;

    Please check more details about forms in Validator::Lazy


=head1 DESCRIPTION

    An internal Role for Validator::Lazy, part of Validator::Lazy package.

    Provides "Form" type for Validator::Lazy config.
    Allows to check hashes as a key-value forms.


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

    return $value unless $value;

    confess 'Form should be a Hashref!'  unless ref $value eq 'HASH';

    return $value;
}

sub check {
    my ( $self, $value, $param ) = @_;

    $param = []  unless $param && ref $param eq 'ARRAY';

    my @prefixes;
    my @fixed_params;

    for my $par ( @$param ) {
        if ( $par  &&  ref $par eq 'ARRAY' ) {
            @prefixes = @$par;
        }
        elsif ( !$par ) {
            @prefixes = ();
        }
        elsif ( @prefixes ) {
            push @fixed_params, $_ . '_' . $par for @prefixes;
        }
        else {
            push @fixed_params, $par;
        };
    };

    # All fields mentioned in Form params should be checked,
    # because we should check ALL form params, not only passed
    $value->{$_} //= undef  for @fixed_params;

    my $validator = Validator::Lazy->new( $self->config );
    push @{ $validator->form_stack }, ( @{ $self->form_stack }, $self->current_field );
    $validator->check( %$value );

    push @{ $self->errors   }, @{ $validator->errors()   };
    push @{ $self->warnings }, @{ $validator->warnings() };

    return $value;
};

1;
