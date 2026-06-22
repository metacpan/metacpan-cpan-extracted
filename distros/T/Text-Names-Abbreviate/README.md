# NAME

Text::Names::Abbreviate - Create abbreviated name formats from full names

## VERSION

Version 0.03

# SYNOPSIS

    use Text::Names::Abbreviate qw(abbreviate);

    say abbreviate('John Quincy Adams');                            # J. Q. Adams
    say abbreviate('Adams, John Quincy');                          # J. Q. Adams
    say abbreviate('George R R Martin', { format => 'initials' }); # G.R.R.M.

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
`format`, `style`, and `separator`.

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

### PSEUDOCODE

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

# LIMITATIONS

- Honorifics (`Dr.`, `Prof.`) and suffixes (`Jr.`, `III`) are not
detected or stripped; they are treated as name components.
- Initials are taken verbatim from the first character of each token.
Non-alphabetic leading characters (digits, punctuation) are included as-is.
- Multiple consecutive commas collapse to a single comma before parsing.
Names with two legitimate comma-separated clauses are not supported.
- `compact` and `initials` formats are lossy: passing their output back into
`abbreviate` does not reproduce the original result.

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

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.
