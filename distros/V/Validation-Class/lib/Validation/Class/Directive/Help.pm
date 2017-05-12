# ABSTRACT: Help Directive for Validation Class Field Definitions

package Validation::Class::Directive::Help;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

our $VERSION = '7.900057'; # VERSION


has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

sub normalize {

    my ($self, $proto, $field) = @_;

    # static help-text may contain multiline strings for the sake of
    # aesthetics, flatten them here

    if (defined $field->{help}) {

        $field->{help} =~ s/^[\n\s\t\r]+//g;
        $field->{help} =~ s/[\n\s\t\r]+$//g;
        $field->{help} =~ s/[\n\s\t\r]+/ /g;

    }

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive::Help - Help Directive for Validation Class Field Definitions

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            username => {
                help => q/A username was automatically generated for you
                at the time you registered your account. Check your email
                client for additional instructions./
            }
        }
    );

=head1 DESCRIPTION

Validation::Class::Directive::Help is a core validation class field
directive that holds the help-text statement(s) to be associated with specific
fields which are useful when rendering form fields or when developing RESTful
API resources.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
