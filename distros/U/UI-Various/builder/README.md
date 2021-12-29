# NAME

*.pl - development tools for `[UI::Various](https://metacpan.org/pod/UI%3A%3AVarious)`

# SYNOPSIS

    builder/dod-check.pl    # check project against Definition of Done
    builder/dod-check.sh    # pretty-print wrapper for builder/dod-check.pl,
                            # also fixes various file permissions
	builder/update-language.pl --check
	                        # check default language file (EN) for completeness
	builder/update-language.pl DE
                            # prepare update of German language file
	builder/update-language.pl 'some new English message'
                            # add key and text for new message to default
                            # language file (EN)

# ABSTRACT

These are some development tools for `[UI::Various](https://metacpan.org/pod/UI%3A%3AVarious)`,
e. g. to handle its messages in all supported different languages or to
check everything against the project's Definition of Done.

# DESCRIPTION

See documentation of each Perl script for more details:

# SEE ALSO

- perldoc builder/dod-check.pl

- perldoc builder/update-language.pl

# LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

# AUTHOR

Thomas Dorner <dorner@cpan.org>
