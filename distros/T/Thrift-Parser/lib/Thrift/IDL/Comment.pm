package Thrift::IDL::Comment;

=head1 NAME

Thrift::IDL::Comment

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Base>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Base);
__PACKAGE__->mk_accessors(qw(value));

=head1 METHODS

=head2 value

Scalar accessor

=cut

my %styles = (
    c_multiline => qr{^/\* (.+?) \*/$}sx,
    c_single    => qr{^\/\/+ (.*?)$}x,
    perl_single => qr{^[#]+ (.*?)$}x,
);

=head2 style

Returns 'c_multiline', 'c_single' or 'perl_single' depending on what form the comment takes

=cut

sub style {
    my ($self) = @_;

    my $value = $self->value;
    keys %styles; # reset the each
    while (my ($style, $regex) = each %styles) {
        my ($escaped_value) = $value =~ $regex;
        next unless defined $escaped_value;
        return $style;
    }
    die "Unrecognized comment style for '$value'";
}

=head2 escaped_value

Returns the content of the comment, based on the C<style>

=cut

sub escaped_value {
    my ($self) = @_;
	my $value = $self->escaped_value_with_whitespace;
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;
	return $value;
}

sub escaped_value_with_whitespace {
    my ($self) = @_;

    my ($escaped_value) = $self->value =~ $styles{$self->style};
    return $escaped_value;
}

1;
