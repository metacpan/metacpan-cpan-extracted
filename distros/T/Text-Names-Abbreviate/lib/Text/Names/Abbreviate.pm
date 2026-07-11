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
use Unicode::Normalize ();

our @EXPORT_OK = qw(abbreviate);

=head1 NAME

Text::Names::Abbreviate - Create abbreviated name formats from full names

=head2 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

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

# Common surname particles across Dutch, German, French, Italian, Spanish,
# Portuguese, Arabic, and Scandinavian naming traditions.  Matching is
# case-sensitive: only lowercase tokens are eligible.
Readonly my @DEFAULT_PARTICLES => qw(
    van de di da von der den des du
    la le las los el al
    te ten ter
    af av
    bin bint ibn
    y do dos das del
    zu zum zur
);

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
	particles => {
		type     => ['boolean', 'arrayref'],
		optional => 1,
	},
);

=head1 SYNOPSIS

  use Text::Names::Abbreviate qw(abbreviate);

  say abbreviate('John Quincy Adams');                            # J. Q. Adams
  say abbreviate('Adams, John Quincy');                          # J. Q. Adams
  say abbreviate('George R R Martin', { format => 'initials' }); # G.R.R.M.
  say abbreviate('Ludwig van Beethoven');                         # L. van Beethoven
  say abbreviate("R\x{e9}mi Dupr\x{e9}");                       # R. Dupr\x{e9}

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
C<format>, C<style>, C<separator>, and C<particles> options.  Input is
NFC-normalised before processing, so strings differing only in Unicode
normalisation form produce identical output.  Surname particles (C<van>,
C<de>, C<von>, etc.) are absorbed into the last-name component by default.

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

=item particles (optional, default enabled)

Controls detection of surname particles (C<van>, C<de>, C<von>, etc.) that
prefix the last name.  Tokens immediately before the last name that appear in
the particle list are absorbed into the last-name component.  Matching is
case-sensitive: only lowercase tokens are eligible.

=over 4

=item omitted or C<1> - use the built-in particle list

=item C<0> - disable particle detection entirely

=item arrayref of strings - use that list instead of the built-in one

=back

  abbreviate('Ludwig van Beethoven');                           # L. van Beethoven
  abbreviate('Ludwig van Beethoven', { particles => 0 });      # L. v. Beethoven
  abbreviate('Felipe de la Cruz', { particles => ['de','la'] }); # F. de la Cruz

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
    particles => { type => ['boolean', 'arrayref'], optional => 1 },
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
  particles: must be one of boolean,       Passed a string or hashref; pass 0/1 or an
    arrayref                               arrayref of particle strings instead.

=head3 PSEUDOCODE

  FUNCTION abbreviate(name, options):
     Validate parameters via %PARAM_SCHEMA       (croak on violation)
     Assign defaults: format=default, style=first_last, sep=".", particles=built-in list
     _normalize_name(name):
         - NFC-normalize to precomposed Unicode form
         - collapse consecutive commas
         - detect and reorder "Last, First" form
         - track $had_leading_comma (input had no last-name component)
         - collapse internal whitespace; trim
     Return '' if normalized name is empty
     _extract_parts(name, had_leading_comma, format, style, particles):
         - tokenize on whitespace
         - pop last token as $last_name (unless leading-comma form)
         - if particles enabled: while last remaining token is a particle,
           pop it and prepend to $last_name
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

	$raw = Unicode::Normalize::NFC($raw);
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
#               from a normalized name string, honouring format, style, and particles.
# Entry Criteria: $name is output of _normalize_name (trimmed, single-spaced).
#                 $had_leading_comma is the boolean from _normalize_name.
#                 $format and $style are validated constants (FMT_*/STY_*).
#                 $particles is an arrayref of particle strings, or undef to disable.
# Exit Status:  Returns ($initials_ref, $last_name).  $initials_ref is an
#               arrayref of single-character strings with empty entries removed.
#               $last_name is '' when consumed by style/format reordering.
# Side Effects: None.
sub _extract_parts {
	my ($name, $had_leading_comma, $format, $style, $particles) = @_;

	my @parts = split /\s+/, $name;
	return ([], q{}) unless @parts;

	my ($last_name, @initials);

	if ($had_leading_comma) {
		$last_name = q{};
		@initials  = map { substr $_, 0, 1 } @parts;
	} else {
		$last_name = pop @parts;

		# Absorb surname particles immediately preceding the last name.
		if ($particles && @parts) {
			my %is_particle = map { $_ => 1 } grep { defined } @{$particles};
			while (@parts && $is_particle{ $parts[-1] }) {
				$last_name = (pop @parts) . q{ } . $last_name;
			}
		}

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

	my $raw_particles = $params->{particles};
	my $particles_ref =
		!defined $raw_particles          ? \@DEFAULT_PARTICLES
		: ref $raw_particles eq 'ARRAY'  ? $raw_particles
		: $raw_particles                 ? \@DEFAULT_PARTICLES
		:                                  undef;

	my ($name, $had_leading_comma) = _normalize_name($params->{name});
	return q{} unless length $name;

	my ($initials, $last_name) = _extract_parts($name, $had_leading_comma, $format, $style, $particles_ref);

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

=item *

Particle detection is case-sensitive.  A token is only absorbed into the
last-name component when it exactly matches a particle string (all lowercase).
Capitalised tokens such as C<Van> or C<De> are treated as ordinary name
components.

=item *

For C<compact> and C<initials> formats with C<last_first> style, only the
first character of the full particle-inclusive last name is used as the last
initial (e.g. C<van Beethoven> contributes initial C<v>).

=item *

Unicode input is NFC-normalised before processing.  Strings that differ only
in normalisation form (e.g. precomposed C<\x{e9}> vs. combining C<e\x{301}>)
produce identical output.

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
    let n0 = NFC(n)             -- Unicode NFC normalisation
    let n1 = gsub(n0, ",+", ",")
    if "," not-in n1 then (collapse(n1), false)
    else
      let (L, R) = split(n1, ",", 2) each trimmed
      case
        L = epsilon ^ R != epsilon  ->  (collapse(R), true)
        L != epsilon ^ R != epsilon ->  (collapse(R ++ " " ++ L), false)
        L != epsilon ^ R = epsilon  ->  (collapse(L), false)
        L = epsilon ^ R = epsilon   ->  (epsilon, false)
      end

  Particles = seq Sigma* | undef    -- arrayref of particle strings, or disabled

  collect_particles : seq Sigma* x Particles -> Sigma* x seq Sigma*
  collect_particles(ps, P) =
    if P = undef then (epsilon, ps)
    else
      let particle_set = { p | p <- P }
      iterate: while ps != [] ^ last(ps) in particle_set:
        prepend last(ps) to accumulator; remove from ps
      (join(" ", accumulator), ps)

  extract : Sigma* x Bool x Format x Style x Particles -> (seq Sigma) x Sigma*
  extract(n, leading, fmt, sty, P) =
    let ps = tokenize(n)    -- split on whitespace
    if ps = [] then ([], epsilon)
    else if leading then
      ([ first(p) | p <- ps ], epsilon)
    else
      let base  = ps[#ps]
          rest  = ps[1..#ps-1]
      let (prefix, rest') = collect_particles(rest, P)
      let last  = if prefix != epsilon then prefix ++ " " ++ base else base
          inits = [ first(p) | p <- rest' ]
      if sty = last_first ^ fmt != default ^ fmt != shortlast ^ last != epsilon
        then ([first(last)] ++ inits, epsilon)
        else (inits, last)

  abbreviate : Sigma+ x Format x Style x Sigma* x Particles -> Sigma*
  abbreviate = format_result . extract . normalize

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut
