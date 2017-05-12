#
# This file is part of autobox-Camelize
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package autobox::Camelize;
{
  $autobox::Camelize::VERSION = '0.001';
}

# ABSTRACT: autobox methods for (de)camelcasing

use strict;
use warnings;

use parent 'autobox';

sub import {
    my $class = shift @_;

    return $class->SUPER::import(
        STRING => 'autobox::Camelize::STRING',
        @_,
    );
}

{
    package autobox::Camelize::STRING;
{
  $autobox::Camelize::STRING::VERSION = '0.001';
}

    use strict;
    use warnings;

    sub decamelize {
        my $string = lcfirst shift @_;

        $string =~ s/::(.)/__\l$1/g;
        $string =~ s/([A-Z])/_\l$1/g;

        return $string;
    }

    sub camelize {
        my $string = ucfirst shift @_;

        $string =~ s/__(.)/::\u$1/g;
        $string =~ s/_(.)/\u$1/g;

        return $string;
    }
}

!!42;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl camelize decamelize Camelize Decamelize Camelizing Decamelizing
camelization lowercased

=head1 NAME

autobox::Camelize - autobox methods for (de)camelcasing

=head1 VERSION

This document describes version 0.001 of autobox::Camelize - released March 17, 2013 as part of autobox-Camelize.

=head1 SYNOPSIS

    use autobox::Camelize;

    # $foo is 'this_is__my__name'
    my $foo = 'ThisIs::My::Name'->decamelize;

    # $bar is 'ThisIs::NotMy::Name'
    my $bar = 'this_is__not_my__name'->camelize;

=head1 DESCRIPTION

This is a simple set of autobox methods that work on strings, and
camelize/decamelize them according to how the author thinks camelization
should work:

Camelizing replaces '__[a-z]' with '::[A-Z]', and '_[a-z]' with '[A-Z]'.
The first character is capitalized.

Decamelizing replaces '::[A-Z]' with '__[a-z]', and '[A-Z]' with '_[a-z]'.
The first character is lowercased.

=head1 STRING METHODS

=head2 camelize

Camelize a string.

=head2 decamelize

Decamelize a string.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<autobox>

=item *

L<L<autobox::Core> has a fairly comprehensive collection of autobox methods.|L<autobox::Core> has a fairly comprehensive collection of autobox methods.>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/autobox-Camelize>
and may be cloned from L<git://github.com/RsrchBoy/autobox-Camelize.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/autobox-Camelize/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
