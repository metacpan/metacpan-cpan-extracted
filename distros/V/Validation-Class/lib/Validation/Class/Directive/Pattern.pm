# ABSTRACT: Pattern Directive for Validation Class Field Definitions

package Validation::Class::Directive::Pattern;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not formatted properly';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{pattern} && defined $param) {

        my $pattern = $field->{pattern};

        if ($field->{required} || $param) {

            unless ( isa_regexp($pattern) ) {

                $pattern =~ s/([^#X ])/\\$1/g;
                $pattern =~ s/#/\\d/g;
                $pattern =~ s/X/[a-zA-Z]/g;
                $pattern = qr/$pattern/;

            }

            unless ( $param =~ $pattern ) {

                $self->error($proto, $field);

            }

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Pattern - Pattern Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            company_email => {
                pattern => qr/\@company\.com$/
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

Validation::Class::Directive::Pattern is a core validation class field directive
that validates simple patterns and complex regular expressions.

=over 8

=item * alternative argument: an-array-of-something

This directive can be passed a regexp object or a simple pattern. A simple
pattern is a string where the `#` character matches digits and the `X` character
matches alphabetic characters.

    fields => {
        task_date => {
            pattern => '##-##-####'
        },
        task_time => {
            pattern => '##:##:##'
        }
    }

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
