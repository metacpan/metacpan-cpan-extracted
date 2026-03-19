# NAME

Text::Names::Canonicalize - Locale-aware personal name canonicalization with YAML rules, inheritance, and user overrides

# SYNOPSIS

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

# DESCRIPTION

Text::Names::Canonicalize provides a robust, data-driven engine for
canonicalizing personal names across multiple languages and cultural
conventions.  It is designed for data cleaning, indexing, matching,
and normalization tasks where consistent, locale-aware handling of
names is essential.

The module uses declarative YAML rules for each locale, supports
inheritance between locale files, detects circular includes, and
allows users to override or extend rules via configuration files.

A command-line tool `text-names-canonicalize` is included for
interactive use.

# FEATURES

- Locale-aware name canonicalization
- YAML-based rule definitions
- Inheritance between locale files (`include:`)
- Circular-include detection
- User override rules via `$CONFIG_DIR` or `~/.config`
- Multi-word particle handling (e.g. `von der`, `d'`, `l'`)
- Tokenization and surname-strategy engine
- CLI tool with `--explain` and `--rules`

# FUNCTIONS

## canonicalize\_name( $name, %opts )

Returns a canonicalized string form of the name.

    my $canon = canonicalize_name("John Mc Donald", locale => 'en_GB');

Options:

- `locale`

    Locale code (e.g. `en_GB`, `fr_FR`, `de_DE`).
    Defaults to `en_GB`.

## canonicalize\_name\_struct( $name, %opts )

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

# LOCALE SYSTEM

Locale rules are stored as YAML files under:

    Text/Names/Canonicalize/Rules/*.yaml

Each file contains one or more rulesets (typically `default`).

## Inheritance

A ruleset may include one or more parent locales:

    default:
      include: en_GB
      particles:
        - de
        - du

Parents are merged in order, and child keys override parent keys.

## Circular include detection

Circular include chains (direct or indirect) are detected and reported
with a clear error message.

# USER OVERRIDES

Users may override or extend locale rules by placing YAML files in:

    $CONFIG_DIR/text-names-canonicalize/rules/*.yaml

or, if `$CONFIG_DIR` is not set:

    ~/.config/text-names-canonicalize/rules/*.yaml

User rules override built-in rules at the per-ruleset level.

# CLI TOOL

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

# YAML RULE FORMAT

Each ruleset contains:

- `particles` - list of surname particles
- `suffixes` - generational/professional suffixes
- `strip_titles` - titles to remove
- `hyphen_policy` - currently `preserve`
- `surname_strategy` - e.g. `last_token_with_particles`

# SUPPORTED LOCALES

- `base` - shared Western defaults
- `en_GB` - British English
- `en_US` - American English
- `fr_FR` - French
- `de_DE` - German

Additional locales can be added easily by creating new YAML files.

# EXTENDING

To add a new locale:

    1. Create a YAML file in Rules/
    2. Optionally inherit from base or another locale
    3. Add locale-specific particles, titles, or suffixes
    4. Write tests under t/

To override rules locally:

    mkdir -p ~/.config/text-names-canonicalize/rules
    cp my_rules.yaml ~/.config/text-names-canonicalize/rules/

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

# REPOSITORY

[https://github.com/nigelhorne/Text-Names-Canonicalize](https://github.com/nigelhorne/Text-Names-Canonicalize)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-text-names-canonicalize at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Canonicalize](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Canonicalize).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Text::Names::Canonicalize

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Text-Names-Canonicalize](https://metacpan.org/dist/Text-Names-Canonicalize)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Canonicalize](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Canonicalize)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Text-Names-Canonicalize](http://matrix.cpantesters.org/?dist=Text-Names-Canonicalize)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Text::Names::Canonicalize](http://deps.cpantesters.org/?module=Text::Names::Canonicalize)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
