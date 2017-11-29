package Validator::Lazy::Role::Check;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Check


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

Provides "Check" role for Validator::Lazy, part of Validator::Lazy package.

Contains checking loop during $validator->check call.

Each check iteration will try to execute for each field-class of each field in your_data_hashref sequence of:
    Your::Role::before
    Your::Role::check
    Your::Role::after

Your::Role::before - should be used for precheck, or modification

of form param value. For example you can do trimlr here


Your::Role::check - main functional of called role.

The form value shoild be checked here

and result should be mirrired im validator object


Your::Role::after - After the value is checked,

Role may want to prepare value for something.

For example the role can convert data into internal format,

store checked file to disc or something like that.


=head1 METHODS

=head2 C<check>

    $validator->check( $your_data_hashref );


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
use Moose::Util qw/ ensure_all_roles apply_all_roles /;


=head2 C<check>

    $validator->check( $your_data_hashref );

=cut

sub check {
    my ( $self, %data ) = @_;

    $self->data(     {} );
    $self->errors(   [] );
    $self->warnings( [] );

    # Each key-value of data is independent "form"
    for my $field ( sort keys %data ) {

        $self->current_field( $field );
        my $value = $data{ $field };

        my @roles = $self->get_field_roles( $field );

        for ( @roles ) {
            ( my $role, undef ) = %$_; # just a key

            ensure_all_roles(
                $self,
                $role,
                {
                    -alias => {
                        before_check => _get_role_method_name( $role, 'before' ),
                        check        => _get_role_method_name( $role, 'check'  ),
                        after_check  => _get_role_method_name( $role, 'after'  ),
                    }
                }
            );
        };

        # Overwrite default(last role in this case) check method to common check dispatcheer role
        apply_all_roles( $self, 'Validator::Lazy::Role::Check' );

        for ( @roles ) {
            my ( $role, $param ) = %$_;

            for my $method ( qw/ before check after / ) {
                my $check = $self->can( _get_role_method_name( $role, $method ) ) or next;

                eval{
                    $value = $check->( $self, $value, $param );
                    1;
                }
                or do {
                    $self->add_error(
                        'CHECK_DIED',
                        {
                            field  => $field,
                            data   => {
                                value  => $value,
                                role   => $role,
                                method => $method,
                            },
                        }
                    );
                };
            }

            my @errors = @{ $self->errors } or next;
            last if $errors[-1]{field} eq $self->get_full_current_field_name;
        }

        $data{ $field } = $value;
    }

    $self->data( \%data );

    my $ok = ! scalar @{ $self->errors };

    return wantarray ? ( $ok, \%data ) : ( $ok );
}


sub _get_role_method_name {
    my ( $role, $method ) = @_;

    my $method_prefix = $role;
    $method_prefix =~ s/\:+/-/ig;

    return $method_prefix . '_' . $method;
};

1;
