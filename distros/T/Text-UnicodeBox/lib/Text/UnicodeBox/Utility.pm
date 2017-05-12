package Text::UnicodeBox::Utility;

=head1 NAME

Text::UnicodeBox::Utility

=head1 DESCRIPTION

This module is part of the low level interface to L<Text::UnicodeBox>; you probably don't need to use it directly.

=cut

use strict;
use warnings;
use charnames ();
use Exporter 'import';

our @EXPORT_OK = qw(find_box_unicode_name fetch_box_character normalize_box_character_parameters);
our $report_on_failure = 0;

=head1 EXPORTED METHODS

The following methods are exportable by name.

=head2 fetch_box_character

  my $character = fetch_box_character( vertical => 'heavy' );

Same as C<find_box_unicode_name> but returns the actual symbol.

=cut

sub fetch_box_character {
    my $name = find_box_unicode_name(@_);
	return undef unless $name;

    return chr charnames::vianame($name);
}

=head2 find_box_unicode_name (%spec)

Given a list of directions and styles, find a matching unicode name that can represent the symbol.  Returns undefined if no such symbol exists.

The spec may contain keys like so:

=over 4

=item up

=item down

=item left

=item right

Provide a style for the named direction

=item horizontal

=item vertical

These are the same as having provided 'top' & 'bottom' or 'left' and 'right'

=back

For each key, the value may be and empty string or the string '1' to default to the style 'light'.  Otherwise, the value is the style you want the line segment to be ('light', 'heavy', 'double', 'single').

=cut

sub find_box_unicode_name {
	my %directions = normalize_box_character_parameters(@_);
	return undef unless %directions;

    # Group together styles
    my %styles;
    while (my ($direction, $style) = each %directions) {
        push @{ $styles{$style} }, $direction;
    }
    my @styles = keys %styles;

    my $base_name = 'box drawings ';
    my @variations;

    if (int @styles == 1) {
        # Only one style; should be at most only two directions
        my @directions = @{ $styles{ $styles[0] } };
        if (int @directions > 2) {
            die "Unexpected scenario; one style but more than 2 directions";
        }
        foreach my $variation (\@directions, [ reverse @directions ]) {
            push @variations, uc $base_name . $styles[0] . ' ' . join (' and ', @$variation);
        }
    }
    elsif (int @styles == 2) {
        my @parts;
        foreach my $style (@styles) {
            my @directions = @{ $styles{$style} };
            if (int @directions > 1) {
                # right/left down/up/vertical, never down/up/vertical left/right
                # up/down horizontal, never horizontal up/down
                if (
                    ($directions[0] =~ m/^(down|up|vertical)$/ && $directions[1] =~ m{^(left|right)$})
                    || ($directions[0] =~ m/^(horizontal)$/ && $directions[1] =~ m{^(up|down)$})
                ) {
                    @directions = reverse @directions;
                }
            }
            push @parts, join ' ', @directions, $style;
        }
        foreach my $variation (\@parts, [ reverse @parts ]) {
            push @variations, uc $base_name . join(' and ', @$variation);
        }
    }

    if (! @variations) {
        return undef;
    }

    foreach my $variation (@variations) {
        next unless charnames::vianame($variation);
        return $variation;
    }

	if ($report_on_failure) {
		print "Unable to find any character like (" .
			join (', ', map { "$_: $directions{$_}" } sort keys %directions) .
			"), tried the following: " .
			join (', ', @variations) . "\n";
	}

    return undef;
}

=head2 normalize_box_character_parameters (%spec)

Takes the passed argument list to fetch_box_character() and normalizes the arguments in an idempotent fashion, returning the new spec list.

=cut

sub normalize_box_character_parameters {
	my %directions = @_;

	if (grep { ! defined $_ } values %directions) {
		print "No way to handle undefined values: " . 
			join (', ', map { "$_: ".(defined $directions{$_} ? $directions{$_} : 'undef') } sort keys %directions) . "\n";
		return ();
	}

    # Expand shorthand
    foreach my $direction (keys %directions) {
        $directions{$direction} = 'light' if $directions{$direction} . '' eq '1';
    }

    # Convert left & right to horizontal, up & down to vertical
    if ($directions{down} && $directions{up} && $directions{down} eq $directions{up}) {
        $directions{vertical} = delete $directions{down};
        delete $directions{up};
    }
    if ($directions{left} && $directions{right} && $directions{left} eq $directions{right}) {
        $directions{horizontal} = delete $directions{left};
        delete $directions{right};
    }

	# If any of the styles is a double, make sure all 'light' are 'single'
	if (grep { $directions{$_} eq 'double' } keys %directions) {
		foreach my $direction (grep { $directions{$_} eq 'light' } keys %directions) {
			$directions{$direction} = 'single';
		}
	}

	return %directions;
}

=head1 COPYRIGHT

Copyright (c) 2012 Eric Waters and Shutterstock Images (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
