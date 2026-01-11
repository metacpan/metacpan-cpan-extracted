package Wordsmith::Claude::Result;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'original!'   => Str,              # Original input text
    'text!'       => Str,              # Rewritten text (or first variation)
    'mode?'       => Str,              # Mode used (if any)
    'variations?' => ArrayRef[Str],    # All variations (if requested)
    'error?'      => Str;              # Error message (if failed)

=head1 NAME

Wordsmith::Claude::Result - Result object for rewritten text

=head1 SYNOPSIS

    my $result = rewrite(text => $input, mode => 'eli5', loop => $loop)->get;

    # Get the rewritten text
    print $result->text;

    # Check for errors
    if ($result->has_error) {
        die "Rewrite failed: " . $result->error;
    }

    # Access original
    print "Original: ", $result->original, "\n";
    print "Rewritten: ", $result->text, "\n";

    # With variations
    my $result = rewrite(
        text => $input,
        mode => 'casual',
        variations => 3,
        loop => $loop,
    )->get;

    for my $var ($result->all_variations) {
        print "- $var\n";
    }

=head1 DESCRIPTION

Result object returned by the C<rewrite()> function containing the
rewritten text and metadata.

=head1 ATTRIBUTES

=head2 original

The original input text.

=head2 text

The rewritten text. If variations were requested, this is the first variation.

=head2 mode

The mode used for rewriting (if a preset mode was used).

=head2 variations

ArrayRef of all variations if multiple were requested.

=head2 error

Error message if the rewrite failed.

=head1 METHODS

=head2 all_variations

    my @vars = $result->all_variations;

Returns all variations as a list. If no variations were requested,
returns the single rewritten text.

=cut

sub all_variations {
    my ($self) = @_;

    if ($self->has_variations && @{$self->variations}) {
        return @{$self->variations};
    }

    return ($self->text);
}

=head2 variation

    my $text = $result->variation(0);  # First variation
    my $text = $result->variation(2);  # Third variation

Get a specific variation by index (0-based).

=cut

sub variation {
    my ($self, $index) = @_;

    if ($self->has_variations && @{$self->variations}) {
        return $self->variations->[$index];
    }

    return $index == 0 ? $self->text : undef;
}

=head2 variation_count

    my $count = $result->variation_count;

Returns the number of variations available.

=cut

sub variation_count {
    my ($self) = @_;

    if ($self->has_variations && @{$self->variations}) {
        return scalar @{$self->variations};
    }

    return 1;
}

=head2 is_success

    if ($result->is_success) { ... }

Returns true if the rewrite succeeded (no error).

=cut

sub is_success {
    my ($self) = @_;
    return !$self->has_error;
}

=head2 is_error

    if ($result->is_error) { ... }

Returns true if the rewrite failed.

=cut

sub is_error {
    my ($self) = @_;
    return $self->has_error;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
