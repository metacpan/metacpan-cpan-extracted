package Validator::Lazy::Role::Composer;

our $VERSION = '0.03';

=head1 NAME

    Validator::Lazy::Role::Composer


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

Provides "Composer" role for Validator::Lazy, part of Validator::Lazy package.

Contains $validator->get_field_roles, that performs compillation of configuration of validator.

=head1 METHODS

=head2 C<get_field_roles>

    $validator->get_field_roles( $field, @skip_classes );


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


=head2 C<get_field_roles>

    $validator->get_field_roles( $field, @skip_classes );

    $field - field name for which we should find all classes to validate
    @skip_classes - classes which is already done and do not need to be affected

=cut

sub get_field_roles {
    my ( $self, $field, @skip_classes ) = @_;

    confess 'No field name passed!'     unless $field && !ref $field;
    confess 'Wrong field name passed!'  unless $field =~ /^.+$/;

    my @classes;

    # Just seek for classes in config
    while( my( $match, $class ) = each %{ $self->config } ) {

        chomp $match;

        # match can be a regular expression
        if ( $match =~ /^\/(.+)\/$/ ) {
            my $regexp = $1;
            # if field matches with the regexp - all classes from this key will be added
            push @classes, $class  if $field =~ /$regexp/;
        }
        # also, match can be a list [value1|value2]
        elsif ( $match =~ /^\[(.+)\]$/ ) {
            my @key_list = split /[\|,]/, $1;

            # list contains field name
            push @classes, $class  if grep { $_ eq $field } @key_list;
        }
        # direct match
        elsif ( $field eq $match ) {
            push @classes, $class;
        }
    };

    @classes = ( $field )  unless @classes;

    @classes = map { ref $_ eq 'ARRAY' ? @$_ : $_ } @classes;

    # Finding subrelations
    my $changed = 1;
    my $deepness = 30;

    while ( $changed ) {

        confess 'Too deep config relations'  unless --$deepness;

        $changed = 0;

        @classes = map {
            my $class = $_;

            if ( grep { $_ eq $class } @skip_classes ) {
                ();
            }
            elsif ( ref $class || $class =~ /\:/ ) {
                $class;
            }
            elsif ( my @new_classes = $self->get_field_roles( $class, ( @skip_classes, $class ) ) ) {
                $changed = 1;
                @new_classes;
            }
            else {
                $class;
            };
        } @classes;
    }

    # replacing class names to packages
    @classes = map {
        my %class =
            ref $_ eq 'HASH' ? %$_          :
            ! ref $_         ? ( $_ => {} ) :
            confess 'Class should be scalar of arrayref';

        my @result_class;

        while ( my( $class, $params ) = each %class ) {
            $class = 'Validator::Lazy::Role::Check::' . $class  unless $class =~ /\:/;
            push @result_class, { $class => $params };
        };

        @result_class;

    } @classes;

    return @classes;
}

1;
