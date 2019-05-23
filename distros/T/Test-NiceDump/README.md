# NAME

Test::NiceDump - let's have a nice and human readable dump of our objects!

# SYNOPSIS

    use Test::Deep;
    use Test::NiceDump 'nice_explain';

    cmp_deeply($got,$expected,'it works')
        or nice_explain($got,$expected);

# DESCRIPTION

This module uses [`Data::Dump::Filtered`](https://metacpan.org/pod/Data::Dump::Filtered) and a set of sensible
filters to dump test data in a more readable way.

For example, [`DateTime`](https://metacpan.org/pod/DateTime) objects get printed in the full ISO
8601 format, and [`DBIx::Class::Row`](https://metacpan.org/pod/DBIx::Class::Row) objects get printed as
hashes of their inflated columns.

# AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
