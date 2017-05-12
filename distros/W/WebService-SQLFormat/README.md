# NAME

WebService::SQLFormat - Format SQL via the sqlformat.org API

# VERSION

version 0.000007

# SYNOPSIS

    use strict;
    use warnings;
    use feature qw( say );

    use WebService::SQLFormat;
    my $formatter = WebService::SQLFormat->new(
        identifier_case => 'upper',
        reindent        => 1,
    );

    my $sql = shift @ARGV;

    say $formatter->format_sql($sql);

## CONSTRUCTOR OPTIONS

- debug\_level

    An integer between 0 and 8.  Used to set debugging level for
    [LWP::ConsoleLogger::Easy](https://metacpan.org/pod/LWP::ConsoleLogger::Easy).  Defaults to 0.

- identifier\_case

    Case to use for SQL identifiers.  One of 'upper', 'lower' or 'capitalize'.  If
    no value is supplied, identifiers will not be changed.

- keyword\_case

    Case to use for SQL keywords.  One of 'upper', 'lower' or 'capitalize'.  If no
    value is supplied, case will not be changed.

- reindent( 0|1)

    Re-indent supplied SQL.  Defaults to 0.

- strip\_comments( 0|1 )

    Remove SQL comments.  Defaults to 0.

- ua

    You may supply your own user agent.  Must be of the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) family.

- url

    The API url to query.  Defaults to [https://sqlformat.org/api/v1/format](https://sqlformat.org/api/v1/format)

## format\_sql( $raw\_sql )

This method expects a scalar containing the SQL which you'd like to format.
Returns the formatted SQL.

# DESCRIPTION

BETA BETA BETA.  Subject to change.

This module is a thin wrapper around [https://sqlformat.org](https://sqlformat.org)

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
