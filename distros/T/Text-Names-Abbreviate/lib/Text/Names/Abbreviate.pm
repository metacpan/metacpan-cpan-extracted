package Text::Names::Abbreviate;

use strict;
use warnings;

use Carp;
use Exporter 'import';
use Params::Get 0.13;
use Params::Validate::Strict 0.13;

our @EXPORT_OK = qw(abbreviate);

=head1 NAME

Text::Names::Abbreviate - Create abbreviated name formats from full names

=head2 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use Text::Names::Abbreviate qw(abbreviate);

  say abbreviate("John Quincy Adams");		 # "J. Q. Adams"
  say abbreviate("Adams, John Quincy");		# "J. Q. Adams"
  say abbreviate("George R R Martin", { format => 'initials' }); # "G.R.R.M."

=head1 DESCRIPTION

This module provides simple abbreviation logic for full personal names,
with multiple formatting options and styles.

The input is expected to be a personal name consisting of one or more
whitespace-separated components. These are typically interpreted as:

  First [Middle ...] Last

Names consisting of a single component are treated as a single name,
and no abbreviation of given names is possible.

=head1 SUBROUTINES/METHODS

=head2 abbreviate

Make the abbreviation.
It takes the following optional arguments:

=over

=item format

One of: default, initials, compact, shortlast

C<Shortlast> produces initials followed by the full last name, ignoring style reordering.
This is similar to the default format but does not support C<last_first> output.

=item style

One of: first_last, last_first

=item separator

String used between initials (default: ".").

Note that spacing between initials is handled separately depending on
the selected format.

=back

=head3 Name Formats

The function recognizes names in both of the following forms:

=over 4

=item *

C<First Middle Last>

=item *

C<Last, First Middle>

=back

In the latter case, the name will be normalized internally before
abbreviation.

If the input begins with a comma (e.g., C<", John">), it is interpreted
as having no last name, and only initials will be produced.

=head3 Errors

The function will throw an exception (via C<croak>) if:

=over 4

=item *

The C<name> parameter is missing or undefined

=item *

The C<name> parameter is an empty string

=item *

An invalid value is provided for C<format> or C<style>

=back

=head1 EXAMPLES

  abbreviate("Madonna")
  # "Madonna"

  abbreviate("Adams, John Quincy")
  # "J. Q. Adams"

  abbreviate("John Quincy Adams", { style => 'last_first' })
  # "Adams, J. Q."

  abbreviate("John Quincy Adams", { format => 'compact' })
  # "JQA"

=head3 Notes

Abbreviation formats such as C<compact> and C<initials> are lossy
transformations. They discard structural information about the original
name.

As a result, passing the output of C<abbreviate()> back into the function
may not yield equivalent results:

  abbreviate("George R R Martin", { format => 'compact' })   # "GRRM"
  abbreviate("GRRM", { format => 'initials' })			# "G."

In such cases, the input is treated as a single name.

Initials are derived by taking the first character of each name component verbatim.
No filtering is applied,
so non-alphabetic characters (such as punctuation or digits) will be included as-is.

=head3	API SPECIFICATION

=head4	INPUT

  {
    'name' => { 'type' => 'string', 'min' => 1, 'optional' => 0 },
    'format' => {
      'type' => 'string',
      'memberof' => [ 'default', 'initials', 'compact', 'shortlast' ],
      'optional' => 1
    }, 'style' => {
      'type' => 'string',
      'memberof' => [ 'first_last', 'last_first' ],
      'optional' => 1
    }, 'separator' => {
      'type' => 'string',
      'optional' => 1
    }
  }

=head4	OUTPUT

Argument error: croak

  {
    'type' => 'string',
  }

=cut

sub abbreviate
{
	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params('name', @_),
		schema => {
			'name' => { 'type' => 'string', 'min' => 1, 'optional' => 0 },
			'format' => {
				'type' => 'string',
				'memberof' => [ 'default', 'initials', 'compact', 'shortlast' ],
				'optional' => 1
			}, 'style' => {
				'type' => 'string',
				'memberof' => [ 'first_last', 'last_first' ],
				'optional' => 1
			}, 'separator' => {
				'type' => 'string',
				'optional' => 1
			}
		}
	});

	my $name = $params->{'name'};
	if(!defined($name)) {
		Carp::croak(__PACKAGE__, '::abbreviate: Usage($name, { options })')
	}

	my $format = $params->{format} // 'default';	# default, initials, compact, shortlast
	my $style = $params->{style} // 'first_last'; # first_last or last_first
	my $sep	= defined $params->{separator} ? $params->{separator} : '.';

	# Normalize commas (e.g., "Adams, John Q." -> ("Adams", "John Q."))
	my $had_leading_comma = 0;
	$name =~ s/,,/,/g;
	if ($name =~ /,/) {
		my ($last, $rest) = map { s/^\s+|\s+$//gr } split(/\s*,\s*/, $name, 2);
		$rest ||= '';
		$last ||= '';

		# Track if we had a leading comma (empty last name part)
		$had_leading_comma = 1 if !length($last) && length($rest);

		if (length($last) && length($rest)) {
			$name = "$rest $last";
		} elsif (length($rest)) {
			$name = $rest;
		} elsif (length($last)) {
			$name = $last;
		} else {
			return '';
		}

		$name =~ s/^\s+|\s+$//g;
		$name =~ s/\s+/ /g;
	}

	my @parts = split /\s+/, $name;
	return '' unless @parts;

	my $last_name;
	my @initials;

	# If we had a leading comma (", John"), treat all parts as first names
	if ($had_leading_comma) {
		$last_name = '';
		@initials = map { substr($_, 0, 1) } @parts;
	} else {
		$last_name = pop @parts;
		@initials = map { substr($_, 0, 1) } @parts;

		# For last_first style in non-default formats, put last name initial first
		if ($style eq 'last_first' && $format ne 'default' && length($last_name)) {
			unshift @initials, substr($last_name, 0, 1);
			$last_name = '';
		}
	}

	if(@initials) {
		@initials = grep { $_ } @initials;	# Remove empty elements
	}

	if ($format eq 'compact') {
		return join('', @initials, length($last_name) ? substr($last_name, 0, 1) : ());
	} elsif($format eq 'initials') {
		my @letters = @initials;
		push @letters, substr($last_name, 0, 1) if length $last_name;

		return join($sep, @letters) . $sep;
	} elsif($format eq 'shortlast') {
		if(@initials) {
			return join(' ', map { "${_}$sep" } @initials) . " $last_name";
		}
		return $last_name;
	} else { # default: "J. Q. Adams"
		if(@initials) {
			my $joined = join(' ', map { "${_}$sep" } @initials);
			if (length($joined)) {
				if ($style eq 'last_first' && length($last_name)) {
					return "$last_name, $joined";
				}
				return $last_name ? "$joined $last_name" : $joined;
			}
		}
		return $last_name;
	}
}

1;

__END__

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 REPOSITORY

L<https://github.com/nigelhorne/Text-Names-Abbreviate>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-text-names-abbreviate at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Abbreviate>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Text::Names::Abbreviate

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Text-Names-Abbreviate>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Abbreviate>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Text-Names-Abbreviate>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Text::Names::Abbreviate>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut
