# ABSTRACT: Email Directive for Validation Class Field Definitions

package Validation::Class::Directive::Email;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s requires a valid email address';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{email} && defined $param) {

        if ($field->{required} || $param) {

            my $ere = qr/^[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+)*@(?:[-_a-z0-9][-_a-z0-9]*\.)*(?:[a-z0-9][-a-z0-9]{0,62})\.(?:(?:[a-z]{2}\.)?[a-z]{2,4}|museum|travel)$/;

            $self->error($proto, $field) unless $param =~ $ere;

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Email - Email Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            user_email => {
                email => 1
            }
        }
    );

    # set parameters to be validated
    $rules->params->add($parameters);

    # validate
    unless ($rules->validate) {
        # handle the failures
    }

=head1 DESCRIPTION

Validation::Class::Directive::Email is a core validation class field directive
that checks the validity of email addresses specified by the associated
parameters. Please note, the email directive does not perform a host lookup
nor does it conform to the RFC specification. For more sophisticated email
validation, please use custom validation with L<Email::Valid> or similar.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
