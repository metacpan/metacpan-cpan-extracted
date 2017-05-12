package Text::Xslate::Bridge::Alloy;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '1.0001';

use parent qw(Text::Xslate::Bridge);

use Template::Alloy;
use Template::Alloy::VMethod qw($VOBJS);

__PACKAGE__->bridge(
    scalar => $VOBJS->{Text},
    array  => $VOBJS->{List},
    hash   => $VOBJS->{Hash},
);

1;
__END__

=head1 NAME

Text::Xslate::Bridge::Alloy - Template::Alloy virtual methods for Xslate

=head1 VERSION

This document describes Text::Xslate::Bridge::Alloy version 1.0001.

=head1 SYNOPSIS

    use Text::Xslate::Bridge::Alloy;

    my $xslate = Text::Xslate->new(
        module => [ 'Text::Xslate::Bridge::Alloy' ],
    );

    print $xslate->render_string('<: "foo".length() :>'); # => 3

=head1 DESCRIPTION

Text::Xslate::Bridge::Alloy provides Xslate with Template::Alloy virtual methods.

Note that Template::Alloy does not distinguish methods and filters. That is,
C<< expr | foo >> is the same as C<< expr.foo() >>. This module exports
all the features as methods, so you must use the latter syntax even for filters.

=head1 INTERFACE

=head2 Class methods

=head3 C<< Text::Xslate::Bridge::Alloy->methods() -> %methods >>

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Text::Xslate>

L<Template::Alloy>

L<Template::Alloy::VMethod>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
