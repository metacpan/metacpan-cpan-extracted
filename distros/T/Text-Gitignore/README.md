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

Text::Gitignore matches `.gitignore` patterns. It combines [Text::Glob](https://metacpan.org/pod/Text::Glob) and
[File::FnMatch](https://metacpan.org/pod/File::FnMatch) functionality with several `.gitignore`-specific tweaks.

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
matched.

# LICENSE

Originally developed for [https://kritika.io](https://kritika.io).

Copyright (C) Viacheslav Tykhanovskyi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# CREDITS

Flavio Poletti

# AUTHOR

Viacheslav Tykhanovskyi <viacheslav.t@gmail.com>
