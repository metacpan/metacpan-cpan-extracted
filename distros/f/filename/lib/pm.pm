


use strict;
use warnings;



package pm;
# ABSTRACT: Perl module to load files at compile-time, without BEGIN blocks.


use parent 'filename';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

pm - Perl module to load files at compile-time, without BEGIN blocks.

=head1 SYNOPSIS

    # Instead of "BEGIN { require '/path/to/file.pm' }"
    # use the more succinct:
    use pm '/path/to/file.pm';

    # Or, if you need to include a Perl module relative to the program:
    use FindBin qw($Bin);
    use pm "$Bin/../lib/Application.pm";

    # Do it at runtime:
    pm->require('/path/to/file.pm');

    # Throw it into a loop:
    say( 'Required: ', $_ ) foreach grep pm->require, @files;

=head1 DESCRIPTION

This is just an alias to the L<filename> module.
See L<filename> for a complete description for how to use this module.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rkleemann/filename/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 VERSION

This document describes version v0.20.060 of this module.

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
