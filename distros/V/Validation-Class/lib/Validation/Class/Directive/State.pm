# ABSTRACT: State Directive for Validation Class Field Definitions

package Validation::Class::Directive::State;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not a valid state';
has 'regexp'  => sub {sprintf'^(%s)$',join'|',map{quotemeta}@{shift->states}};
has 'states'  => sub {[ # u.s. states and territories
    'Alabama',
    'Alaska',
    'Arizona',
    'Arkansas',
    'California',
    'Colorado',
    'Connecticut',
    'Delaware',
    'Florida',
    'Georgia',
    'Hawaii',
    'Idaho',
    'Illinois',
    'Indiana',
    'Iowa',
    'Kansas',
    'Kentucky',
    'Louisiana',
    'Maine',
    'Maryland',
    'Massachusetts',
    'Michigan',
    'Minnesota',
    'Mississippi',
    'Missouri',
    'Montana',
    'Nebraska',
    'Nevada',
    'New Hampshire',
    'New Jersey',
    'New Mexico',
    'New York',
    'North Carolina',
    'North Dakota',
    'Ohio',
    'Oklahoma',
    'Oregon',
    'Pennsylvania',
    'Rhode Island',
    'South Carolina',
    'South Dakota',
    'Tennessee',
    'Texas',
    'Utah',
    'Vermont',
    'Virginia',
    'Washington',
    'West Virginia',
    'Wisconsin',
    'Wyoming',
    'District of Columbia',
    'Puerto Rico',
    'Guam',
    'American Samoa',
    'U.S. Virgin Islands',
    'Northern Mariana Islands',
]};

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{state} && defined $param) {

        if ($field->{required} || $param) {

            my $type = $field->{state};
            my $lre  = $self->regexp;

            my $sre = {
                'abbr' => qr/^(A[LKSZRAEP]|C[AOT]|D[EC]|F[LM]|G[AU]|HI|I[ADLN]|K[SY]|LA|M[ADEHINOPST]|N[CDEHJMVY]|O[HKR]|P[ARW]|RI|S[CD]|T[NX]|UT|V[AIT]|W[AIVY])$/i,
                'long' => qr/$lre/i,
            };

            my $is_valid = 0;

            $type = isa_arrayref($type) ? $type : $type == 1 ? [keys %$sre] : [$type];

            for (@{$type}) {

                if ($param =~ $sre->{$_}) {
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

Validation::Class::Directive::State - State Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            address_state => {
                state => 1
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

Validation::Class::Directive::State is a core validation class field directive
that handles state validation for states in the USA. States will be validated
against a list of state (case-insensitive abbreviated and long) names.

For example: ny, NY, New York, and new york will validate.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
