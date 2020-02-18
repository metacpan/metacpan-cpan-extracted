# NAME

Text::Gitignore - Match .gitignore patterns

# SYNOPSIS

    use Text::Gitignore qw(match_gitignore build_gitignore_matcher);

    my @matched_files = match_gitignore(['pattern1', 'pattern2/*'], @files);

    # Precompile patterns
    my $matcher = build_gitignore_matcher(['*.js']);

    if ($matcher->('foo.js')) {

        # Matched
    }

# DESCRIPTION

Text::Gitignore matches `.gitignore` patterns. It combines [Text::Glob](https://metacpan.org/pod/Text%3A%3AGlob) and
[File::FnMatch](https://metacpan.org/pod/File%3A%3AFnMatch) functionality with several `.gitignore`-specific tweaks.

# EXPORTED FUNCTIONS

## `match_gitignore`

    my @matched_files = match_gitignore(['pattern1', 'pattern2/*'], @files);

Returns matched paths (if any). Accepts a string (slurped file for example), or an array reference

## `build_gitignore_matcher`

    # Precompile patterns
    my $matcher = build_gitignore_matcher(['*.js']);

    if ($matcher->('foo.js')) {

        # Matched
    }

Returns a code reference. The produced function accepts a single file as a first parameter and returns true when it was
matched. In case no pattern is matched, it returns a false value with the following convention:

- if the no-match reason is because of a negated pattern, then a false but defined value is returned (e.g. `0`);
- otherwise, if the no-match reason is that no _direct_ pattern matched, then `undef` is returned.

The use of different false values is inspired to the `wantarray()` built-in function.

Example:

    my $matcher  = build_gitignore_matcher(['f*', '!foo*', 'foobar']);
    my $matched  = $matcher->('foobar');  # $matched set to true
    my $ignored  = $matcher->('bar');     # $ignored set to undef
    my $excluded = $matcher->('foolish'); # $excluded set to false but defined (e.g. 0)

# LICENSE

Originally developed for [https://kritika.io](https://kritika.io).

Copyright (C) Viacheslav Tykhanovskyi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# CREDITS

Flavio Poletti

Eric A. Zarko

# AUTHOR

Viacheslav Tykhanovskyi <viacheslav.t@gmail.com>
