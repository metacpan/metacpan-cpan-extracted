package Validator::Lazy::Role::Notifications;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Notifications


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use Validator::Lazy;
    my $v = Validator::Lazy->new( $config );

    my $ok = $v->check( $hashref_of_your_data_to_chech );  # true / false
    OR
    my ( $ok, $data ) = $v->check( $hashref_of_your_data_to_chech );  # true / false

    say Dumper $v->errors;    # [ { code => any_error_code, field => field_with_error, data => { variable data for more accurate error definition } } ]
    say Dumper $v->warnings;  # [ { code => any_warn_code,  field => field_with_warn,  data => { variable data for more accurate warn  definition } } ]
    say Dumper $v->data;      # Fixed data. For example trimmed strings, corrected char case, etc...

=head1 DESCRIPTION

Provides "Notifications" role for Validator::Lazy, part of Validator::Lazy package.

Methods:
    $validator->add_error,   that adding error to $validator object.
    $validator->add_warning, that adding warning to $validator object.

Each of these methods can be called with 0,1 or 2 params.

If param count is 0 then default error/warn will be generated.

By default it is a hash = { field => field_with_error, code => working_check_role_name . '_ERROR', data => {} }

If param count is 1:
    if param is a HASH, then we interpret it as "data" for error/warn hash
    if param is scalar then it will be error/warn code for error/warn hash

If param count is 2, then the first param is error/warn code, the 2nd is "data"


=head1 METHODS

=head2 C<add_error>

    $validator->add_error( );
    $validator->add_error( $code );
    $validator->add_error( $data );
    $validator->add_error( $code, $data );


=head2 C<add_warning>

    $validator->add_warning( );
    $validator->add_warning( $code );
    $validator->add_warning( $data );
    $validator->add_warning( $code, $data );

=head2 C<errors>
    $validator->errors; # ArrayRef of errors hashrefs in order of their apearing

=head2 C<warnings>
    $validator->warnings; # ArrayRef of warnings hashrefs in order of their apearing

=head2 C<error_codes>
    $validator->error_codes; # ArrayRef of warning codes in order of their apearing

=head2 C<warning_codes>
    $validator->warning_codes; # ArrayRef of error codes in order of their apearing


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


# [ { name => { error_code => 'REQUIRED', error_data => {} } }, ... ]
has errors => (
    is       => 'rw',
    isa      => 'ArrayRef[HashRef]',
    init_arg => undef,
    traits   => ['Array'],
    handles => {
        _add_error => 'push',
    },
);


# [ { name => { error_code => 'REQUIRED', error_data => {} } }, ... ]
has warnings => (
    is       => 'rw',
    isa      => 'ArrayRef[HashRef]',
    init_arg => undef,
    traits   => ['Array'],
    handles => {
        _add_warning => 'push',
    },
);


sub add_error {
    my ( $self, $code, $data ) = @_;

    $data = $code  if $code  &&  ref $code eq 'HASH';
    $data //= {};

    $self->_add_error( {
        field => $self->get_full_current_field_name,
        code  => _get_full_code( $code, 'ERROR' ),
        data  => $data,
    } );
}


sub add_warning {
    my ( $self, $code, $data ) = @_;

    $data = $code  if $code  &&  ref $code eq 'HASH';
    $data //= {};

    $self->_add_warning( {
        field => $self->get_full_current_field_name,
        code  => _get_full_code( $code, 'WARNING' ),
        data  => $data,
    } );
}


sub error_codes {
    my ( $self ) = @_;

    return [ map { $_->{code} } @{ $self->errors } ];
};


sub warning_codes {
    my ( $self ) = @_;

    return [ map { $_->{code} } @{ $self->warnings } ];
};

sub _get_full_code {
    my ( $code, $type ) = @_;

    if ( !$code || ref $code ) {
        my $caller = uc caller(1);
        $caller =~ s/^.+::ROLE::(CHECK::)?//;
        $caller =~ s/\:+/_/g;
        $code = $caller . '_' . $type;
    };

    return $code;
};

1;
