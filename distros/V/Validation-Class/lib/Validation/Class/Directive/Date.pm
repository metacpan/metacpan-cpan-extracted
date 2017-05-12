# ABSTRACT: Date Directive for Validation Class Field Definitions

package Validation::Class::Directive::Date;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s requires a valid date';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{date} && defined $param) {

        my $dtre = {
            # options:
            # dmy 27-12-2006 or 27-12-06 separators can be a space, period, dash, forward slash
            # mdy 12-27-2006 or 12-27-06 separators can be a space, period, dash, forward slash
            # ymd 2006-12-27 or 06-12-27 separators can be a space, period, dash, forward slash
            # dMy 27 December 2006 or 27 Dec 2006
            # Mdy December 27, 2006 or Dec 27, 2006 comma is optional
            # My December 2006 or Dec 2006
            # my 12/2006 separators can be a space, period, dash, forward slash
            'dmy' => qr%^(?:(?:31(\/|-|\.|\x20)(?:0?[13578]|1[02]))\1|(?:(?:29|30)(\/|-|\.|\x20)(?:0?[1,3-9]|1[0-2])\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})$|^(?:29(\/|-|\.|\x20)0?2\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\d|2[0-8])(\/|-|\.|\x20)(?:(?:0?[1-9])|(?:1[0-2]))\4(?:(?:1[6-9]|[2-9]\d)?\d{2})$%,
            'mdy' => qr%^(?:(?:(?:0?[13578]|1[02])(\/|-|\.|\x20)31)\1|(?:(?:0?[13-9]|1[0-2])(\/|-|\.|\x20)(?:29|30)\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})$|^(?:0?2(\/|-|\.|\x20)29\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:(?:0?[1-9])|(?:1[0-2]))(\/|-|\.|\x20)(?:0?[1-9]|1\d|2[0-8])\4(?:(?:1[6-9]|[2-9]\d)?\d{2})$%,
            'ymd' => qr%^(?:(?:(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00)))(\/|-|\.|\x20)(?:0?2\1(?:29)))|(?:(?:(?:1[6-9]|[2-9]\d)?\d{2})(\/|-|\.|\x20)(?:(?:(?:0?[13578]|1[02])\2(?:31))|(?:(?:0?[1,3-9]|1[0-2])\2(29|30))|(?:(?:0?[1-9])|(?:1[0-2]))\2(?:0?[1-9]|1\d|2[0-8]))))$%,
            'dMy' => qr%^((31(?!\ (Feb(ruary)?|Apr(il)?|June?|(Sep(?=\b|t)t?|Nov)(ember)?)))|((30|29)(?!\ Feb(ruary)?))|(29(?=\ Feb(ruary)?\ (((1[6-9]|[2-9]\d)(0[48]|[2468][048]|[13579][26])|((16|[2468][048]|[3579][26])00)))))|(0?[1-9])|1\d|2[0-8])\ (Jan(uary)?|Feb(ruary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep(?=\b|t)t?|Nov|Dec)(ember)?)\ ((1[6-9]|[2-9]\d)\d{2})$%,
            'Mdy' => qr%^(?:(((Jan(uary)?|Ma(r(ch)?|y)|Jul(y)?|Aug(ust)?|Oct(ober)?|Dec(ember)?)\ 31)|((Jan(uary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep)(tember)?|(Nov|Dec)(ember)?)\ (0?[1-9]|([12]\d)|30))|(Feb(ruary)?\ (0?[1-9]|1\d|2[0-8]|(29(?=,?\ ((1[6-9]|[2-9]\d)(0[48]|[2468][048]|[13579][26])|((16|[2468][048]|[3579][26])00)))))))\,?\ ((1[6-9]|[2-9]\d)\d{2}))$%,
            'My'  => qr%^(Jan(uary)?|Feb(ruary)?|Ma(r(ch)?|y)|Apr(il)?|Ju((ly?)|(ne?))|Aug(ust)?|Oct(ober)?|(Sep(?=\b|t)t?|Nov|Dec)(ember)?)[ /]((1[6-9]|[2-9]\d)\d{2})$%,
            'my'  => qr%^(((0[123456789]|10|11|12)([- /.])(([1][9][0-9][0-9])|([2][0-9][0-9][0-9]))))$%
        };

        my $type = $field->{date};

        if ($field->{required} || $param) {

            my $is_valid = 0;

            $type = isa_arrayref($type) ?
                $type : $type eq '1' ? [sort keys %$dtre] : [$type]
            ;

            for (@{$type}) {

                if ($param =~ $dtre->{$_}) {
                    $is_valid = 1;
                    last;
                }

            }

            $self->error($proto, $field) unless $is_valid;

        }

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Date - Date Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            creation_date  => {
                date => 1
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

Validation::Class::Directive::Date is a core validation class field
directive that provides validation of simple date formats.

=over 8

=item * alternative argument: an-array-of-options

=item * option: dmy e.g. 27-12-2006 or 27-12-06

=item * option: mdy e.g. 12-27-2006 or 12-27-06

=item * option: ymd e.g. 2006-12-27 or 06-12-27

=item * option: dMy e.g. 27 December 2006 or 27 Dec 2006

=item * option: Mdy e.g. December 27, 2006 or Dec 27, 2006 (comma optional)

=item * option: My e.g. December 2006 or Dec 2006

=item * option: my e.g. 12/2006

This directive can be passed a single value or an array of values:

    fields => {
        creation_date  => {
            date => ['dmy', 'mdy']
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
