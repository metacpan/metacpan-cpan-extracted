package Text::Names::Abbreviate;

use strict;
use warnings;
use autodie qw(:all);
use utf8;

use Carp;
use Exporter 'import';
use Params::Get 0.13;
use Params::Validate::Strict 0.13;
use Readonly;

our @EXPORT_OK = qw(abbreviate);

=head1 NAME

Text::Names::Abbreviate - Create abbreviated name formats from full names

=head2 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

# ---------------------------------------------------------------------------
# Named constants -- eliminate magic strings throughout the logic
# ---------------------------------------------------------------------------
Readonly my $FMT_DEFAULT   => 'default';
Readonly my $FMT_INITIALS  => 'initials';
Readonly my $FMT_COMPACT   => 'compact';
Readonly my $FMT_SHORTLAST => 'shortlast';
Readonly my $STY_FIRST     => 'first_last';
Readonly my $STY_LAST      => 'last_first';
Readonly my $DEFAULT_SEP   => '.';

# Single source of truth for parameter validation; also reflected in POD below.
Readonly my %PARAM_SCHEMA => (
	name => {
		type     => 'string',
		min      => 1,
		optional => 0,
	},
	format => {
		type     => 'string',
		memberof => [ $FMT_DEFAULT, $FMT_INITIALS, $FMT_COMPACT, $FMT_SHORTLAST ],
		optional => 1,
	},
	style => {
		type     => 'string',
		memberof => [ $STY_FIRST, $STY_LAST ],
		optional => 1,
	},
	separator => {
		type     => 'string',
		optional => 1,
	},
);

=head1 SYNOPSIS

  use Text::Names::Abbreviate qw(abbreviate);

  say abbreviate('John Quincy Adams');                            # J. Q. Adams
  say abbreviate('Adams, John Quincy');                          # J. Q. Adams
  say abbreviate('George R R Martin', { format => 'initials' }); # G.R.R.M.

=head1 DESCRIPTION

This module provides simple abbreviation logic for full personal names with
multiple formatting options and styles.  Input is expected to be a personal
name consisting of one or more whitespace-separated components interpreted as:

  First [Middle ...] Last

Names consisting of a single component are returned unchanged.

=head1 SUBROUTINES/METHODS

=head2 abbreviate

Produce an abbreviated form of a personal name.

=head3 Purpose

Accept a full name in either C<First Middle Last> or C<Last, First Middle>
form and return a formatted abbreviated string according to the requested
C<format>, C<style>, and C<separator>.

=head3 Args

=over 4

=item name (required)

Non-empty string.  Accepted in two forms:

=over 4

=item C<First [Middle ...] Last>

=item C<Last, First [Middle ...]>

=back

A leading comma (C<", John">) signals that no last name is present; only
initials are produced.

=item format (optional, default C<default>)

One of C<default>, C<initials>, C<compact>, C<shortlast>.

=over 4

=item C<default>   -- C<J. Q. Adams>

=item C<initials>  -- C<J.Q.A.>

=item C<compact>   -- C<JQA>

=item C<shortlast> -- initials then full last name; honours C<last_first> style
(e.g. C<Adams, J. Q.>).

=back

=item style (optional, default C<first_last>)

One of C<first_last>, C<last_first>.  All formats honour this option.

=item separator (optional, default C<.>)

String appended after each initial.  Empty string removes all punctuation.

=back

=head3 Returns

A plain string.  Returns C<''> for inputs that normalise to nothing (e.g. a
bare comma).

=head3 Side Effects

None.  The function is purely functional with no persistent state.

=head3 Usage

  # Positional
  my $abbrev = abbreviate('John Quincy Adams');

  # Options hashref
  my $abbrev = abbreviate('John Quincy Adams', {
      format    => 'initials',
      style     => 'last_first',
      separator => '-',
  });

=head3 API SPECIFICATION

  INPUT
  {
    name      => { type => 'string', min => 1, optional => 0 },
    format    => { type => 'string',
                   memberof => [qw(default initials compact shortlast)],
                   optional => 1 },
    style     => { type => 'string',
                   memberof => [qw(first_last last_first)],
                   optional => 1 },
    separator => { type => 'string', optional => 1 },
  }

  OUTPUT
  { type => 'string' }    # croaks on argument error

=head3 MESSAGES

  Error                                    Meaning / Resolution
  ---------------------------------------  -----------------------------------------------
  name parameter missing or undefined      Called without a name argument; supply one.
  name must be a non-empty string          Passed '' or undef; supply a non-empty string.
  format must be one of: ...               Invalid format constant; see API SPECIFICATION.
  style must be one of: ...               Invalid style constant; see API SPECIFICATION.

=head3 PSEUDOCODE

  FUNCTION abbreviate(name, options):
     Validate parameters via %PARAM_SCHEMA       (croak on violation)
     Assign defaults: format=default, style=first_last, sep="."
     _normalize_name(name):
         - collapse consecutive commas
         - detect and reorder "Last, First" form
         - track $had_leading_comma (input had no last-name component)
         - collapse internal whitespace; trim
     Return '' if normalized name is empty
     _extract_parts(name, had_leading_comma, format, style):
         - tokenize on whitespace
         - pop last token as $last_name (unless leading-comma form)
         - build @initials from remaining tokens (first char each)
         - if style=last_first and format!=default: unshift last initial, clear $last_name
         - filter empty initials
     Format result:
         compact   -> join('', @initials, first($last_name))
         initials  -> join($sep, @all_letters) . $sep
         shortlast -> join(' ', map {"$_$sep"} @initials) . " $last_name"
         default   -> joined initials; prepend/append $last_name per $style

=cut

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:      Resolve "Last, First" and leading-comma forms into a canonical
#               "First ... Last" string, collapsing all internal whitespace.
# Entry Criteria: $raw is a defined, non-empty string (validated by the caller).
# Exit Status:  Returns ($normalized, $had_leading_comma).  $normalized is
#               whitespace-collapsed and trimmed.  $had_leading_comma is 1 when
#               the original input began with a comma (no last-name component).
# Side Effects: None.
sub _normalize_name {
	my ($raw) = @_;

	$raw =~ s/,+/,/g;    # collapse any run of commas to one before splitting

	my $had_leading_comma = 0;

	if ($raw =~ /,/) {
		my ($last, $rest) = map { s/^\s+|\s+$//gr } split /\s*,\s*/, $raw, 2;
		$rest //= q{};
		$last //= q{};

		$had_leading_comma = 1 if !length($last) && length($rest);

		if (length($last) && length($rest)) {
			$raw = "$rest $last";
		} elsif (length $rest) {
			$raw = $rest;
		} elsif (length $last) {
			$raw = $last;
		} else {
			return (q{}, 0);
		}
	}

	$raw =~ s/^\s+|\s+$//g;
	$raw =~ s/\s+/ /g;

	return ($raw, $had_leading_comma);
}

# Purpose:      Derive the ordered list of initials and the preserved last name
#               from a normalized name string, honouring format and style.
# Entry Criteria: $name is output of _normalize_name (trimmed, single-spaced).
#                 $had_leading_comma is the boolean from _normalize_name.
#                 $format and $style are validated constants (FMT_*/STY_*).
# Exit Status:  Returns ($initials_ref, $last_name).  $initials_ref is an
#               arrayref of single-character strings with empty entries removed.
#               $last_name is '' when consumed by style/format reordering.
# Side Effects: None.
sub _extract_parts {
	my ($name, $had_leading_comma, $format, $style) = @_;

	my @parts = split /\s+/, $name;
	return ([], q{}) unless @parts;

	my ($last_name, @initials);

	if ($had_leading_comma) {
		$last_name = q{};
		@initials  = map { substr $_, 0, 1 } @parts;
	} else {
		$last_name = pop @parts;
		@initials  = map { substr $_, 0, 1 } @parts;

		# last_first on non-default formats (except shortlast, which keeps the full last name):
		# move the last-name initial to the front and discard the full last name
		if ($style eq $STY_LAST && $format ne $FMT_DEFAULT && $format ne $FMT_SHORTLAST && length $last_name) {
			unshift @initials, substr $last_name, 0, 1;
			$last_name = q{};
		}
	}

	@initials = grep { length $_ } @initials;

	return (\@initials, $last_name);
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

sub abbreviate {
	my $params = Params::Validate::Strict::validate_strict({
		args   => Params::Get::get_params('name', @_),
		schema => \%PARAM_SCHEMA,
	});

	Carp::croak(__PACKAGE__ . '::abbreviate: name parameter is required and must be defined')
		unless defined $params->{name};

	my $format = $params->{format}    // $FMT_DEFAULT;
	my $style  = $params->{style}     // $STY_FIRST;
	my $sep    = $params->{separator} // $DEFAULT_SEP;

	my ($name, $had_leading_comma) = _normalize_name($params->{name});
	return q{} unless length $name;

	my ($initials, $last_name) = _extract_parts($name, $had_leading_comma, $format, $style);

	if ($format eq $FMT_COMPACT) {
		return join q{}, @{$initials},
			(length $last_name ? (substr $last_name, 0, 1) : ());
	}

	if ($format eq $FMT_INITIALS) {
		my @letters = @{$initials};
		push @letters, substr($last_name, 0, 1) if length $last_name;
		return join($sep, @letters) . $sep;
	}

	if ($format eq $FMT_SHORTLAST) {
		my $joined = @{$initials} ? join(' ', map { $_ . $sep } @{$initials}) : q{};
		if ($style eq $STY_LAST && length $last_name) {
			return length($joined) ? "$last_name, $joined" : $last_name;
		}
		return length($joined)
			? (length($last_name) ? "$joined $last_name" : $joined)
			: $last_name;
	}

	# default format
	return $last_name unless @{$initials};
	my $joined = join ' ', map { $_ . $sep } @{$initials};
	return ($style eq $STY_LAST && length $last_name)
		? "$last_name, $joined"
		: (length $last_name ? "$joined $last_name" : $joined);
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item *

Honorifics (C<Dr.>, C<Prof.>) and suffixes (C<Jr.>, C<III>) are not
detected or stripped; they are treated as name components.

=item *

Initials are taken verbatim from the first character of each token.
Non-alphabetic leading characters (digits, punctuation) are included as-is.

=item *

Multiple consecutive commas collapse to a single comma before parsing.
Names with two legitimate comma-separated clauses are not supported.

=item *

C<compact> and C<initials> formats are lossy: passing their output back into
C<abbreviate> does not reproduce the original result.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report bugs to C<bug-text-names-abbreviate at rt.cpan.org> or via
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Abbreviate>.

=head1 REPOSITORY

L<https://github.com/nigelhorne/Text-Names-Abbreviate>

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Text-Names-Abbreviate/coverage/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

  perldoc Text::Names::Abbreviate

=over 4

=item * MetaCPAN: L<https://metacpan.org/dist/Text-Names-Abbreviate>

=item * RT tracker: L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Abbreviate>

=item * CPAN Testers: L<http://matrix.cpantesters.org/?dist=Text-Names-Abbreviate>

=back

=head1 FORMAL SPECIFICATION

=head2 abbreviate

  Let Sigma* denote the set of all Unicode strings.
  Let epsilon denote the empty string.

  Sigma+ = Sigma* \ {epsilon}
  Format = {default, initials, compact, shortlast}
  Style  = {first_last, last_first}

  collapse(s) -- replace runs of whitespace with a single space, then trim

  normalize : Sigma+ -> Sigma* x Bool
  normalize(n) =
    let n1 = gsub(n, ",+", ",")
    if "," not-in n1 then (collapse(n1), false)
    else
      let (L, R) = split(n1, ",", 2) each trimmed
      case
        L = epsilon ^ R != epsilon  ->  (collapse(R), true)
        L != epsilon ^ R != epsilon ->  (collapse(R ++ " " ++ L), false)
        L != epsilon ^ R = epsilon  ->  (collapse(L), false)
        L = epsilon ^ R = epsilon   ->  (epsilon, false)
      end

  extract : Sigma* x Bool x Format x Style -> (seq Sigma) x Sigma*
  extract(n, leading, fmt, sty) =
    let ps = tokenize(n)    -- split on whitespace
    if ps = [] then ([], epsilon)
    else if leading then
      ([ first(p) | p <- ps ], epsilon)
    else
      let last  = ps[#ps]
          inits = [ first(p) | p <- ps[1..#ps-1] ]
      if sty = last_first ^ fmt != default ^ last != epsilon
        then ([first(last)] ++ inits, epsilon)
        else (inits, last)

  abbreviate : Sigma+ x Format x Style x Sigma* -> Sigma*
  abbreviate = format_result . extract . normalize

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut
