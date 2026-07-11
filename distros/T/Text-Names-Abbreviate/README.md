# NAME

Text::Names::Abbreviate - Create abbreviated name formats from full names

## VERSION

Version 0.04

# SYNOPSIS

    use Text::Names::Abbreviate qw(abbreviate);

    say abbreviate('John Quincy Adams');                            # J. Q. Adams
    say abbreviate('Adams, John Quincy');                          # J. Q. Adams
    say abbreviate('George R R Martin', { format => 'initials' }); # G.R.R.M.
    say abbreviate('Ludwig van Beethoven');                         # L. van Beethoven
    say abbreviate("R\x{e9}mi Dupr\x{e9}");                       # R. Dupr\x{e9}

# DESCRIPTION

This module provides simple abbreviation logic for full personal names with
multiple formatting options and styles.  Input is expected to be a personal
name consisting of one or more whitespace-separated components interpreted as:

    First [Middle ...] Last

Names consisting of a single component are returned unchanged.

# SUBROUTINES/METHODS

## abbreviate

Produce an abbreviated form of a personal name.

### Purpose

Accept a full name in either `First Middle Last` or `Last, First Middle`
form and return a formatted abbreviated string according to the requested
`format`, `style`, `separator`, and `particles` options.  Input is
NFC-normalised before processing, so strings differing only in Unicode
normalisation form produce identical output.  Surname particles (`van`,
`de`, `von`, etc.) are absorbed into the last-name component by default.

### Args

- name (required)

    Non-empty string.  Accepted in two forms:

    - `First [Middle ...] Last`
    - `Last, First [Middle ...]`

    A leading comma (`", John"`) signals that no last name is present; only
    initials are produced.

- format (optional, default `default`)

    One of `default`, `initials`, `compact`, `shortlast`.

    - `default`   -- `J. Q. Adams`
    - `initials`  -- `J.Q.A.`
    - `compact`   -- `JQA`
    - `shortlast` -- initials then full last name; honours `last_first` style
    (e.g. `Adams, J. Q.`).

- style (optional, default `first_last`)

    One of `first_last`, `last_first`.  All formats honour this option.

- separator (optional, default `.`)

    String appended after each initial.  Empty string removes all punctuation.

- particles (optional, default enabled)

    Controls detection of surname particles (`van`, `de`, `von`, etc.) that
    prefix the last name.  Tokens immediately before the last name that appear in
    the particle list are absorbed into the last-name component.  Matching is
    case-sensitive: only lowercase tokens are eligible.

    - omitted or `1` - use the built-in particle list
    - `0` - disable particle detection entirely
    - arrayref of strings - use that list instead of the built-in one

        abbreviate('Ludwig van Beethoven');                           # L. van Beethoven
        abbreviate('Ludwig van Beethoven', { particles => 0 });      # L. v. Beethoven
        abbreviate('Felipe de la Cruz', { particles => ['de','la'] }); # F. de la Cruz

### Returns

A plain string.  Returns `''` for inputs that normalise to nothing (e.g. a
bare comma).

### Side Effects

None.  The function is purely functional with no persistent state.

### Usage

    # Positional
    my $abbrev = abbreviate('John Quincy Adams');

    # Options hashref
    my $abbrev = abbreviate('John Quincy Adams', {
        format    => 'initials',
        style     => 'last_first',
        separator => '-',
    });

### API SPECIFICATION

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

### MESSAGES

    Error                                    Meaning / Resolution
    ---------------------------------------  -----------------------------------------------
    name parameter missing or undefined      Called without a name argument; supply one.
    name must be a non-empty string          Passed '' or undef; supply a non-empty string.
    format must be one of: ...               Invalid format constant; see API SPECIFICATION.
    style must be one of: ...               Invalid style constant; see API SPECIFICATION.
    particles: must be one of boolean,       Passed a string or hashref; pass 0/1 or an
      arrayref                               arrayref of particle strings instead.

### PSEUDOCODE

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

# LIMITATIONS

- Honorifics (`Dr.`, `Prof.`) and suffixes (`Jr.`, `III`) are not
detected or stripped; they are treated as name components.
- Initials are taken verbatim from the first character of each token.
Non-alphabetic leading characters (digits, punctuation) are included as-is.
- Multiple consecutive commas collapse to a single comma before parsing.
Names with two legitimate comma-separated clauses are not supported.
- `compact` and `initials` formats are lossy: passing their output back into
`abbreviate` does not reproduce the original result.
- Particle detection is case-sensitive.  A token is only absorbed into the
last-name component when it exactly matches a particle string (all lowercase).
Capitalised tokens such as `Van` or `De` are treated as ordinary name
components.
- For `compact` and `initials` formats with `last_first` style, only the
first character of the full particle-inclusive last name is used as the last
initial (e.g. `van Beethoven` contributes initial `v`).
- Unicode input is NFC-normalised before processing.  Strings that differ only
in normalisation form (e.g. precomposed `\x{e9}` vs. combining `e\x{301}`)
produce identical output.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report bugs to `bug-text-names-abbreviate at rt.cpan.org` or via
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Abbreviate](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Names-Abbreviate).

# REPOSITORY

[https://github.com/nigelhorne/Text-Names-Abbreviate](https://github.com/nigelhorne/Text-Names-Abbreviate)

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Text-Names-Abbreviate/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

    perldoc Text::Names::Abbreviate

- MetaCPAN: [https://metacpan.org/dist/Text-Names-Abbreviate](https://metacpan.org/dist/Text-Names-Abbreviate)
- RT tracker: [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Abbreviate](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-Abbreviate)
- CPAN Testers: [http://matrix.cpantesters.org/?dist=Text-Names-Abbreviate](http://matrix.cpantesters.org/?dist=Text-Names-Abbreviate)

# FORMAL SPECIFICATION

## abbreviate

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

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.
