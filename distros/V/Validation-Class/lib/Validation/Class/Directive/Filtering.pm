# ABSTRACT: Filtering Directive for Validation Class Field Definitions

package Validation::Class::Directive::Filtering;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 0;
has 'dependencies' => sub {{
    normalization => ['alias'],
    validation    => []
}};

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # by default fields should have a filtering directive
    # unless already specified

    $field->{filtering} = $proto->filtering unless defined $field->{filtering};

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Filtering - Filtering Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            telephone_number => {
                filters   => ['numeric']
                filtering => 'post'
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

Validation::Class::Directive::Filtering is a core validation class field
directive that specifies whether filtering and sanitation should occur as a
pre-process or post-process.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
