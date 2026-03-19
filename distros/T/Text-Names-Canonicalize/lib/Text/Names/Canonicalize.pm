package Text::Names::Canonicalize;

use strict;
use warnings;
use Exporter qw(import);
use Unicode::Normalize qw(NFKC NFD NFC);
use feature 'unicode_strings';
use charnames qw(:full);

use Text::Names::Canonicalize::Rules;

our @EXPORT_OK = qw(
	canonicalize_name
	canonicalize_name_struct
);

# Default suffixes used when no rules are provided
my %DEFAULT_SUFFIX = map { $_ => 1 } qw(jr sr ii iii iv);

=head1 NAME

Text::Names::Canonicalize - Locale-aware personal name canonicalization with YAML rules, inheritance, and user overrides


=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Text::Names::Canonicalize qw(
      canonicalize_name
      canonicalize_name_struct
  );

  my $canon = canonicalize_name(
      "Jean d'Ormesson",
      locale => 'fr_FR',
  );

  # jean d'ormesson

  my $struct = canonicalize_name_struct(
      "Karl von der Heide",
      locale => 'de_DE',
  );

  # {
  #   original => "Karl von der Heide",
  #   locale   => "de_DE",
  #   parts    => {
  #       given   => ["karl"],
  #       surname => ["von der", "heide"],
  #   },
  #   canonical => "karl von der heide",
  # }

=head1 DESCRIPTION

Text::Names::Canonicalize provides a robust, data-driven engine for
canonicalizing personal names across multiple languages and cultural
conventions.  It is designed for data cleaning, indexing, matching,
and normalization tasks where consistent, locale-aware handling of
names is essential.

The module uses declarative YAML rules for each locale, supports
inheritance between locale files, detects circular includes, and
allows users to override or extend rules via configuration files.

A command-line tool C<text-names-canonicalize> is included for
interactive use.

=head1 FEATURES

=over 4

=item * Locale-aware name canonicalization

=item * YAML-based rule definitions

=item * Inheritance between locale files (C<include:>)

=item * Circular-include detection

=item * User override rules via C<$CONFIG_DIR> or C<~/.config>

=item * Multi-word particle handling (e.g. C<von der>, C<d'>, C<l'>)

=item * Tokenization and surname-strategy engine

=item * CLI tool with C<--explain> and C<--rules>

=back

=head1 FUNCTIONS

=head2 canonicalize_name( $name, %opts )

Returns a canonicalized string form of the name.

  my $canon = canonicalize_name("John Mc Donald", locale => 'en_GB');

Options:

=over 4

=item * C<locale>

Locale code (e.g. C<en_GB>, C<fr_FR>, C<de_DE>).
Defaults to C<en_GB>.

=back

=head2 canonicalize_name_struct( $name, %opts )

Returns a structured hashref describing the canonicalization process:

  {
    original  => "...",
    locale    => "...",
    parts     => {
        given   => [...],
        surname => [...],
    },
    canonical => "...",
  }

Useful for debugging, testing, and downstream processing.

=head1 LOCALE SYSTEM

Locale rules are stored as YAML files under:

  Text/Names/Canonicalize/Rules/*.yaml

Each file contains one or more rulesets (typically C<default>).

=head2 Inheritance

A ruleset may include one or more parent locales:

  default:
    include: en_GB
    particles:
      - de
      - du

Parents are merged in order, and child keys override parent keys.

=head2 Circular include detection

Circular include chains (direct or indirect) are detected and reported
with a clear error message.

=head1 USER OVERRIDES

Users may override or extend locale rules by placing YAML files in:

  $CONFIG_DIR/text-names-canonicalize/rules/*.yaml

or, if C<$CONFIG_DIR> is not set:

  ~/.config/text-names-canonicalize/rules/*.yaml

User rules override built-in rules at the per-ruleset level.

=head1 CLI TOOL

The distribution includes a command-line utility:

  text-names-canonicalize [options] "Full Name"

Options:

  --locale LOCALE     Select locale (default: en_GB)
  --explain           Dump structured canonicalization
  --rules             Show resolved ruleset for the locale

Examples:

  text-names-canonicalize "Jean d'Ormesson" --locale fr_FR
  text-names-canonicalize "Karl von der Heide" --locale de_DE --explain
  text-names-canonicalize --rules --locale fr_FR

=head1 YAML RULE FORMAT

Each ruleset contains:

=over 4

=item * C<particles> - list of surname particles

=item * C<suffixes> - generational/professional suffixes

=item * C<strip_titles> - titles to remove

=item * C<hyphen_policy> - currently C<preserve>

=item * C<surname_strategy> - e.g. C<last_token_with_particles>

=back

=head1 SUPPORTED LOCALES

=over 4

=item * C<base> - shared Western defaults

=item * C<en_GB> - British English

=item * C<en_US> - American English

=item * C<fr_FR> - French

=item * C<de_DE> - German

=back

Additional locales can be added easily by creating new YAML files.

=head1 EXTENDING

To add a new locale:

  1. Create a YAML file in Rules/
  2. Optionally inherit from base or another locale
  3. Add locale-specific particles, titles, or suffixes
  4. Write tests under t/

To override rules locally:

  mkdir -p ~/.config/text-names-canonicalize/rules
  cp my_rules.yaml ~/.config/text-names-canonicalize/rules/

=cut


# Returns a plain canonical string.
sub canonicalize_name {
	my ($name, %opts) = @_;
	return _normalize_string($name, %opts);
}

sub canonicalize_name_struct {
	my ($name, %opts) = @_;

	my $locale  = $opts{locale}  || 'en_GB';
	my $ruleset = $opts{ruleset} || 'default';

	my $rules = Text::Names::Canonicalize::Rules->get($locale, $ruleset);

	# 1. Strip titles (using raw input)
	if (my $titles = $rules->{strip_titles}) {
		my $re = join '|', map { quotemeta } @$titles;
		$name =~ s/\b(?:$re)\b\.?//ig if defined $name;
	}

	# 2. Normalize
	my $norm = _normalize_string($name, %opts);

	# 3. Tokenize
	my $tokens = _tokenize($norm);

	# 4. Classify
	my $classified = _classify_tokens($tokens, $rules);

	# 5. Extract parts
	my $parts = _extract_parts($classified, $rules);

	return {
		original  => (defined $name ? $name : ''),
		locale	=> $locale,
		ruleset   => $ruleset,
		canonical => join(' ', @$tokens),
		parts	 => $parts,
	};
}

sub _tokenize {
	my ($norm) = @_;

	# Normalize apostrophes
	$norm =~ s/[\N{LEFT SINGLE QUOTATION MARK}\N{RIGHT SINGLE QUOTATION MARK}]/'/g;

	# Normalize dash-like characters
	$norm =~ s/\p{Dash}/-/g;

	# Split French prefix particles BEFORE splitting on spaces.
	# d'Ormesson → d' Ormesson
	# l'Enfant   → l' Enfant
	$norm =~ s/\b(d'|l')(\p{Letter}+)/$1 $2/gi;

	my @t = split / /, $norm;

	# Join multi-word particles (e.g., "von der")
	@t = _join_multiword_particles(@t);

	for (@t) {
		s/^\pP+//;				 # leading punctuation
		s/[\pP&&[^']]+$//;		 # trailing punctuation except apostrophe
		s/\.$//;				   # trailing period (initials)
	}

	return [ grep { length } @t ];
}

sub _classify_tokens {
	my ($tokens, $rules) = @_;

	my %suffix = %DEFAULT_SUFFIX;

	# If rules are provided, override suffix list from ruleset
	if ($rules && $rules->{suffixes}) {
		%suffix = map { $_ => 1 } @{ $rules->{suffixes} };
	}

	my @types;

	for my $t (@$tokens) {
		if ($t =~ /^[a-z]$/) {
			push @types, "initial";
		}
		elsif ($suffix{$t}) {
			push @types, "suffix";
		}
		else {
			push @types, "word";
		}
	}

	return {
		tokens => $tokens,
		types => \@types,
	};
}

sub _extract_parts {
	my ($classified, $rules) = @_;

	my @tokens = @{ $classified->{tokens} };
	my @types = @{ $classified->{types} };

	my %particle = map { $_ => 1 } @{ $rules->{particles} || [] };

	my (@given, @middle, @surname, @suffix);

	# 1. Peel off suffixes
	while (@types && $types[-1] eq 'suffix') {
		unshift @suffix, pop @tokens;
		pop @types;
	}

	# If nothing left, return empty structure
	return {
		given   => [],
		middle  => [],
		surname => [],
		suffix  => \@suffix,
	} unless @tokens;

	# 2. Locale-aware surname extraction
	if ($rules->{surname_strategy} && $rules->{surname_strategy} eq 'last_token_with_particles') {

		# Always take the last token as surname root
		my $root = pop @tokens;
		pop @types;
		unshift @surname, $root;

		# Pull in particles from the end backwards
		while (@tokens && $particle{$tokens[-1]}) {
			unshift @surname, pop @tokens;
			pop @types;
		}

	} else {
		# Fallback: simple last token
		my $root = pop @tokens;
		pop @types;
		unshift @surname, $root;
	}

	# 3. Given = first token (if any)
	if (@tokens) {
		push @given, shift @tokens;
		shift @types;
	}

	# 4. Middle = everything else
	@middle = @tokens;

	return {
		given   => \@given,
		middle  => \@middle,
		surname => \@surname,
		suffix  => \@suffix,
	};
}

sub _normalize_string {
	my ($name, %opts) = @_;

	$name = '' unless defined $name;

	my $norm = NFKC($name);

	# whitespace
	$norm =~ s/\s+/ /g;
	$norm =~ s/^\s+//;
	$norm =~ s/\s+$//;

	# punctuation (basic)
	$norm =~ s/[.,]+$//;   # strip trailing comma/period
	$norm =~ s/^[.,]+//;   # strip leading comma/period

	# lowercase
	$norm = lc $norm;

	# diacritics
	if ($opts{strip_diacritics}) {
		my $d = NFD($norm);
		$d =~ s/\pM//g;
		$norm = NFC($d);
	}

	return $norm;
}

sub _join_multiword_particles {
	my @t = @_;
	my @out;

	while (@t) {
		my $w = shift @t;

		# Try 2-word particles
		if (@t && "$w $t[0]" =~ /^(von der|von dem)$/) {
			$w = "$w " . shift @t;
		}

		push @out, $w;
	}

	return @out;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=head1 REPOSITORY

L<https://github.com/nigelhorne/Text-Names-Canonicalize>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-text-names-canonicalize at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Canonicalize>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Text::Names::Canonicalize

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Text-Names-Canonicalize>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Canonicalize>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Text-Names-Canonicalize>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Text::Names::Canonicalize>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
