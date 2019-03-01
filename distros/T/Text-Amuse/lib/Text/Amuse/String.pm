package Text::Amuse::String;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::String - Process one-line muse strings.

=head1 SYNOPSIS

This module provides a minimal class compatible with
Text::Amuse::Document to process single strings passed via value.

=head1 CONSTRUCTORS

=over 4

=item new ($string)

Constructor

=cut

sub new {
    my ($class, $string, $lang) = @_;
    my $self = {
                _raw_string => $string,
                _lang => $lang || 'en',
               };
    bless $self, $class;
    return $self;
};

=back

=head1 METHODS

=over 4

=item string

The string stored

=cut

sub string {
    return shift->{_raw_string};
}

=item elements

It returns the only L<Text::Amuse::Element> which composes the body.

=cut


sub elements {
    my $self = shift;
    my $el = Text::Amuse::Element->new(type => 'standalone',
                                       string => $self->string);
    return ($el);
}

=back

=head2 Fake methods

They return nothing, but nevertheless the Output module won't complain.

=over 4

=item raw_header

=item get_footnote

=item attachments

=item language_code

=back

=cut


sub raw_header {
    return;
}

sub get_footnote {
    return;
}

sub attachments {
    return;
}

sub language_code {
    shift->{_lang};
}

1;
