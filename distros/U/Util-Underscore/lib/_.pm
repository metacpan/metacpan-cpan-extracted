# this matches, but perlcritic seems to use retarded regexes that don't get this.
## no critic (Modules::RequireFilenameMatchesPackage)
package _;

# PODNAME: _.pm
# ABSTRACT: do not use this module directly

use strict;
use warnings;

use Carp ();

my $blow_up = sub {

    # Unload ourselves, so that "require _" gets trapped each time.
    # However, this is only respected by Perl in the $_WE_COME_IN_PEACE mode.
    delete $INC{'_.pm'};

    # be silent if this is being loaded by Util::Underscore
    ## no critic (ProtectPrivateVars)
    return 1 if ($Util::Underscore::_WE_COME_IN_PEACE // q[]) eq 'pinky swear';

    # loudly complain otherwise.
    Carp::confess qq(The "_" package is internal to Util::Underscore)
        . qq(and must not be imported directly.\n);
};

{
    no warnings 'redefine';    ## no critic (ProhibitNoWarnings)

    sub import {
        return $blow_up->();
    }
}

# End with a true value in the $_WE_COME_IN_PEACE mode,
# otherwise use this as a chance to blow up
# – "import" has already been compiled after all.
## no critic (Modules::RequireEndWithOne)
$blow_up->();

__END__

=pod

=encoding UTF-8

=head1 NAME

_.pm - do not use this module directly

=head1 VERSION

version v1.4.2

=head1 DESCRIPTION

Do not use this module directly.
The "_" package is internal to L<Util::Underscore|Util::Underscore>,
and only serves as a placeholder.

Any attempt to use, require, or import this module should result in an error message.

The functions in the C<_> namespace are documented in the L<Util::Underscore|Util::Underscore> documentation.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/latk/p5-Util-Underscore/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Lukas Atkinson (cpan: AMON) <amon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Lukas Atkinson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
